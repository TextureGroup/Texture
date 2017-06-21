//
//  ASDKDiffingFixtures.m
//  ASDKDiffing
//
//  Created by Adlai Holler on 6/20/17.
//
//

#import "ASDKDiffingFixtures.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <stdatomic.h>

atomic_uint g_identifier;
atomic_uint g_val;

void ASTReset() {
  atomic_store(&g_identifier, 0);
  atomic_store(&g_val, 0);
}

NSInteger ASTNextIdentifier() {
  return atomic_fetch_add(&g_identifier, 1);
}

NSInteger ASTNextContents() {
  return atomic_fetch_add(&g_val, 1);
}

id ASTWithDebugNamesTable(id (NS_NOESCAPE ^block)(NSMapTable<NSNumber *, NSString *> *table)) {
  static NSMapTable<NSNumber *, NSString *> *table;
  static NSLock *lock;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    table = [NSMapTable strongToStrongObjectsMapTable];
    lock = [NSLock new];
  });
  
  [lock lock];
  id result = block(table);
  [lock unlock];
  return result;
}

@implementation ASTViewModel

- (instancetype)init
{
  if (self = [super init]) {
    _identifier = ASTNextIdentifier();
    _contents = ASTNextContents();
  }
  return self;
}

- (instancetype)viewModelByUpdating
{
  ASTViewModel *vm = [[self class] alloc]; // No init. We control the values manually.
  vm->_identifier = _identifier;
  vm->_contents = ASTNextContents();
  return vm;
}

- (NSString *)debugDescription
{
  return ASObjectDescriptionMake(self, [self propertiesForDebugDescription]);
}

- (void)setDebugName:(NSString *)debugName
{
  ASTWithDebugNamesTable(^id(NSMapTable<NSNumber *,NSString *> *table) {
    [table setObject:[debugName copy] forKey:@(self.identifier)];
    return nil;
  });
}

- (NSString *)debugName
{
  return ASTWithDebugNamesTable(^id(NSMapTable<NSNumber *,NSString *> *table) {
    return [table objectForKey:@(self.identifier)];
  });
}

- (NSMutableArray<NSDictionary *> *)propertiesForDebugDescription
{
  __auto_type array = [NSMutableArray array];
  NSString *name = self.debugName;
  if (name.length > 0) {
    [array addObject:@{ @"name": name }];
  } else {
    [array addObject:@{ @"id": @(self.identifier) }];
  }
  [array addObject:@{ @"contents": @(self.contents) }];
  return array;
}

+ (void)reset
{
  ASTReset();
}

#pragma mark - IGListDiffable

- (BOOL)isEqualToDiffableObject:(id<IGListDiffable>)object
{
  ASTViewModel *vm = (ASTViewModel *)object;
  NSParameterAssert([(id)object class] == [self class]);
  NSParameterAssert(vm.identifier == self.identifier);
  return vm.contents == self.contents;
}

- (id<NSObject>)diffIdentifier
{
  return @(self.identifier);
}

@end

@implementation ASTSection
@end

@implementation ASTItem
@end

@implementation ASTSectionCtrl

- (ASCellNodeBlock)nodeBlockForItemAtIndex:(NSInteger)index
{
  return ^{
    return [ASTItemNode new];
  };
}

@end
@implementation ASTItemNode

@end
