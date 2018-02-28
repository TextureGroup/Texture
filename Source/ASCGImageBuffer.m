//
//  ASCGImageBuffer.m
//  AsyncDisplayKit
//
//  Created by Adlai on 2/28/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "ASCGImageBuffer.h"

#import <sys/mman.h>
#import <mach/mach_init.h>
#import <mach/vm_map.h>
#import <mach/vm_statistics.h>

@implementation ASCGImageBuffer {
  BOOL _createdNSData;
}

- (instancetype)initWithLength:(NSUInteger)length
{
  if (self = [super init]) {
    void *buf = mmap(NULL, length, PROT_WRITE | PROT_READ, MAP_ANONYMOUS | MAP_PRIVATE, VM_MAKE_TAG(VM_MEMORY_CGIMAGE), 0);
    if (buf == MAP_FAILED) {
      NSCAssert(NO, @"Failed to create CG image buffer.");
      return nil;
    }
    _mutableBytes = buf;
    _length = length;
  }
  return self;
}

- (void)dealloc
{
  if (!_createdNSData) {
    __unused int result = munmap(_mutableBytes, _length);
    NSCAssert(result == noErr, @"Failed to unmap cg image buffer: %s", strerror(result));
  }
}

- (CGDataProviderRef)createDataProviderAndInvalidate
{
  NSCAssert(!_createdNSData, @"Should not create NSData from buffer multiple times.");
  _createdNSData = YES;
  
  __unused kern_return_t result = vm_protect(mach_task_self(), (vm_address_t)_mutableBytes, _length, true, VM_PROT_READ);
  NSCAssert(result == noErr, @"Error marking buffer as read-only: %@", [NSError errorWithDomain:NSMachErrorDomain code:result userInfo:nil]);
  
  void *buf = _mutableBytes;
  NSUInteger length = _length;
  NSData *d = [[NSData alloc] initWithBytesNoCopy:buf length:length deallocator:^(void * _Nonnull bytes, NSUInteger length) {
    __unused int result = munmap(buf, length);
    NSCAssert(result == noErr, @"Failed to unmap cg image buffer: %s", strerror(result));
  }];
  return CGDataProviderCreateWithCFData((__bridge CFDataRef)d);
}

@end
