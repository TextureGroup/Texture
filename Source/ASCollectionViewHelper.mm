#import "ASCollectionViewHelper.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <AsyncDisplayKit/ASInternalHelpers.h>
#import <os/log.h>
#import <future>
#import <unordered_map>
#import <objc/runtime.h>

#import "ASBoundedQueue.h"

static NSString *const kASReuseIdentifier = @"texture_cell";

static os_log_t ASCollectionLog2(void) {
  static os_log_t _val;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _val = os_log_create("org.TextureGroup.collectionTwo", "");
  });
  return _val;
}

struct ASCollectionPath {
    __unsafe_unretained NSString *supplementaryElementKind;
    NSInteger section;
    NSInteger item;
  static ASCollectionPath cell(NSIndexPath *indexPath) {
    return { nil, indexPath.section, indexPath.item };
  }
  static ASCollectionPath header(NSInteger sectionArg) {
    return { UICollectionElementKindSectionHeader, sectionArg, 0};
  }
  static ASCollectionPath footer(NSInteger sectionArg) {
    return { UICollectionElementKindSectionFooter, sectionArg, 0};
  }
  static ASCollectionPath supp(NSIndexPath *indexPath, NSString *kind) {
    return { kind, indexPath.section, indexPath.item};
  }
};


using namespace std;

@interface ASCollectionObjectState : NSObject {
@package
  unowned id _object;
  shared_future<CFTypeRef> _nodeFuture;
  
  pair<ASSizeRange, shared_future<CGSize>> _sizeFuture;
}
@end

@implementation ASCollectionObjectState
- (void)dealloc
{
  // TODO: Avoid blocking on this future if we're going away!
  if (_nodeFuture.valid()) {
    CFRelease(_nodeFuture.get());
  }
}
@end

@interface ASCollectionViewHelper ()
@end

@implementation ASCollectionViewHelper {
  BOOL _isTableView;
  __weak id<ASCollectionViewHelperDataSource> _dataSource;
  
  // weak object -> state
  NSMapTable<id, ASCollectionObjectState *> *_data;
}

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView dataSource:(id<ASCollectionViewHelperDataSource>)dataSource
{
  if (self = [self init]) {
    _dataSource = dataSource;

    [collectionView registerClass:UICollectionViewCell.class
       forCellWithReuseIdentifier:kASReuseIdentifier];
    [collectionView registerClass:UICollectionReusableView.class forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kASReuseIdentifier];
    [collectionView registerClass:UICollectionReusableView.class forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:kASReuseIdentifier];
  }
  return self;
}

- (instancetype)initWithTableView:(UITableView *)tableView dataSource:(id<ASCollectionViewHelperDataSource>)dataSource
{
  if (self = [self init]) {
    _dataSource = dataSource;
    _isTableView = YES;
    
    [tableView registerClass:UITableViewCell.class forCellReuseIdentifier:kASReuseIdentifier];
    [tableView registerClass:UITableViewHeaderFooterView.class forHeaderFooterViewReuseIdentifier:kASReuseIdentifier];
  }
  return self;
}

- (instancetype)init
{
  if (self = [super init]) {
    _data = [[NSMapTable alloc] initWithKeyOptions:NSMapTableObjectPointerPersonality | NSMapTableWeakMemory valueOptions:NSMapTableStrongMemory capacity:0];
  }
  return self;
}

#pragma mark - Table view data

- (BOOL)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath height:(out CGFloat *)heightPtr {
  CGSize size;
  if (![self sizeFor:ASCollectionPath::cell(indexPath) container:tableView sizePtr:&size]) {
    return NO;
  }
#if TARGET_OS_IOS
  /**
   * Weirdly enough, Apple expects the return value here to _include_ the height
   * of the separator, if there is one! So if our node wants to be 43.5, we need
   * to return 44. UITableView will make a cell of height 44 with a content view
   * of height 43.5.
   */
  if (tableView.separatorStyle != UITableViewCellSeparatorStyleNone) {
    size.height += 1.0 / ASScreenScale();
  }
#endif
  *heightPtr = size.height;
  return YES;
}

- (BOOL)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section height:(out CGFloat *)heightPtr {
  CGSize size;
  if (![self sizeFor:ASCollectionPath::header(section) container:tableView sizePtr:&size]) {
    return NO;
  }
  *heightPtr = size.height;
  return YES;
}

- (BOOL)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section height:(out CGFloat *)heightPtr {
  CGSize size;
  if (![self sizeFor:ASCollectionPath::footer(section) container:tableView sizePtr:&size]) {
    return NO;
  }
  *heightPtr = size.height;
  return YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  auto path = ASCollectionPath::cell(indexPath);
  id object = [self _objectFromDataSourceAt:path];
  if (!object) {
    return nil;
  }
  auto cell = [tableView dequeueReusableCellWithIdentifier:kASReuseIdentifier forIndexPath:indexPath];
  [self host:path object:object inContentView:cell.contentView container:tableView];
  return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
  auto path = ASCollectionPath::header(section);
  id object = [self _objectFromDataSourceAt:path];
  if (!object) {
    return nil;
  }
  auto cell = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kASReuseIdentifier];
  [self host:path object:object inContentView:cell.contentView container:tableView];
  return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
  auto path = ASCollectionPath::footer(section);
  id object = [self _objectFromDataSourceAt:path];
  if (!object) {
    return nil;
  }
  auto cell = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kASReuseIdentifier];
  [self host:path object:object inContentView:cell.contentView container:tableView];
  return cell;
}

