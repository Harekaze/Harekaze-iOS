//
//  Channel.swift
//  Harekaze
//
//  Created by Yuki MIZUNO on 2016/07/10.
//  Copyright © 2016年 Yuki MIZUNO. All rights reserved.
//

import RealmSwift
import ObjectMapper

class Channel: Object, Mappable {

	// MARK: - Managed instance fileds
	dynamic var channel: Int = 0
	dynamic var id: String = ""
	dynamic var name: String = ""
	dynamic var number: Int = 0
	dynamic var sid: Int = 0
	dynamic var type: String = ""

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
		channel <- map["channel"]
		id <- map["id"]
		name <- map["name"]
		number <- map["n"]
		sid <- map["sid"]
		type <- map["type"]
	}
}