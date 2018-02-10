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

import UIKit
import APIKit
import SwiftDate
import G3GridView
import Crashlytics
import StatusAlert

class GuideViewController: UIViewController {
	// MARK: - IBOutlets
	@IBOutlet weak var tableGridView: GridView! {
		didSet {
			tableGridView.register(UINib(nibName: "ProgramItemGridViewCell", bundle: nil), forCellWithReuseIdentifier: "ProgramItemGridViewCell")
			tableGridView.minimumScale = Scale(x: 0.5, y: 0.5)
			tableGridView.maximumScale = Scale(x: 1.5, y: 1.5)
		}
	}
	@IBOutlet weak var channelGridView: GridView! {
		didSet {
			channelGridView.register(UINib(nibName: "ChannelItemGridViewCell", bundle: nil), forCellWithReuseIdentifier: "ChannelItemGridViewCell")
			channelGridView.dataSource = channelListDataSource
			channelGridView.delegate = channelListDataSource
		}
	}
	@IBOutlet weak var timeGridView: GridView! {
		didSet {
			timeGridView.register(UINib(nibName: "TimeItemGridViewCell", bundle: nil), forCellWithReuseIdentifier: "TimeItemGridViewCell")
			timeGridView.dataSource = dateTimeDataSource
			timeGridView.delegate = dateTimeDataSource
		}
	}

	var programList: [[Program]] = []
	let channelListDataSource = ChannelListDataSource()
	let dateTimeDataSource = DateTimeGridViewDataSource()

	// MARK: - View initialization

	override func viewDidLoad() {
		super.viewDidLoad()

		tableGridView.contentInset.top = channelGridView.bounds.height
		tableGridView.scrollIndicatorInsets.top = tableGridView.contentInset.top
		tableGridView.scrollIndicatorInsets.left = timeGridView.bounds.width

		channelGridView.minimumScale.x = tableGridView.minimumScale.x
		channelGridView.maximumScale.x = tableGridView.maximumScale.x

		timeGridView.contentInset.top = channelGridView.bounds.height
		timeGridView.minimumScale.y = tableGridView.minimumScale.y
		timeGridView.maximumScale.y = tableGridView.maximumScale.y

		refreshDataSource()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		coordinator.animate(alongsideTransition: { _ in
			self.tableGridView?.invalidateContentSize()
			self.channelGridView?.invalidateContentSize()
			self.view.layoutIfNeeded()
		})
	}

	// MARK: - Resource updater

	func refreshDataSource() {
		if let subview = Bundle.main.loadNibNamed("DataLoadingView", owner: self, options: nil)?.first as? UIView {
			self.view.addSubview(subview)
		}
		let request = ChinachuAPI.GuideRequest()
		IndicatableSession.send(request) { result in
			switch result {
			case .success(let data):
				DispatchQueue.global().async {
					// TODO: Add local in-memory realm store

					let start = (Date() - 1.hour).startOf(component: .hour)
					let end = start + 3.days
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
					DispatchQueue.main.sync {
						self.channelListDataSource.set(channels: channelList)
						self.dateTimeDataSource.isEnabled = true
						self.timeGridView.reloadData()
						self.channelGridView.reloadData()
						self.tableGridView.reloadData()
						if let loadingView = self.view.subviews.filter({ ($0.restorationIdentifier ?? "") == "DataLoadingView" }).first {
							loadingView.removeFromSuperview()
						}
					}
				}
			case .failure(let error):
				if let loadingView = self.view.subviews.filter({ ($0.restorationIdentifier ?? "") == "DataLoadingView" }).first {
					loadingView.removeFromSuperview()
				}
				StatusAlert.instantiate(withImage: #imageLiteral(resourceName: "error"),
										title: "Load guide failed",
										message: ChinachuAPI.parseErrorMessage(error),
										canBePickedOrDismissed: false).showInKeyWindow()
			}
		}
	}
}

extension GuideViewController: GridViewDataSource, GridViewDelegate {
	func numberOfColumns(in gridView: GridView) -> Int {
		return programList.count
	}

	func gridView(_ gridView: GridView, numberOfRowsInColumn column: Int) -> Int {
		return programList[column].count
	}

	func gridView(_ gridView: GridView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return CGFloat((programList[indexPath.column][indexPath.row].duration.in(.minute) ?? 0) * 2)
	}

	func gridView(_ gridView: GridView, cellForRowAt indexPath: IndexPath) -> GridViewCell {
		let cell = gridView.dequeueReusableCell(withReuseIdentifier: "ProgramItemGridViewCell", for: indexPath)
		if let cell = cell as? ProgramItemGridViewCell {
			cell.setCellEntities(programList[indexPath.column][indexPath.row])
		}
		return cell
	}

	func gridView(_ gridView: GridView, didScaleAt scale: CGFloat) {
		channelGridView.contentScale(scale)
		timeGridView.contentScale(scale)
	}

	func gridView(_ gridView: GridView, didSelectRowAt indexPath: IndexPath) {
		gridView.deselectRow(at: indexPath)
		let program = programList[indexPath.column][indexPath.row]
		if program.channel == nil {
			return
		}
		guard let programDetailViewController = self.storyboard!.instantiateViewController(withIdentifier: "ProgramDetailTableViewController") as?
			ProgramDetailTableViewController else {
				return
		}
		programDetailViewController.program = program
		self.navigationController?.pushViewController(programDetailViewController, animated: true)
	}

	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		channelGridView.contentOffset.x = scrollView.contentOffset.x
		timeGridView.contentOffset.y = scrollView.contentOffset.y
	}
}

final class DateTimeGridViewDataSource: NSObject, GridViewDataSource, GridViewDelegate {
	var isEnabled = false

	func gridView(_ gridView: GridView, numberOfRowsInColumn column: Int) -> Int {
		return isEnabled ? 24*3 : 0
	}

	func gridView(_ gridView: GridView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 60 * 2
	}

	func gridView(_ gridView: GridView, cellForRowAt indexPath: IndexPath) -> GridViewCell {
		let cell = gridView.dequeueReusableCell(withReuseIdentifier: "TimeItemGridViewCell", for: indexPath)
		if let cell = cell as? TimeItemGridViewCell {
			cell.setCellEntities((indexPath.row + Date().hour + 23) % 24)
		}
		return cell
	}
}

final class ChannelListDataSource: NSObject, GridViewDataSource, GridViewDelegate {
	var channels: [String] = []

	func set(channels: [String]) {
		self.channels = channels
	}

	func numberOfColumns(in gridView: GridView) -> Int {
		return channels.count
	}

	func gridView(_ gridView: GridView, numberOfRowsInColumn column: Int) -> Int {
		return 1
	}

	func gridView(_ gridView: GridView, cellForRowAt indexPath: IndexPath) -> GridViewCell {
		let cell = gridView.dequeueReusableCell(withReuseIdentifier: "ChannelItemGridViewCell", for: indexPath)
		if let cell = cell as? ChannelItemGridViewCell {
			cell.channelLabel.text = channels[indexPath.column]
		}
		return cell
	}
}

