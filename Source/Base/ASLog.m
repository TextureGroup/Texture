//
//  ASLog.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASLog.h>

os_log_t ASNodeLog() {
  static os_log_t log;
#if ASEnableLogs && ASNodeLogEnabled
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    log = as_log_create("org.TextureGroup.Texture", "Node");
  });
#endif
  return log;
}

os_log_t ASLayoutLog() {
  static os_log_t log;
#if ASEnableLogs && ASLayoutLogEnabled
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    log = as_log_create("org.TextureGroup.Texture", "Layout");
  });
#endif
  return log;
}

os_log_t ASCollectionLog() {
  static os_log_t log;
#if ASEnableLogs && ASCollectionLogEnabled
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    log = as_log_create("org.TextureGroup.Texture", "Collection");
  });
#endif
  return log;
}

os_log_t ASRenderLog() {
  static os_log_t log;
#if ASEnableLogs && ASRenderLogEnabled
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    log = as_log_create("org.TextureGroup.Texture", "Render");
  });
#endif
  return log;
}

os_log_t ASImageLoadingLog() {
  static os_log_t log;
#if ASEnableLogs && ASImageLoadingLogEnabled
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    log = as_log_create("org.TextureGroup.Texture", "ImageLoading");
  });
#endif
  return log;
}

os_log_t ASMainThreadDeallocationLog() {
  static os_log_t log;
#if ASEnableLogs && ASMainThreadDeallocationLogEnabled
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    log = as_log_create("org.TextureGroup.Texture", "MainDealloc");
  });
#endif
  return log;
}
