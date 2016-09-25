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
import Crashlytics

// MARK: - Chinachu API DataParserType

class ChinachuDataParser: DataParserType {

	var contentType: String? {
		return "application/json"
	}

	func parseData(_ data: Data) throws -> AnyObject {
		guard data.count > 0 else {
			return [:]
		}
		guard let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
			throw ResponseError.UnexpectedObject(data)
		}

		do {
			return try JSONSerialization.jsonObject(with: data, options: [])
		} catch let error as NSError  {
			Answers.logCustomEvent(withName: "JSON Serialization error", customAttributes: ["error": error])
			return ["data": string, "parseError": error.description]
		}
	}
}

protocol ChinachuRequestType: RequestType {

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
	var baseURL:URL {
		return URL(string: "\(ChinachuAPI.wuiAddress)/api/")!
	}

	// MARK: - Response check
	func interceptObject(_ object: AnyObject, URLResponse: HTTPURLResponse) throws -> AnyObject {
		guard (200..<300).contains(URLResponse.statusCode) else {
			Answers.logCustomEvent(withName: "HTTP Status Code out-of-range", customAttributes: ["status_code": URLResponse.statusCode])
			throw ResponseError.UnacceptableStatusCode(URLResponse.statusCode)
		}

		return object
	}

	// MARK: - Timeout set

	func interceptURLRequest(_ URLRequest: NSMutableURLRequest) throws -> NSMutableURLRequest {
		URLRequest.timeoutInterval = ChinachuAPI.timeout
		return URLRequest
	}

