/**
 *
 * ChinachuAPI.swift
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

import APIKit
import ObjectMapper
import Kingfisher
import KeychainAccess

protocol ChinachuRequestType: RequestType {

}

extension ChinachuRequestType {

	// MARK: - Basic Authorization setting
	var headerFields: [String: String] {
		if ChinachuAPI.username == "" && ChinachuAPI.password == "" {
			return [:]
		}
		if let auth = "\(ChinachuAPI.username):\(ChinachuAPI.password)".dataUsingEncoding(NSUTF8StringEncoding) {
			return ["Authorization": "Basic \(auth.base64EncodedStringWithOptions([]))"]
		}
		return [:]
	}

	// MARK: - API endpoint definition
	var baseURL:NSURL {
		return NSURL(string: "\(ChinachuAPI.wuiAddress)/api/")!
	}

	// MARK: - Response check
	func interceptObject(object: AnyObject, URLResponse: NSHTTPURLResponse) throws -> AnyObject {
		switch URLResponse.statusCode {
		case 200..<300:
			return object

		default:
			throw ResponseError.UnacceptableStatusCode(URLResponse.statusCode)
		}
	}

	// MARK: - Timeout set

	func interceptURLRequest(URLRequest: NSMutableURLRequest) throws -> NSMutableURLRequest {
		URLRequest.timeoutInterval = ChinachuAPI.timeout
		return URLRequest
	}
}

final class ChinachuAPI {

	// MARK: - Chinachu WUI configurations
	private struct Configuration {
		static var timeout: NSTimeInterval = 10
	}

	static var wuiAddress: String {
		get {
			return NSUserDefaults().stringForKey("ChinachuWUIAddress") ?? ""
		}
		set {
			let userDefaults = NSUserDefaults()
			userDefaults.setObject(newValue, forKey: "ChinachuWUIAddress")
			userDefaults.synchronize()
		}
	}

	static var username: String {
		get {
			return NSUserDefaults().stringForKey("ChinachuWUIUsername") ?? ""
		}
		set {
			let userDefaults = NSUserDefaults()
			userDefaults.setObject(newValue, forKey: "ChinachuWUIUsername")
			userDefaults.synchronize()
		}
	}

	static var password: String {
		get {
			let keychain = Keychain(server: wuiAddress,
			                        protocolType: wuiAddress.rangeOfString("^https://", options: .RegularExpressionSearch) != nil ? .HTTPS : .HTTP,
			                        authenticationType: .HTTPBasic)
			return keychain[username] ?? ""
		}
		set {
			let keychain = Keychain(server: wuiAddress,
			                        protocolType: wuiAddress.rangeOfString("^https://", options: .RegularExpressionSearch) != nil ? .HTTPS : .HTTP,
			                        authenticationType: .HTTPBasic)
			keychain[username] = newValue
			keychain.setSharedPassword(newValue, account: username)
		}
	}

	static var timeout: NSTimeInterval {
		get { return Configuration.timeout }
		set { Configuration.timeout = newValue }
	}

	// MARK: - API request types
	struct RecordingRequest: ChinachuRequestType {
		typealias Response = [Program]

		var method: HTTPMethod {
			return .GET
		}

		var path: String {
			return "recorded.json"
		}

		func responseFromObject(object: AnyObject, URLResponse: NSHTTPURLResponse) throws -> Response {
			guard let dict = object as? [[String: AnyObject]] else {
				return []
			}
			return dict.map { Mapper<Program>().map($0) }.filter { $0 != nil }.map { $0! }
		}
	}

	struct RecordingDetailRequest: ChinachuRequestType {
		typealias Response = [String: AnyObject]

		var method: HTTPMethod {
			return .GET
		}

		var id: String
		init(id: String) {
			self.id = id
		}

		var path: String {
			return "recorded/\(self.id).json"
		}

		func responseFromObject(object: AnyObject, URLResponse: NSHTTPURLResponse) throws -> Response {
			guard let dict = object as? [String: AnyObject] else {
				return [:]
			}
			return dict
		}
	}

	struct RecordingFileInfoRequest: ChinachuRequestType {
		typealias Response = [String: AnyObject]

		var method: HTTPMethod {
			return .GET
		}

		var id: String
		init(id: String) {
			self.id = id
		}

		var path: String {
			return "recorded/\(self.id)/file.json"
		}

		func responseFromObject(object: AnyObject, URLResponse: NSHTTPURLResponse) throws -> Response {
			guard let dict = object as? [String: AnyObject] else {
				return [:]
			}
			return dict
		}
	}

	struct TimerRequest: ChinachuRequestType {
		typealias Response = [Timer]

		var method: HTTPMethod {
			return .GET
		}

		var path: String {
			return "reserves.json"
		}

		func responseFromObject(object: AnyObject, URLResponse: NSHTTPURLResponse) throws -> Response {
			guard let dict = object as? [[String: AnyObject]] else {
				return []
			}
			return dict.map { Mapper<Timer>().map($0) }.filter { $0 != nil }.map { $0! }
		}
	}

	struct GuideRequest: ChinachuRequestType {
		typealias Response = [Program]

		var method: HTTPMethod {
			return .GET
		}

		var path: String {
			return "schedule.json"
		}

		func responseFromObject(object: AnyObject, URLResponse: NSHTTPURLResponse) throws -> Response {
			guard let dict = object as? [[String: AnyObject]] else {
				return []
			}
			var programs: [Program] = []
			dict.forEach {
				if let progs = $0["programs"] as? [[String: AnyObject]] {
					progs.map { Mapper<Program>().map($0) }.filter { $0 != nil }.forEach { programs.append($0!) }
				}
			}
			return programs
		}
	}

	struct PreviewImageRequest: ChinachuRequestType {
		typealias Response = UIImage

		var method: HTTPMethod {
			return .GET
		}

		var id: String
		init(id: String) {
			self.id = id
		}

		var path: String {
			return "recorded/\(self.id)/preview.png"
		}

		var parameters: AnyObject? {
			return ["width": 1280, "height": 720, "pos": 36]
		}

		func responseFromObject(object: AnyObject, URLResponse: NSHTTPURLResponse) throws -> Response {
			guard let data = object as? NSData else {
				throw ResponseError.UnexpectedObject(object)
			}
			guard let image = UIImage(data: data) else {
				throw ResponseError.UnexpectedObject(object)
			}
			return image
		}
	}

	struct DeleteProgramRequest: ChinachuRequestType {
		typealias Response = Bool

		var method: HTTPMethod {
			return .DELETE
		}

		var id: String
		init(id: String) {
			self.id = id
		}

		var path: String {
			return "recorded/\(self.id).json"
		}

		func responseFromObject(object: AnyObject, URLResponse: NSHTTPURLResponse) throws -> Response {
			return true
		}
	}
	
	struct DeleteProgramFileRequest: ChinachuRequestType {
		typealias Response = Bool

		var method: HTTPMethod {
			return .DELETE
		}

		var id: String
		init(id: String) {
			self.id = id
		}

		var path: String {
			return "recorded/\(self.id)/file.json"
		}

		func responseFromObject(object: AnyObject, URLResponse: NSHTTPURLResponse) throws -> Response {
			return true
		}
	}

	struct StreamingMediaRequest: ChinachuRequestType {
		typealias Response = NSData

		var method: HTTPMethod {
			return .GET
		}

		var id: String
		init(id: String) {
			self.id = id
		}

		var path: String {
			return "recorded/\(self.id)/watch.m2ts"
		}

		var parameters: AnyObject? {
			return ["ext": "m2ts", "c:v": "copy", "c:a": "copy"]
		}

		func responseFromObject(object: AnyObject, URLResponse: NSHTTPURLResponse) throws -> Response {
			guard let data = object as? NSData else {
				throw ResponseError.UnexpectedObject(object)
			}

			return data
		}
	}

}