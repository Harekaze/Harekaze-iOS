/**
 *
 * ChinachuAPI.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/07/10.
 * 
 * Copyright (c) 2016-2017, Yuki MIZUNO
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
import Crashlytics

// MARK: - Chinachu API DataParserType

class ChinachuDataParser: DataParser {

	var contentType: String? {
		return "application/json"
	}

	func parse(data: Data) throws -> Any {
		guard !data.isEmpty else {
			return [:]
		}
		guard let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
			throw ResponseError.unexpectedObject(data)
		}

		do {
			return try JSONSerialization.jsonObject(with: data, options: [])
		} catch let error as NSError  {
			Answers.logCustomEvent(withName: "JSON Serialization error", customAttributes: ["error": error])
			return ["data": string, "parseError": error.description]
		}
	}
}

protocol ChinachuRequestType: Request {

}

// MARK: - Chinachu API RequestType

extension ChinachuRequestType {

	// MARK: - Basic Authorization setting
	var headerFields: [String: String] {
		if ChinachuAPI.username == "" && ChinachuAPI.password == "" {
			return [:]
		}
		if let auth = "\(ChinachuAPI.username):\(ChinachuAPI.password)".data(using: String.Encoding.utf8) {
			return ["Authorization": "Basic \(auth.base64EncodedString(options: []))"]
		}
		return [:]
	}

	// MARK: - API endpoint definition
	var baseURL: URL {
		return URL(string: "\(ChinachuAPI.wuiAddress)/api/")!
	}

	// MARK: - Response check
	func interceptObject(_ object: AnyObject, URLResponse: HTTPURLResponse) throws -> AnyObject {
		guard (200..<300).contains(URLResponse.statusCode) else {
			Answers.logCustomEvent(withName: "HTTP Status Code out-of-range", customAttributes: ["status_code": URLResponse.statusCode])
			throw ResponseError.unacceptableStatusCode(URLResponse.statusCode)
		}

		return object
	}

	// MARK: - Timeout set

	func interceptURLRequest(_ URLRequest: NSMutableURLRequest) throws -> NSMutableURLRequest {
		URLRequest.timeoutInterval = ChinachuAPI.timeout
		return URLRequest
	}

	// MARK: - Data parser
	var dataParser: DataParser {
		return ChinachuDataParser()
	}
}

final class ChinachuAPI {

	// MARK: - Chinachu WUI configurations
	fileprivate struct Configuration {
		static var timeout: TimeInterval = 10
	}

	static var wuiAddress: String {
		get {
			return UserDefaults().string(forKey: "ChinachuWUIAddress") ?? ""
		}
		set {
			let userDefaults = UserDefaults()
			userDefaults.set(newValue, forKey: "ChinachuWUIAddress")
			userDefaults.synchronize()
		}
	}

	static var username: String {
		get {
			return UserDefaults().string(forKey: "ChinachuWUIUsername") ?? ""
		}
		set {
			let userDefaults = UserDefaults()
			userDefaults.set(newValue, forKey: "ChinachuWUIUsername")
			userDefaults.synchronize()
		}
	}

	static var password: String {
		get {
			if wuiAddress.isEmpty {
				return ""
			}
			let keychain: Keychain
			if wuiAddress.range(of: "^https://", options: .regularExpression) != nil {
				keychain = Keychain(server: wuiAddress, protocolType: .https, authenticationType: .httpBasic)
			} else {
				keychain = Keychain(server: wuiAddress, protocolType: .http, authenticationType: .httpBasic)
			}
			return keychain[username] ?? ""
		}
		set {
			if wuiAddress.isEmpty {
				return
			}
			let keychain: Keychain
			if wuiAddress.range(of: "^https://", options: .regularExpression) != nil {
				keychain = Keychain(server: wuiAddress, protocolType: .https, authenticationType: .httpBasic)
			} else {
				keychain = Keychain(server: wuiAddress, protocolType: .http, authenticationType: .httpBasic)
			}
			keychain[username] = newValue
			keychain.setSharedPassword(newValue, account: username)
		}
	}

	static var timeout: TimeInterval {
		get { return Configuration.timeout }
		set { Configuration.timeout = newValue }
	}

	static var transcode: Bool {
		get {
			return UserDefaults().bool(forKey: "PlaybackTranscoding")
		}
		set {
			let userDefaults = UserDefaults()
			userDefaults.set(newValue, forKey: "PlaybackTranscoding")
			userDefaults.synchronize()
		}
	}

	static var videoResolution: String {
		get {
			return UserDefaults().string(forKey: "TranscodeResolution") ?? "1280x720"
		}
		set {
			let userDefaults = UserDefaults()
			userDefaults.set(newValue, forKey: "TranscodeResolution")
			userDefaults.synchronize()
		}
	}

	static var videoBitrate: Int {
		get {
			let value = UserDefaults().value(forKey: "VideoBitrate") ?? 1024
			switch value {
			case let intVal as Int:
				return intVal
			default:
				return 0
			}
		}
		set {
			let userDefaults = UserDefaults()
			userDefaults.set(newValue, forKey: "VideoBitrate")
			userDefaults.synchronize()
		}
	}

	static var audioBitrate: Int {
		get {
			let value = UserDefaults().value(forKey: "AudioBitrate") ?? 256
			switch value {
			case let intVal as Int:
				return intVal
			default:
				return 0
			}
		}
		set {
			let userDefaults = UserDefaults()
			userDefaults.set(newValue, forKey: "AudioBitrate")
			userDefaults.synchronize()
		}
	}
}

// MARK: - API request types

extension ChinachuAPI {

	// MARK: - Recording API

	struct RecordingRequest: ChinachuRequestType {
		typealias Response = [Program]

		var method: HTTPMethod {
			return .get
		}

		var path: String {
			return "recorded.json"
		}

		func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
			guard let dict = object as? [[String: AnyObject]] else {
				return []
			}
			return dict.map { Mapper<Program>().map(JSON: $0) }.filter { $0 != nil }.map { $0! }
		}
	}

	struct RecordingDetailRequest: ChinachuRequestType {
		typealias Response = Program!

		var method: HTTPMethod {
			return .get
		}

		var id: String
		init(id: String) {
			self.id = id
		}

		var path: String {
			return "recorded/\(self.id).json"
		}

		func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
			guard let dict = object as? [String: AnyObject] else {
				return nil
			}
			return Mapper<Program>().map(JSON: dict)
		}
	}

	struct RecordingFileInfoRequest: ChinachuRequestType {
		typealias Response = [String: AnyObject]

		var method: HTTPMethod {
			return .get
		}

		var id: String
		init(id: String) {
			self.id = id
		}

		var path: String {
			return "recorded/\(self.id)/file.json"
		}

		func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
			guard let dict = object as? [String: AnyObject] else {
				return [:]
			}
			return dict
		}
	}

	// MARK: - Timer API

	struct TimerRequest: ChinachuRequestType {
		typealias Response = [Timer]

		var method: HTTPMethod {
			return .get
		}

		var path: String {
			return "reserves.json"
		}

		func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
			guard let dict = object as? [[String: AnyObject]] else {
				return []
			}
			return dict.map { Mapper<Timer>().map(JSON: $0) }.filter { $0 != nil }.map { $0! }
		}
	}

	struct TimerSkipRequest: ChinachuRequestType {
		typealias Response = [String: AnyObject]

		var method: HTTPMethod {
			return .put
		}

		var id: String
		init(id: String) {
			self.id = id
		}

		var path: String {
			return "reserves/\(self.id)/skip.json"
		}

		func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
			guard let dict = object as? [String: AnyObject] else {
				return [:]
			}
			return dict
		}
	}

	struct TimerUnskipRequest: ChinachuRequestType {
		typealias Response = [String: AnyObject]

		var method: HTTPMethod {
			return .put
		}

		var id: String
		init(id: String) {
			self.id = id
		}

		var path: String {
			return "reserves/\(self.id)/unskip.json"
		}

		func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
			guard let dict = object as? [String: AnyObject] else {
				return [:]
			}
			return dict
		}
	}

	struct TimerAddRequest: ChinachuRequestType {
		typealias Response = [String: AnyObject]

		var method: HTTPMethod {
			return .put
		}

		var id: String
		init(id: String) {
			self.id = id
		}

		var path: String {
			return "program/\(self.id).json"
		}

		func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
			guard let dict = object as? [String: AnyObject] else {
				return [:]
			}
			return dict
		}
	}

	struct TimerDeleteRequest: ChinachuRequestType {
		typealias Response = [String: AnyObject]

		var method: HTTPMethod {
			return .delete
		}

		var id: String
		init(id: String) {
			self.id = id
		}

		var path: String {
			return "reserves/\(self.id).json"
		}

		func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
			guard let dict = object as? [String: AnyObject] else {
				return [:]
			}
			return dict
		}
	}

	// MARK: - Guide API

	struct GuideRequest: ChinachuRequestType {
		typealias Response = [Program]

		var method: HTTPMethod {
			return .get
		}

		var path: String {
			return "schedule.json"
		}

		func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
			guard let dict = object as? [[String: AnyObject]] else {
				return []
			}
			var programs: [Program] = []
			dict.forEach {
				if let progs = $0["programs"] as? [[String: AnyObject]] {
					progs.map { Mapper<Program>().map(JSON: $0) }.filter { $0 != nil }.forEach { programs.append($0!) }
				}
			}
			return programs
		}
	}

	// MARK: - Thumbnail API

	struct PreviewImageRequest: ChinachuRequestType {
		typealias Response = UIImage

		var method: HTTPMethod {
			return .get
		}

		var id: String
		init(id: String) {
			self.id = id
		}

		var path: String {
			return "recorded/\(self.id)/preview.png"
		}

		var parameters: Any? {
			return ["width": 1280, "height": 720, "pos": 36]
		}

		func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
			guard let data = object as? Data else {
				throw ResponseError.unexpectedObject(object)
			}
			guard let image = UIImage(data: data) else {
				throw ResponseError.unexpectedObject(object)
			}
			return image
		}
	}

	// MARK: - Data operation API

	struct DeleteProgramRequest: ChinachuRequestType {
		typealias Response = Bool

		var method: HTTPMethod {
			return .delete
		}

		var id: String
		init(id: String) {
			self.id = id
		}

		var path: String {
			return "recorded/\(self.id).json"
		}

		func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
			return true
		}
	}

	struct DeleteProgramFileRequest: ChinachuRequestType {
		typealias Response = Bool

		var method: HTTPMethod {
			return .delete
		}

		var id: String
		init(id: String) {
			self.id = id
		}

		var path: String {
			return "recorded/\(self.id)/file.json"
		}

		func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
			return true
		}
	}

	// MARK: - Streaming API

	struct StreamingMediaRequest: ChinachuRequestType {
		typealias Response = Data

		var method: HTTPMethod {
			return .get
		}

		var id: String
		init(id: String) {
			self.id = id
		}

		var path: String {
			// Disable mp4 container because time of video streaming is not available
			// TODO: Implement alternative method to get time of mp4 container
			/*
			if ChinachuAPI.transcode {
				return "recorded/\(self.id)/watch.mp4"
			}
			*/
			return "recorded/\(self.id)/watch.m2ts"
		}

		var parameters: Any? {
			if ChinachuAPI.transcode {
				return ["ext": "mp4", "c:v": "libx264", "c:a": "aac", "b:v": "\(ChinachuAPI.videoBitrate)k", "size": ChinachuAPI.videoResolution, "b:a": "\(ChinachuAPI.audioBitrate)k"]
			}
			return ["ext": "m2ts", "c:v": "copy", "c:a": "copy"]
		}

		func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
			guard let data = object as? Data else {
				throw ResponseError.unexpectedObject(object)
			}

			return data
		}
	}

}

// MARK: - Error string parser
extension ChinachuAPI {
	static func parseErrorMessage(_ error: SessionTaskError) -> String {
		switch error {
		case .connectionError(let error as NSError):
			return error.localizedDescription
		case .requestError(let error as RequestError):
			switch error {
			case .invalidBaseURL(_):
				return "Request URL is invalid."
			case .unexpectedURLRequest(_):
				return "Request URL is unexpected."
			}
		case .responseError(let error as ResponseError):
			switch error {
			case .nonHTTPURLResponse(_):
				return (error as NSError).localizedDescription
			case .unacceptableStatusCode(let statusCode):
				switch statusCode {
				case 401:
					return "Authentication failed."
				default:
					return "HTTP \(statusCode) " + (error as NSError).localizedDescription
				}
			case .unexpectedObject(_):
				return (error as NSError).localizedDescription
			}
		case .connectionError:
			return "Connection error."
		case .requestError:
			return "Request error."
		case .responseError:
			return "Response error."
		}
	}

}
