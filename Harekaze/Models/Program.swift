//
//  Program.swift
//  Harekaze
//
//  Created by Yuki MIZUNO on 2016/07/10.
//  Copyright © 2016年 Yuki MIZUNO. All rights reserved.
//


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
		id <- map["id"]
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
}