#pragma mark - Collection view data

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  auto path = ASCollectionPath::cell(indexPath);
  id object = [self _objectFromDataSourceAt:path];
  if (!object) {
    return nil;
  }
  auto cell = [collectionView dequeueReusableCellWithReuseIdentifier:kASReuseIdentifier forIndexPath:indexPath];
  [self host:path object:object inContentView:cell.contentView container:collectionView];
  return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  auto path = ASCollectionPath::supp(indexPath, kind);
  id object = [self _objectFromDataSourceAt:path];
  if (!object) {
    return nil;
  }
  auto cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:kASReuseIdentifier forIndexPath:indexPath];
  [self host:path object:object inContentView:cell container:collectionView];
  return cell;
}

- (BOOL)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath size:(out CGSize *)sizePtr
{
  return [self sizeFor:ASCollectionPath::cell(indexPath) container:collectionView sizePtr:sizePtr];
}

- (BOOL)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout referenceSizeForHeaderInSection:(NSInteger)section size:(out CGSize *)sizePtr
{
  return [self sizeFor:ASCollectionPath::header(section) container:collectionView sizePtr:sizePtr];
}

- (BOOL)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout referenceSizeForFooterInSection:(NSInteger)section size:(out CGSize *)sizePtr
{
  return [self sizeFor:ASCollectionPath::footer(section) container:collectionView sizePtr:sizePtr];
}

#pragma mark - Funnel Methods

- (BOOL)sizeFor:(const ASCollectionPath &)path container:(UIView *)container sizePtr:(CGSize *)sizePtr
{
  id object = [self _objectFromDataSourceAt:path];
  if (!object) {
    *sizePtr = CGSizeZero;
    return NO;
  }
  
  // Wait on the node future.
  let state = [self _stateForObject:object];
  [self _ensureNodeFutureAt:path state:state];
  let node = (__bridge ASDisplayNode *)state->_nodeFuture.get();
  
  ASSizeRange sizeRange = [self sizeRangeFor:path container:container];
  *sizePtr = [node layoutThatFits:sizeRange].size;
  return YES;
}

- (void)host:(const ASCollectionPath &)path object:(id)object inContentView:(UIView *)contentView container:(UIView *)container
{
  // Get the node, or bail if this is cell is not a node.
  unowned let state = [self _stateForObject:object];
  [self _ensureNodeFutureAt:path state:state];
  unowned let node = (__bridge ASDisplayNode *)state->_nodeFuture.get();
  unowned let nodeView = node.view;
  let subviews = contentView.subviews;
  if (NSNotFound != [subviews indexOfObjectIdenticalTo:nodeView]) {
    // Already hosted.
    return;
  }
  
  for (UIView *view in subviews) {
    [view removeFromSuperview];
  }
  [contentView addSubview:nodeView];
  nodeView.frame = contentView.bounds;
  nodeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

#pragma mark - Internal

- (void)_ensureNodeFutureAt:(const ASCollectionPath &)path state:(ASCollectionObjectState *)state
{
  if (!state->_nodeFuture.valid()) {
    let promise = new std::promise<CFTypeRef>();
    state->_nodeFuture = promise->get_future().share();
    let nodeBlock = [_dataSource collectionViewHelper:self nodeBlockForObject:state->_object indexPath:[NSIndexPath indexPathForItem:path.item inSection:path.section] supplementaryElementKind:path.supplementaryElementKind];
    let dispatchBlock = dispatch_block_create((dispatch_block_flags_t)0, ^{
      promise->set_value((__bridge_retained CFTypeRef)nodeBlock());
      delete promise;
    });
    [ASBoundedQueueGetDefault() dispatch:dispatchBlock];
  }
}

/// Look up or create an empty state for the given object.
- (ASCollectionObjectState *)_stateForObject:(id)object
{
  auto state = [_data objectForKey:object];
  if (!state) {
    state = [[ASCollectionObjectState alloc] init];
    state->_object = object;
    [_data setObject:state forKey:object];
  }
  return state;
}

- (id)_objectFromDataSourceAt:(const ASCollectionPath &)path
{
  if (path.supplementaryElementKind == nil) {
    return [_dataSource collectionViewHelper:self objectForItemAtIndexPath:[NSIndexPath indexPathForItem:path.item inSection:path.section]];
  } else if (path.supplementaryElementKind == UICollectionElementKindSectionHeader) {
    return [_dataSource collectionViewHelper:self objectForHeaderInSection:path.section];
  } else if (path.supplementaryElementKind == UICollectionElementKindSectionFooter) {
    return [_dataSource collectionViewHelper:self objectForFooterInSection:path.section];
  } else {
    NSAssert(NO, @"Non-header/footer supplementary kinds are not supported currently.");
    return nil;
  }
}

- (ASSizeRange)sizeRangeFor:(const ASCollectionPath &)path container:(UIView *)container
{
  // If we are already hosted in a table view cell, use that cell's width
  CGRect bounds = container.bounds;
  if (_isTableView) {
    return ASSizeRangeMake({CGRectGetWidth(bounds),0}, {CGRectGetWidth(bounds),2009});
  } else {
    return ASSizeRangeMake(CGSizeZero, bounds.size);
  }
}

@end
