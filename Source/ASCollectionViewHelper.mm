#import "ASCollectionViewHelper.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <os/log.h>
#import <future>
#import <unordered_map>
#import <objc/runtime.h>

#import "BoundedQueue.h"

static os_log_t ASCollectionLog2(void) {
  static os_log_t _val;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _val = os_log_create("org.TextureGroup.collectionTwo", "");
  });
  return _val;
}

typedef struct {
    __unsafe_unretained NSString * _Nullable supplementaryElementKind;
    NSInteger section;
    NSInteger item;
} ASCollectionElementPath;

using namespace std;

@interface ASCollectionViewHelper ()
@end

@implementation ASCollectionViewHelper {
  __weak id<ASCollectionViewHelperDataSource> _dataSource;
  NSMutableSet<NSString *> *_registeredViewClassesForSupplementaryKinds;
  
  // id<ASNodeKey> -> { future<ASDisplayNode>, dispatch_block_t }
  unordered_map<CFTypeRef, pair<shared_future<CFTypeRef>, dispatch_block_t>> _layouts;
}

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView dataSource:(id<ASCollectionViewHelperDataSource>)dataSource
{
  if (self = [super init]) {
    _dataSource = dataSource;
    
    [collectionView registerClass:UICollectionViewCell.class
       forCellWithReuseIdentifier:@"asdkCellId"];
    _registeredViewClassesForSupplementaryKinds = [[NSMutableSet alloc] init];
  }
  return self;
}

- (instancetype)initWithTableView:(UITableView *)tableView dataSource:(id<ASCollectionViewHelperDataSource>)dataSource
{
  if (self = [super init]) {
    _dataSource = dataSource;
    
    [tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"asdkCellId"];
    _registeredViewClassesForSupplementaryKinds = [[NSMutableSet alloc] init];
  }
  return self;
}

#pragma mark - Data providing

- (CGFloat)heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return [self sizeForItemAtIndexPath:indexPath].height;
}

- (CGFloat)heightForHeaderInSection:(NSInteger)section {
  return [self sizeForSupplementaryElementOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]].height;
}

- (CGFloat)heightForFooterInSection:(NSInteger)section {
  return [self sizeForSupplementaryElementOfKind:UICollectionElementKindSectionFooter atIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]].height;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  ASDisplayNodeAssertMainThread();
  os_log_debug(ASCollectionLog2(), "request cell for node %lu", (unsigned long)indexPath.item);
  
  auto cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"asdkCellId" forIndexPath:indexPath];
  [self host:{ nil, indexPath.section, indexPath.item } inContentView:cell.contentView];
  return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  ASDisplayNodeAssertMainThread();
  if (![_registeredViewClassesForSupplementaryKinds containsObject:kind]) {
    [collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:kind withReuseIdentifier:@"asdkSuppId"];
    [_registeredViewClassesForSupplementaryKinds addObject:kind];
  }
  UICollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"asdkSuppId" forIndexPath:indexPath];
  [self host:{ kind, indexPath.section, indexPath.item } inContentView:view];
  return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (void)host:(ASCollectionElementPath)element inContentView:(UIView *)contentView
{
  ASDisplayNodeAssertMainThread();
  // Get the node, or bail if this is cell is not a node.
  auto node = [self _measuredNodeFor:element];
  if (!node) {
    return;
  }
  unowned let oldCellView = contentView.subviews.firstObject;
  unowned let nodeView = node.view;
  if (oldCellView != nodeView) {
    [oldCellView removeFromSuperview];
    [contentView addSubview:nodeView];
    nodeView.frame = contentView.bounds;
    nodeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  }
}

