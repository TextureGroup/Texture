//
//  ASTextKitContextConcurrencyTests.m
//  AsyncDisplayKitTests
//
//  Created by Greg Bolsinga on 11/25/19.
//  Copyright © 2019 Pinterest. All rights reserved.
//

#import "ASTestCase.h"
#import <AsyncDisplayKit/ASTextKitContext.h>

static const NSUInteger ASTextContextConcurrentCount = 2000;

static void *createContext(void *arg)
{
  BOOL enableGlobalLock = *(BOOL *)arg;

  ASTextKitContext *context = [[ASTextKitContext alloc] initWithAttributedString:[[NSAttributedString alloc] initWithString:@""]
                                                                       tintColor:nil
                                                                   lineBreakMode:NSLineBreakByWordWrapping
                                                            maximumNumberOfLines:100
                                                                  exclusionPaths:nil
                                                                 constrainedSize:CGSizeZero
                                                                 enableGlobalLock:enableGlobalLock];
  return (__bridge void *)(context);
}

@interface ASTextKitContextConcurrencyTests : ASTestCase

@end

@implementation ASTextKitContextConcurrencyTests

- (void)_instantiateTextContextConcurrencyCount:(NSUInteger)concurrencyCount enableGlobalLock:(BOOL)enableGlobalLock
{
  pthread_t threads[concurrencyCount];
  for (NSUInteger i = 0; i < concurrencyCount; i++) {
  pthread_create(&threads[i], NULL, createContext, &enableGlobalLock);
  }

  for (NSUInteger i = 0; i < concurrencyCount; i++) {
  pthread_join(threads[i], NULL);
  }
}

- (void)testTextContextConcurrency_disableGlobalLock
{
  [self _instantiateTextContextConcurrencyCount:ASTextContextConcurrentCount enableGlobalLock:NO];
}

- (void)testTextContextConcurrency_default
{
  [self _instantiateTextContextConcurrencyCount:ASTextContextConcurrentCount enableGlobalLock:YES];
}

@end
