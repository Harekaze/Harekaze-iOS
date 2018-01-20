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

class Program: Object, Mappable {

	// MARK: - Shared dataSource
	static var programs: Results<(Program)>! = {
		let realm = try! Realm()
		return realm.objects(Program.self).sorted(byKeyPath: "startTime", ascending: false)
	}()

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
	@objc dynamic var filePath: String = ""
	@objc dynamic var tuner: String = ""
	@objc dynamic var command: String = ""

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
		filePath <- map["recorded"]
		tuner <- map["tuner.name"]
		command <- map["command"]
	}

	// MARK: - Static method

	static func refreshPrograms(onSuccess: (() -> Void)?, onFailure: ((SessionTaskError) -> Void)?) {
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		let start = CFAbsoluteTimeGetCurrent()
		let request = ChinachuAPI.RecordingRequest()
		Session.send(request) { result in
			switch result {
			case .success(let data):
				// Add Spotlight search index
				var searchIndex: [CSSearchableItem] = []
				for content in data {
					let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
					attributeSet.title = content.title
					attributeSet.contentDescription = content.detail
					attributeSet.addedDate = content.startTime
					attributeSet.duration = content.duration as NSNumber?
					let item = CSSearchableItem(uniqueIdentifier: content.id, domainIdentifier: "recordings", attributeSet: attributeSet)
					searchIndex.append(item)
				}

				CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: ["recordings"]) { error in
					CSSearchableIndex.default().indexSearchableItems(searchIndex) { error in
						if let error = error {
							Answers.logCustomEvent(withName: "CSSearchableIndex indexing failed", customAttributes: ["error": error as NSError])
						}
					}
				}
				// Store recording program list to realm and spotlight
				DispatchQueue.global().async {
					// Add local in-memory realm store
					let realm = try! Realm()
					try! realm.write {
						realm.add(data, update: true)
						let objectsToDelete = realm.objects(Program.self).filter { data.index(of: $0) == nil }
						realm.delete(objectsToDelete)
					}

					let end = CFAbsoluteTimeGetCurrent()
					let wait = max(0.0, 3.0 - (end - start))
					DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
						onSuccess?()
						UIApplication.shared.isNetworkActivityIndicatorVisible = false
					}
				}
			case .failure(let error):
				onFailure?(error)
				UIApplication.shared.isNetworkActivityIndicatorVisible = false
			}
		}
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
