//
//  Timer.swift
//  Harekaze
//
//  Created by Yuki MIZUNO on 2016/08/02.
//  Copyright © 2016年 Yuki MIZUNO. All rights reserved.
//

import UIKit
import RealmSwift
import ObjectMapper

class Timer: Program {

	// MARK: - Managed instance fileds
	dynamic var conflict: Bool = false
	dynamic var manual: Bool = false
	dynamic var skip: Bool = false

	// MARK: - Class initialization
	required convenience init?(_ map: Map) {
		self.init()
		mapping(map)
	}

	// MARK: - JSON value mapping
	override func mapping(map: Map) {
		super.mapping(map)
		conflict <- map["isConflict"]
		manual <- map["isManualReserved"]
		skip <- map["isSkip"]
	}
	
}