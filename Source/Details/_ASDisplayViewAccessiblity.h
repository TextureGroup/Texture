//
//  _ASDisplayViewAccessiblity.h
//  Texture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /ASDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/_ASDisplayView.h>

// WARNING: When dealing with accessibility elements, please use the `accessibilityElements`
// property instead of the older methods e.g. `accessibilityElementCount()`. While the older methods
// should still work as long as accessibility is enabled, this framework provides no guarantees on
// their correctness. For details, see
// https://developer.apple.com/documentation/objectivec/nsobject/1615147-accessibilityelements
