/**
 *
 * Program.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/07/10.
 * 
 * Copyright (c) 2016-2018, Yuki MIZUNO
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
import APIKit
import CoreSpotlight
import MobileCoreServices
import Crashlytics

class RealmString: Object {
	@objc dynamic var stringValue = ""
}

protocol ProgramDuration {
	var startTime: Date { get set }
	var endTime: Date { get set }
	var duration: Double { get }
}

protocol ProgramKey {
	var id: String { get set }
}

class DummyProgram: NSObject, ProgramDuration {
	var startTime: Date
	var endTime: Date
	var duration: Double {
		return endTime.timeIntervalSince(startTime)
	}

	// MARK: - Class initialization
	init(startTime: Date, endTime: Date) {
		self.startTime = startTime
		self.endTime = endTime
	}
}

class Program: Object, Mappable, ProgramKey, ProgramDuration {
	// MARK: - Managed instance fileds
	@objc dynamic var id: String = ""
	@objc dynamic var title: String = ""
	@objc dynamic var fullTitle: String = ""
	@objc dynamic var subTitle: String = ""
	@objc dynamic var detail: String = ""
	let _attributes = List<RealmString>() // swiftlint:disable:this variable_name
	@objc dynamic var genre: String = ""
	@objc dynamic var channel: Channel?
	@objc dynamic var episode: Int = 0
	@objc dynamic var startTime: Date = Date()
	@objc dynamic var endTime: Date = Date()
	@objc dynamic var duration: Double = 0.0

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

	let attributeMap: [String: String] = ["手": "🈐", "字": "🈑", "双": "🈒", "デ": "🈓", "二": "🈔", "多": "🈕", "解": "🈖", "天": "🈗", "交": "🈘",
										  "映": "🈙", "無": "🈚", "料": "🈛", "前": "🈜", "後": "🈝", "再": "🈞", "新": "🈟", "初": "🈠", "終": "🈡",
										  "生": "🈢", "販": "🈣", "声": "🈤", "吹": "🈥", "演": "🈦", "投": "🈧", "捕": "🈨", "一": "🈩", "三": "🈪",
										  "遊": "🈫", "左": "🈬", "中": "🈭", "右": "🈮", "指": "🈯", "走": "🈰", "打": "🈱"]
	var attributedAttributes: [String] {
		return attributes.map {attributeMap[$0] ?? $0}
	}

	var attributedFullTitle: String {
		var newTitle = fullTitle
		for index in newTitle.indices.dropLast().dropFirst().reversed() {
			if let attribute = attributeMap[String(fullTitle[index])] {
				let before = fullTitle.index(before: index)
				let after = fullTitle.index(after: index)
				if fullTitle[before] == "[" && fullTitle[after] == "]" {
					newTitle.replaceSubrange(before...after, with: attribute)
				}
			}
		}
		return newTitle
	}

	// MARK: Spotlight Search item
	var attributeSet: CSSearchableItemAttributeSet {
		let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeMovie as String)
		attributeSet.title = self.title
		attributeSet.keywords = [self.title]
		attributeSet.contentDescription = self.detail
		attributeSet.addedDate = self.endTime
		attributeSet.duration = self.duration as NSNumber?
		attributeSet.metadataModificationDate = self.startTime
		attributeSet.contentCreationDate = self.startTime
		attributeSet.contentModificationDate = self.startTime
		attributeSet.genre = self.genre
		attributeSet.information = self.detail
		attributeSet.projects = [self.title]
		attributeSet.publishers = [self.channel!.name] // ?
		attributeSet.organizations = [self.channel!.name]
		return attributeSet
	}

	override static func ignoredProperties() -> [String] {
		return ["attributes", "attributeSet", "attributedAttributes", "attributedFullTitle", "attributeMap"]
	}

	// MARK: - Primary key definition
	override static func primaryKey() -> String? {
		return "id"
	}

	// MARK: - Class initialization
	required convenience init?(map: Map) {
		self.init()
		mapping(map: map)
	}

	// MARK: - JSON value mapping
	func mapping(map: Map) {
		if map.mappingType == .toJSON {
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
	}
}

class TimeDateTransform: TransformType {

	public func transformFromJSON(_ value: Any?) -> Date? {
		if let seconds = value as? Double {
			return Date(timeIntervalSince1970: TimeInterval(seconds / 1000))
		}
		return nil
	}

	public func transformToJSON(_ value: Date?) -> Double? {
		if let date = value {
			return date.timeIntervalSince1970 * 1000
		}
		return nil
	}
}