- (void)_startPreparingNodeFor:(ASCollectionElementPath)path knownSizeRange:(ASSizeRange)sizeRange
{
  ASDisplayNodeAssertMainThread();
  id object;
  if (path.supplementaryElementKind == nil) {
    object = [_dataSource collectionViewHelper:self objectForItemAtIndexPath:[NSIndexPath indexPathForItem:path.item inSection:path.section]];
  } else {
    object = [_dataSource collectionViewHelper:self objectForSupplementaryElementOfKind:path.supplementaryElementKind atIndexPath:[NSIndexPath indexPathForItem:path.item inSection:path.section]];
  }
  if (object == nil) {
    return;
  }
  
  if (ASSizeRangeEqualToSizeRange(sizeRange, ASSizeRangeNull)) {
    sizeRange = [self _sizeRangeFromLayoutFor:path];
  }
  
  auto promise = new std::promise<CFTypeRef>();
  auto future = promise->get_future().share();
  __block dispatch_block_t dispatchBlock = dispatch_block_create((dispatch_block_flags_t)0, ^{
    if (dispatch_block_testcancel(dispatchBlock)) {
      delete promise;
      return;
    }
    
    // We retain the key. The key retains the node.
    // If the data source also retains the key, then the node survives across updates.
    // If it doesn't, then we have to regenerate the node.
    static int nodeAssociationKey;
    
    ASDisplayNode *node;
    @synchronized(object) {
      node = objc_getAssociatedObject(object, &nodeAssociationKey);
      if (node) {
        os_log_debug(ASCollectionLog2(), "reused node at %lu", (unsigned long)path.item);
      } else {
        os_log_debug(ASCollectionLog2(), "creating node at %lu", (unsigned long)path.item);
        node = [object createNode];
        if ((id)node != (id)object) {
          objc_setAssociatedObject(object, &nodeAssociationKey, node, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        } else {
          objc_setAssociatedObject(object, &nodeAssociationKey, node, OBJC_ASSOCIATION_ASSIGN);
        }
      }
    }
    
    // Check canceled.
    if (dispatch_block_testcancel(dispatchBlock)) {
      os_log_debug(ASCollectionLog2(), "measure canceled", (unsigned long)path.item);
      delete promise;
      return;
    }
    
    // Just compute the size and rely on the node's cache.
    [node layoutThatFits:sizeRange];
    os_log_debug(ASCollectionLog2(), "measured node at %lu", (unsigned long)path.item);
    
    promise->set_value((__bridge CFTypeRef)node);
    delete promise;
  });
  [BoundedQueueGetDefault() dispatch:dispatchBlock];
  _layouts.insert({ (__bridge_retained CFTypeRef)key, { future, dispatchBlock }});
}

/**
 * For sizing calls, the normal pattern (flow layout) is to size all cells upfront.
 *
 * We want to size them all upfront and avoid re-validating our data on each sizing call.
 * To do this, we need some cooperation from the layout object unfortunately. We need to know
 * that the data source is still valid.
 */
- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  ASDisplayNodeAssertMainThread();
  os_log_debug(ASCollectionLog2(), "request size for node %lu", (unsigned long)indexPath.item);
  return [self _measuredNodeFor:{ nil, indexPath.section, indexPath.item }].calculatedSize;
}

- (CGSize)flowLayoutReferenceSizeForHeaderInSection:(NSInteger)section
{
  return [self sizeForSupplementaryElementOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
}

- (CGSize)flowLayoutReferenceSizeForFooterInSection:(NSInteger)section
{
  return [self sizeForSupplementaryElementOfKind:UICollectionElementKindSectionFooter atIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
}

- (CGSize)sizeForSupplementaryElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
  ASDisplayNodeAssertMainThread();
  os_log_debug(ASCollectionLog2(), "request size for supp node %@ %lu", elementKind, (unsigned long)indexPath.section);
  return [self _measuredNodeFor:{ elementKind, indexPath.section, indexPath.item }].calculatedSize;
}

- (ASDisplayNode *)_measuredNodeFor:(ASCollectionElementPath)path
{
  ASDisplayNodeAssertMainThread();
  id key = [_dataSource collectionViewHelper:self nodeKeyForCollectionPath:path];
  if (key == nil) {
    ASDisplayNodeFailAssert(@"Asked for size of item that isn't a node!");
    return nil;
  }
  auto it = _layouts.find((__bridge CFTypeRef)key);
  
  // We didn't pre-warm this. Known causes of this are:
  // - Changes in the return value from nodeKeyForCollectionPath: for the same path without
  //   invalidating the layout.
  // - Not including a supplementary element in -supplementaryElementsInSection:
  if (it == _layouts.end()) {
    os_log_debug(ASCollectionLog2(), "Warning: failed to warm layout for %lu", (unsigned long)path.item);
    [self _startPreparingNodeFor:path knownSizeRange:ASSizeRangeNull];
    it = _layouts.find((__bridge CFTypeRef)key);
  }
  
  // Blocking: Wait on the layout promise.
  return (__bridge ASDisplayNode *)it->second.first.get();
}

@end
