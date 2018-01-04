/**
*
* GuideViewController.swift
* Harekaze
* Created by Yuki MIZUNO on 2018/01/04.
*
* Copyright (c) 2016-2018, Yuki MIZUNO
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice,
*	this list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice,
*	this list of conditions and the following disclaimer in the documentation
*	 and/or other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors
*	may be used to endorse or promote products derived from this software
*	without specific prior written permission.
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

import UIKit
import APIKit
import SwiftDate

class GuideViewController: UIViewController {

	var programList: [[Program]] = []

	// MARK: - View initialization

	override func viewDidLoad() {
		super.viewDidLoad()

		refreshDataSource()
		// Do any additional setup after loading the view.
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// MARK: - Resource updater

	func refreshDataSource() {
		let request = ChinachuAPI.GuideRequest()
		Session.send(request) { result in
			switch result {
			case .success(let data):
				let start = Date(timeIntervalSinceNow: TimeInterval(-2.hours.in(.second)!)).at(unit: .minute, value: 0)!.at(unit: .second, value: 0)!
				let end = start.addingTimeInterval(TimeInterval(3.days.in(.second)!))
				var channelList: [String] = []
				self.programList = data.filter {!$0.isEmpty}.map {
					$0.filter { $0.startTime >= start && $0.endTime < end }
					}.map { $0.sorted(by: { (p, q) in p.startTime < q.startTime })} // swiftlint:disable:this identifier_name
					.map { progs in
						if progs.isEmpty {
							return []
						}
						var programs = progs
						progs.reversed().enumerated().forEach { (index, program) in
							if index == progs.count - 1 {
								return
							}
							let before = progs[progs.count - index - 2]
							if before.endTime != program.startTime {
								let dummy = Program()
								dummy.startTime = before.endTime
								dummy.duration = program.startTime.timeIntervalSince(before.endTime)
								programs.insert(dummy, at: progs.count - index - 1)
							}
						}
						channelList.append(programs.first!.channel!.name)
						if programs.first!.startTime != start {
							let dummy = Program()
							dummy.startTime = start
							dummy.duration = programs.first!.startTime.timeIntervalSince(start)
							programs.insert(dummy, at: 0)
						}
						return programs
					}.filter {!$0.isEmpty}
				print("Loaded \(data.count)")
			case .failure(let error):
				print("Error \(error.localizedDescription)")
			}
		}
	}

	/*
	// MARK: - Navigation

	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		// Get the new view controller using segue.destinationViewController.
		// Pass the selected object to the new view controller.
	}
	*/
}
