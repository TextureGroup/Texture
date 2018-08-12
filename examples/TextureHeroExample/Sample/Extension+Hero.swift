//
//  Extension+Hero.swift
//  Sample
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

import Foundation
import Hero
import AsyncDisplayKit

protocol HeroExampleProtocol {
  func setupHero()
}

extension ASDisplayNode {
  
  enum HeroIdentifier {
    case profile(String)
    case username(String)
    case bio(String)
    
    var identifier: String {
      switch self {
      case .profile(let id):
        return "profile-hero-identifer-\(id)"
      case .username(let id):
        return "username-hero-identifer-\(id)"
      case .bio(let id):
        return "bio-hero-identifer-\(id)"
      }
    }
  }
  
  func applyHero(id: HeroIdentifier, modifier: [HeroModifier]?) {
    guard ASDisplayNodeThreadIsMain() else {
      fatalError("This method must be called on the main thread")
    }
    self.view.hero.id = id.identifier
    self.view.hero.modifiers = modifier
  }
}

