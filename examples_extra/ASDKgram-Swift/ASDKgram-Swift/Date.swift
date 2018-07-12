//
//  Date.swift
//  ASDKgram-Swift
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

import Foundation

extension Date {
	static let iso8601Formatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.calendar = Calendar(identifier: .iso8601)
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.timeZone = TimeZone(secondsFromGMT: 0)
		formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
		return formatter
	}()
    
    static func timeStringSince(fromConverted date: Date) -> String {
        let diffDates = NSCalendar.current.dateComponents([.day, .hour, .second], from: date, to: Date())
        
        if let week = diffDates.day, week > 7 {
            return "\(week / 7)w"
        } else if let day = diffDates.day, day > 0 {
            return "\(day)d"
        } else if let hour = diffDates.hour, hour > 0 {
            return "\(hour)h"
        } else if let second = diffDates.second, second > 0 {
            return "\(second)s"
        } else if let zero = diffDates.second, zero == 0 {
            return "1s"
        } else {
            return "ERROR"
        }
    }
}
