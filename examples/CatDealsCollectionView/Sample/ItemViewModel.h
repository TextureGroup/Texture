//
//  ItemViewModel.h
//  Sample
//
//  Created by Samuel Stow on 12/29/15.
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
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ItemViewModel : NSObject

+ (instancetype)randomItem;

@property (nonatomic, copy) NSString *titleText;
@property (nonatomic, copy) NSString *firstInfoText;
@property (nonatomic, copy) NSString *secondInfoText;
@property (nonatomic, copy) NSString *originalPriceText;
@property (nonatomic, copy) NSString *finalPriceText;
@property (nonatomic, copy) NSString *soldOutText;
@property (nonatomic, copy) NSString *distanceLabelText;
@property (nonatomic, copy) NSString *badgeText;

- (NSURL *)imageURLWithSize:(CGSize)size;

@end
