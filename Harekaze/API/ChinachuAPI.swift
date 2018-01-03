/**
 *
 * ChinachuAPI.swift
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

import APIKit
import ObjectMapper
import Kingfisher
import KeychainAccess
import Crashlytics
import SwiftyUserDefaults

// MARK: - ImageDataParserType

class ImageDataParser: DataParser {

	var contentType: String? {
		return "image/png"
	}

	func parse(data: Data) throws -> Any {
		guard let image = UIImage(data: data) else {
			throw ResponseError.unexpectedObject(data)
		}
		return image
	}
}

protocol ChinachuRequestType: Request {
}

// MARK: - UserDefaults keys

extension DefaultsKeys {
	static let address = DefaultsKey<String>("ChinachuWUIAddress")
	static let username = DefaultsKey<String>("ChinachuWUIUsername")
	static let transcode = DefaultsKey<Bool>("PlaybackTranscoding")
	static let videoResolution = DefaultsKey<String>("TranscodeResolution")
	static let videoBitrate = DefaultsKey<Int>("VideoBitrate")
	static let audioBitrate = DefaultsKey<Int>("AudioBitrate")
}

// MARK: - Chinachu API RequestType

extension ChinachuRequestType {

	// MARK: - Basic Authorization setting
	var headerFields: [String: String] {
		if ChinachuAPI.Config[.username] == "" && ChinachuAPI.password == "" {
			return [:]
		}
		if let auth = "\(ChinachuAPI.Config[.username]):\(ChinachuAPI.password)".data(using: String.Encoding.utf8) {
			return ["Authorization": "Basic \(auth.base64EncodedString(options: []))"]
		}
		return [:]
	}

	// MARK: - API endpoint definition
	var baseURL: URL {
		return URL(string: "\(ChinachuAPI.Config[.address])/api/")!
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
		return JSONDataParser(readingOptions: .allowFragments)
	}
}

final class ChinachuAPI {
	static let Config = Defaults

	// MARK: - Chinachu WUI configurations
	static var timeout: TimeInterval = 10
	static var password: String {
		get {
			if Config[.address].isEmpty {
				return ""
			}
			let keychain: Keychain
			if Config[.address].range(of: "^https://", options: .regularExpression) != nil {
				keychain = Keychain(server: Config[.address], protocolType: .https, authenticationType: .httpBasic)
			} else {
				keychain = Keychain(server: Config[.address], protocolType: .http, authenticationType: .httpBasic)
			}
			return keychain[Config[.username]] ?? ""
		}
		set {
			if Config[.address].isEmpty {
				return
			}
			let keychain: Keychain
			if Config[.address].range(of: "^https://", options: .regularExpression) != nil {
				keychain = Keychain(server: Config[.address], protocolType: .https, authenticationType: .httpBasic)
			} else {
				keychain = Keychain(server: Config[.address], protocolType: .http, authenticationType: .httpBasic)
			}
			keychain[Config[.username]] = newValue
			keychain.setSharedPassword(newValue, account: Config[.username])
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
		typealias Response = [[Program]]

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
			return dict.map {
				if let programs = $0["programs"] as? [[String: AnyObject]] {
					return programs.map { Mapper<Program>().map(JSON: $0) }.filter { $0 != nil }.map {$0!}
				}
				return []
			}
		}
	}

	// MARK: - Channel Logo API

	struct ChannelLogoImageRequest: ChinachuRequestType {
		typealias Response = UIImage

		var method: HTTPMethod {
			return .get
		}

		var id: String
		init(id: String) {
			self.id = id
		}

		var path: String {
			return "channel/\(self.id)/logo.png"
		}

		var dataParser: DataParser {
			return ImageDataParser()
		}

		func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
			guard let image = object as? UIImage else {
				throw ResponseError.unexpectedObject(object)
			}
			return image
		}
	}

	// MARK: - Thumbnail API

	struct PreviewImageRequest: ChinachuRequestType {
		typealias Response = UIImage

		var method: HTTPMethod {
			return .get
		}

		var id: String
		var position: Int
		init(id: String, position: Int) {
			self.id = id
			self.position = position
		}

		var path: String {
			return "recorded/\(self.id)/preview.png"
		}

		var parameters: Any? {
			return ["width": 1280, "height": 720, "pos": position]
		}

		var dataParser: DataParser {
			return ImageDataParser()
		}

		func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
			guard let image = object as? UIImage else {
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
			if ChinachuAPI.Config[.transcode] {
				return "recorded/\(self.id)/watch.mp4"
			}
			*/
			return "recorded/\(self.id)/watch.m2ts"
		}

		var parameters: Any? {
			if Config[.transcode] {
				return ["ext": "mp4", "c:v": "libx264", "c:a": "aac", "b:v": "\(Config[.videoBitrate])k",
						"size": Config[.videoResolution], "b:a": "\(Config[.audioBitrate])k"]
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
			case .invalidBaseURL:
				return "Request URL is invalid."
			case .unexpectedURLRequest:
				return "Request URL is unexpected."
			}
		case .responseError(let error as ResponseError):
			switch error {
			case .nonHTTPURLResponse, .unexpectedObject:
				return (error as NSError).localizedDescription
			case .unacceptableStatusCode(let statusCode):
				switch statusCode {
				case 401:
					return "Authentication failed."
				default:
					return "HTTP \(statusCode) " + (error as NSError).localizedDescription
				}
			}
		case .requestError:
			return "Request error."
		case .responseError:
			return "Response error."
		}
	}
}
