//
//  LoadingNode.m
//  Sample
//
//  Created by Samuel Stow on 1/9/16.
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the root directory of this source tree. An additional grant
//  of patent rights can be found in the PATENTS file in the same directory.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "LoadingNode.h"
#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>
#import <AsyncDisplayKit/ASHighlightOverlayLayer.h>

#import <AsyncDisplayKit/ASInsetLayoutSpec.h>
#import <AsyncDisplayKit/ASCenterLayoutSpec.h>

@interface LoadingNode ()
{
  ASDisplayNode *_loadingSpinner;
}

@end

@implementation LoadingNode


#pragma mark -
#pragma mark ASCellNode.

- (instancetype)init
{
  if (!(self = [super init]))
    return nil;
  
  _loadingSpinner = [[ASDisplayNode alloc] initWithViewBlock:^UIView * _Nonnull{
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [spinner startAnimating];
    return spinner;
  }];
  _loadingSpinner.style.preferredSize = CGSizeMake(50, 50);
    
  // add it as a subnode, and we're done
  [self addSubnode:_loadingSpinner];
  
  return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
  ASCenterLayoutSpec *centerSpec = [[ASCenterLayoutSpec alloc] init];
  centerSpec.centeringOptions = ASCenterLayoutSpecCenteringXY;
  centerSpec.sizingOptions = ASCenterLayoutSpecSizingOptionDefault;
  centerSpec.child = _loadingSpinner;
  
  return centerSpec;
}

@end
