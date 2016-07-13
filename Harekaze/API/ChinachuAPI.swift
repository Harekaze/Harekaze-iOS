//
//  ChinachuAPI.swift
//  Harekaze
//
//  Created by Yuki MIZUNO on 2016/07/10.
//  Copyright © 2016年 Yuki MIZUNO. All rights reserved.
//

import APIKit
import ObjectMapper
import Kingfisher

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
}

final class ChinachuAPI {

	// MARK: - Chinachu WUI configurations
	private struct Configuration {
		static var wuiAddress = "http://chinachu.local:10772"
		static var username = "akari"
		static var password = "bakuhatsu"
	}

	static var wuiAddress: String {
		get { return Configuration.wuiAddress }
		set { Configuration.wuiAddress = newValue }
	}

	static var username: String {
		get { return Configuration.username }
		set { Configuration.username = newValue }
	}

	static var password: String {
		get { return Configuration.password }
		set { Configuration.password = newValue }
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

	struct TimerRequest: ChinachuRequestType {
		typealias Response = [Program]

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
			return dict.map { Mapper<Program>().map($0) }.filter { $0 != nil }.map { $0! }
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