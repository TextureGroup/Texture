//
//  User.swift
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
import UIKit

struct User {
  let profileImage: UIImage?
  let name: String
  let bio: String
}

extension User {
  
  static func generateMockUsers() -> [User] {
    let usernames: [String] = ["Umji",
                               "Eunha",
                               "SinB",
                               "Sowon",
                               "Yerin",
                               "Yuju"]
    let userBio: [String] =
      ["Umji is a South Korean singer. She is a vocalist and the maknae of the girl group GFRIEND.",
       "Eunha is a South Korean singer and actress. She is known as the lead vocalist of the girl group GFriend.",
       "SinB is a South Korean singer. She is the main dancer, face and center of GFriend, which is under Source Music.",
       "Sowon is a South Korean singer rapper. She is the leader and rapper of GFriend, which is under Source Music.",
       "Yerin is a South Korean singer. She is the lead dancer and second center of GFriend, which is under Source Music.",
       "Yuju is a South Korean singer. She is best known as the main vocalist of the South Korean girl group GFriend."
    ]
    
    return (0 ..< usernames.count).map { index -> User in
      return User(profileImage: UIImage(named: usernames[index]),
                  name: usernames[index],
                  bio: userBio[index])
    }
  }
}