	// MARK: - Data parser
	var dataParser: DataParserType {
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

	static var timeout: TimeInterval {
		get { return Configuration.timeout }
		set { Configuration.timeout = newValue }
	}

	static var transcode: Bool {
		get {
			return UserDefaults().bool(forKey: "PlaybackTranscoding") ?? false
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
			return value as! Int
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
			return value as! Int
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
			return .GET
		}

		var path: String {
			return "recorded.json"
		}

		func responseFromObject(_ object: AnyObject, URLResponse: HTTPURLResponse) throws -> Response {
			guard let dict = object as? [[String: AnyObject]] else {
				return []
			}
			return dict.map { Mapper<Program>().map($0) }.filter { $0 != nil }.map { $0! }
		}
	}

	struct RecordingDetailRequest: ChinachuRequestType {
		typealias Response = Program!

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

		func responseFromObject(_ object: AnyObject, URLResponse: HTTPURLResponse) throws -> Response {
			guard let dict = object as? [String: AnyObject] else {
				return nil
			}
			return Mapper<Program>().map(dict)
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

		func responseFromObject(_ object: AnyObject, URLResponse: HTTPURLResponse) throws -> Response {
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
			return .GET
		}

		var path: String {
			return "reserves.json"
		}

		func responseFromObject(_ object: AnyObject, URLResponse: HTTPURLResponse) throws -> Response {
			guard let dict = object as? [[String: AnyObject]] else {
				return []
			}
			return dict.map { Mapper<Timer>().map($0) }.filter { $0 != nil }.map { $0! }
		}
	}

	struct TimerSkipRequest: ChinachuRequestType {
		typealias Response = [String: AnyObject]

		var method: HTTPMethod {
			return .PUT
		}

		var id: String
		init(id: String) {
			self.id = id
		}

		var path: String {
			return "reserves/\(self.id)/skip.json"
		}

		func responseFromObject(_ object: AnyObject, URLResponse: HTTPURLResponse) throws -> Response {
			guard let dict = object as? [String: AnyObject] else {
				return [:]
			}
			return dict
		}
	}

	struct TimerUnskipRequest: ChinachuRequestType {
		typealias Response = [String: AnyObject]

		var method: HTTPMethod {
			return .PUT
		}

		var id: String
		init(id: String) {
			self.id = id
		}

		var path: String {
			return "reserves/\(self.id)/unskip.json"
		}

		func responseFromObject(_ object: AnyObject, URLResponse: HTTPURLResponse) throws -> Response {
			guard let dict = object as? [String: AnyObject] else {
				return [:]
			}
			return dict
		}
	}

	struct TimerAddRequest: ChinachuRequestType {
		typealias Response = [String: AnyObject]

		var method: HTTPMethod {
			return .PUT
		}

		var id: String
		init(id: String) {
			self.id = id
		}

		var path: String {
			return "program/\(self.id).json"
		}

		func responseFromObject(_ object: AnyObject, URLResponse: HTTPURLResponse) throws -> Response {
			guard let dict = object as? [String: AnyObject] else {
				return [:]
			}
			return dict
		}
	}

	struct TimerDeleteRequest: ChinachuRequestType {
		typealias Response = [String: AnyObject]

		var method: HTTPMethod {
			return .DELETE
		}

		var id: String
		init(id: String) {
			self.id = id
		}

		var path: String {
			return "reserves/\(self.id).json"
		}

		func responseFromObject(_ object: AnyObject, URLResponse: HTTPURLResponse) throws -> Response {
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
			return .GET
		}

		var path: String {
			return "schedule.json"
		}

		func responseFromObject(_ object: AnyObject, URLResponse: HTTPURLResponse) throws -> Response {
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

	// MARK: - Thumbnail API

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

		func responseFromObject(_ object: AnyObject, URLResponse: HTTPURLResponse) throws -> Response {
			guard let data = object as? Data else {
				throw ResponseError.UnexpectedObject(object)
			}
			guard let image = UIImage(data: data) else {
				throw ResponseError.UnexpectedObject(object)
			}
			return image
		}
	}

	// MARK: - Data operation API

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

		func responseFromObject(_ object: AnyObject, URLResponse: HTTPURLResponse) throws -> Response {
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

		func responseFromObject(_ object: AnyObject, URLResponse: HTTPURLResponse) throws -> Response {
			return true
		}
	}

	// MARK: - Streaming API

	struct StreamingMediaRequest: ChinachuRequestType {
		typealias Response = Data

		var method: HTTPMethod {
			return .GET
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

		var parameters: AnyObject? {
			if ChinachuAPI.transcode {
				return ["ext": "mp4", "c:v": "libx264", "c:a": "aac", "b:v": "\(ChinachuAPI.videoBitrate)k", "size": ChinachuAPI.videoResolution, "b:a": "\(ChinachuAPI.audioBitrate)k"]
			}
			return ["ext": "m2ts", "c:v": "copy", "c:a": "copy"]
		}

		func responseFromObject(_ object: AnyObject, URLResponse: HTTPURLResponse) throws -> Response {
			guard let data = object as? Data else {
				throw ResponseError.UnexpectedObject(object)
			}

			return data
		}
	}

}

// MARK: - Error string parser
extension ChinachuAPI {
	static func parseErrorMessage(_ error: Error) -> String {
		switch error as! SessionTaskError {
		case .ConnectionError(let error as NSError):
			return error.localizedDescription
		case .RequestError(let error as RequestError):
			switch error {
			case .InvalidBaseURL(_):
				return "Request URL is invalid."
			case .UnexpectedURLRequest(_):
				return "Request URL is unexpected."
			}
		case .ResponseError(let error as ResponseError):
			switch error {
			case .NonHTTPURLResponse(_):
				return (error as NSError).localizedDescription
			case .UnacceptableStatusCode(let statusCode):
				switch (statusCode) {
				case 401:
					return "Authentication failed."
				default:
					return "HTTP \(statusCode) " + (error as NSError).localizedDescription
				}
			case .UnexpectedObject(_):
				return (error as NSError).localizedDescription
			}
		case .ConnectionError:
			return "Connection error."
		case .RequestError:
			return "Request error."
		case .ResponseError:
			return "Response error."
		}
	}

}
