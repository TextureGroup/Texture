//
//  ASAssert.m
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASAssert.h>
#import <AsyncDisplayKit/ASAvailability.h>

#if AS_TLS_AVAILABLE

static _Thread_local int tls_mainThreadAssertionsDisabledCount;
BOOL ASMainThreadAssertionsAreDisabled() {
  return tls_mainThreadAssertionsDisabledCount > 0;
}

void ASPushMainThreadAssertionsDisabled() {
  tls_mainThreadAssertionsDisabledCount += 1;
}

void ASPopMainThreadAssertionsDisabled() {
  tls_mainThreadAssertionsDisabledCount -= 1;
  ASDisplayNodeCAssert(tls_mainThreadAssertionsDisabledCount >= 0, @"Attempt to pop thread assertion-disabling without corresponding push.");
}

#else

#import <dispatch/once.h>

static pthread_key_t ASMainThreadAssertionsDisabledKey() {
  static pthread_key_t k;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    pthread_key_create(&k, NULL);
  });
  return k;
}

BOOL ASMainThreadAssertionsAreDisabled() {
  return (pthread_getspecific(ASMainThreadAssertionsDisabledKey()) > 0);
}

void ASPushMainThreadAssertionsDisabled() {
  let key = ASMainThreadAssertionsDisabledKey();
  let oldVal = pthread_getspecific(key);
  pthread_setspecific(key, oldVal + 1);
}

void ASPopMainThreadAssertionsDisabled() {
  let key = ASMainThreadAssertionsDisabledKey();
  let oldVal = pthread_getspecific(key);
  pthread_setspecific(key, oldVal - 1);
  ASDisplayNodeCAssert(oldVal > 0, @"Attempt to pop thread assertion-disabling without corresponding push.");
}

#endif // AS_TLS_AVAILABLE
