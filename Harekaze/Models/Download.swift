/**
*
* Download.swift
* Harekaze
* Created by Yuki MIZUNO on 2016/08/21.
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

class Download: Object {
	// MARK: - Scheme version
	static let SchemeVersion: UInt64 = 4

	// MARK: - Managed instance fileds
	@objc dynamic var id: String = ""
	@objc dynamic var recording: Recording?
	@objc dynamic var size: Int64 = 0
	@objc dynamic var downloadStartDate: Date = Date()
	@objc dynamic var lastPlayedPosition: Float = 0.0

	// MARK: - Primary key definition
	override static func primaryKey() -> String? {
		return "id"
	}

	func humanReadableSize() -> String! {
		let component: Int64 = 1024
		let exp = Int(log(Double(size)) / log(Double(component)))
		let unit = " kMGTPE"[String.Index.init(encodedOffset: exp)]
		return String(format: "%.2f \(unit)B", Double(size) / pow(Double(component), Double(exp)))
	}
}
