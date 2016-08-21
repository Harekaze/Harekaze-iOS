/**
 *
 * Program.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/07/10.
 * 
 * Copyright (c) 2016, Yuki MIZUNO
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 * 
 * 3. Neither the name of the copyright holder nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */


import RealmSwift
import ObjectMapper

class RealmString : Object {
	dynamic var stringValue = ""
}

class Program: Object, Mappable {

	// MARK: - Managed instance fileds
	dynamic var id: String = ""
	dynamic var title: String = ""
	dynamic var fullTitle: String = ""
	dynamic var subTitle: String = ""
	dynamic var detail: String = ""
	let _attributes = List<RealmString>()
	dynamic var genre: String = ""
	dynamic var channel: Channel?
	dynamic var episode: Int = 0
	dynamic var startTime: NSDate = NSDate()
	dynamic var endTime: NSDate = NSDate()
	dynamic var duration: Double = 0.0
	dynamic var filePath: String = ""
	dynamic var tuner: String = ""
	dynamic var command: String = ""

	// MARK: - Unmanaged instance fileds
	var attributes: [String] {
		get {
			return _attributes.map { $0.stringValue }
		}
		set {
			_attributes.removeAll()
			newValue.forEach { _attributes.append(RealmString(value: [$0])) }
		}
	}
	override static func ignoredProperties() -> [String] {
		return ["attributes"]
	}

	// MARK: - Primary key definition
	override static func primaryKey() -> String? {
		return "id"
	}

	// MARK: - Class initialization
	required convenience init?(_ map: Map) {
		self.init()
		mapping(map)
	}

	// MARK: - JSON value mapping
	func mapping(map: Map) {
		if map.mappingType == .ToJSON {
			var id = self.id
			id <- map["id"]
		} else {
			id <- map["id"]
		}
		title <- map["title"]
		fullTitle <- map["fullTitle"]
		subTitle <- map["subTitle"]
		detail <- map["detail"]
		attributes <- map["flags"]
		genre <- map["category"]
		channel <- map["channel"]
		episode <- map["episode"]
		startTime <- (map["start"], TimeDateTransform())
		endTime <- (map["end"], TimeDateTransform())
		duration <- map["seconds"]
		filePath <- map["recorded"]
		tuner <- map["tuner.name"]
		command <- map["command"]
	}
}

class TimeDateTransform : DateTransform {
	override func transformFromJSON(value: AnyObject?) -> NSDate? {
		if let seconds = value as? Float {
			return NSDate(timeIntervalSince1970: NSTimeInterval(seconds / 1000))
		}
		return nil
	}

	override func transformToJSON(value: NSDate?) -> Double? {
		if let date = value {
			return date.timeIntervalSince1970 * 1000
		}
		return nil
	}
}

