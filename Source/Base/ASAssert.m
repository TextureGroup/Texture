//
//  ASAssert.m
//  AsyncDisplayKit
//
//  Created by Adlai Holler on 6/10/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <AsyncDisplayKit/ASAssert.h>
#import <Foundation/Foundation.h>

// pthread_key_create must be called before the key can be used. This function does that.
static pthread_key_t ASMainThreadAssertionsDisabledKey()
{
  static pthread_key_t ASMainThreadAssertionsDisabledKey;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    pthread_key_create(&ASMainThreadAssertionsDisabledKey, NULL);
  });
  return ASMainThreadAssertionsDisabledKey;
}

BOOL ASMainThreadAssertionsAreDisabled() {
  return (size_t)pthread_getspecific(ASMainThreadAssertionsDisabledKey()) > 0;
}

void ASPushMainThreadAssertionsDisabled() {
  pthread_key_t key = ASMainThreadAssertionsDisabledKey();
  size_t oldValue = (size_t)pthread_getspecific(key);
  pthread_setspecific(key, (void *)(oldValue + 1));
}

void ASPopMainThreadAssertionsDisabled() {
  pthread_key_t key = ASMainThreadAssertionsDisabledKey();
  size_t oldValue = (size_t)pthread_getspecific(key);
  if (oldValue > 0) {
    pthread_setspecific(key, (void *)(oldValue - 1));
  } else {
    ASDisplayNodeCFailAssert(@"Attempt to pop thread assertion-disabling without corresponding push.");
  }
}
