/**
*
* Recording.swift
* Harekaze
* Created by Yuki MIZUNO on 2018/01/30.
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
import Kingfisher

class Recording: Object, Mappable {
	// MARK: - Scheme version
	static let SchemeVersion: UInt64 = 1

	// MARK: - Shared dataSource
	static var dataSource: Results<(Recording)>! = {
		let realm = try! Realm()
		return realm.objects(Recording.self).sorted(byKeyPath: "program.startTime", ascending: false)
	}()

	// MARK: - Managed instance fileds
	@objc dynamic var id: String = ""
	@objc dynamic var filePath: String = ""
	@objc dynamic var tuner: String = ""
	@objc dynamic var command: String = ""
	@objc dynamic var program: Program?

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
		id <- map["id"]
		filePath <- map["recorded"]
		tuner <- map["tuner.name"]
		command <- map["command"]
		program = Program(map: map)
	}

	// MARK: - Static method

	static func refresh(onSuccess: (() -> Void)?, onFailure: ((SessionTaskError) -> Void)?) {
		let start = DispatchTime.now()
		let request = ChinachuAPI.RecordingRequest()
		Session.sendIndicatable(request) { result in
			switch result {
			case .success(let data):
				// Add Spotlight search index
				let searchIndex: [CSSearchableItem] = data.flatMap { $0.program! }.map {
					let attributeSet = $0.attributeSet
					attributeSet.streamable = 1
					attributeSet.thumbnailURL = URL(fileURLWithPath: ImageCache.default.cachePath(forKey: "\($0.id)-0",
						processorIdentifier: DefaultImageProcessor.default.identifier))
					return CSSearchableItem(uniqueIdentifier: $0.id, domainIdentifier: "recordings", attributeSet: attributeSet)
				}

				CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: ["recordings"]) { error in
					CSSearchableIndex.default().indexSearchableItems(searchIndex) { error in
						if let error = error {
							Answers.logCustomEvent(withName: "CSSearchableIndex indexing failed", customAttributes: ["error": error])
						}
					}
				}
				// Store recording program list to realm and spotlight
				DispatchQueue.global().async {
					// Add local in-memory realm store
					let realm = try! Realm()
					try! realm.write {
						realm.add(data, update: true)
						let objectsToDelete = realm.objects(Recording.self).filter { data.index(of: $0) == nil }
						realm.delete(objectsToDelete)
					}
					DispatchQueue.main.asyncAfter(deadline: start + 3) {
						onSuccess?()
					}
				}
			case .failure(let error):
				onFailure?(error)
			}
		}
	}
}

