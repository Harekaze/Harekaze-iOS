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
import PKHUD
import Dropdowns
import RealmSwift

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

	@IBOutlet weak var currentTimeGridView: GridView! {
		didSet {
			currentTimeGridView.register(UINib(nibName: "CurrentTimeGridViewCell", bundle: nil), forCellWithReuseIdentifier: "CurrentTimeGridViewCell")
			currentTimeGridView.dataSource = currentTimeDataSource
			currentTimeGridView.delegate = currentTimeDataSource
		}
	}

	// MARK: - Fields
	var programList: [[Any & ProgramDuration]] = []
	var isLoading = false
	let channelListDataSource = ChannelListDataSource()
	let dateTimeDataSource = DateTimeGridViewDataSource()
	let currentTimeDataSource = CurrentTimeGridViewDataSource()
	var refreshedTime: Date! {
		didSet {
			self.dateTimeDataSource.refreshedTime = self.refreshedTime
			self.currentTimeDataSource.refreshedTime = self.refreshedTime

			var dateLabels: [String] = []
			for i in 0..<7 {
				dateLabels.append(refreshedTime.add(components: [.day: i]).string(dateStyle: .short, timeStyle: .none))
			}
			DispatchQueue.main.sync {
				let titleView = TitleView(navigationController: navigationController!, title: self.title!, items: dateLabels)
				titleView?.action = { index in
					titleView?.button.label.text = self.title!
					let indexPath = IndexPath(row: index*24, column: 0)
					self.timeGridView.scrollToRow(at: indexPath)
				}
				self.navigationItem.titleView = titleView
			}
		}
	}

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

		currentTimeGridView.contentInset.top = timeGridView.contentInset.top
		currentTimeGridView.minimumScale.y = tableGridView.minimumScale.y
		currentTimeGridView.maximumScale.y = tableGridView.maximumScale.y

		self.registerForPreviewing(with: self, sourceView: tableGridView)
		refreshDataSource()

		// Dropdowns configuration
		Config.List.DefaultCell.Text.color = .white
		Config.List.DefaultCell.Text.font = UIFont.boldSystemFont(ofSize: 16)
		Config.List.backgroundColor = UIColor(named: "main")!
		Config.ArrowButton.Text.color = .white
		Config.List.Cell.config = { cell, item, index, selected in
			guard let cell = cell as? TableCell else { return }
			cell.label.text = item
			cell.checkmark.isHidden = true
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.currentTimeGridView.isHidden = false
		self.currentTimeGridView.reloadData()
		currentTimeGridView.contentOffset.y = timeGridView.contentOffset.y
		self.tableGridView?.invalidateContentSize()
		self.channelGridView?.invalidateContentSize()
		self.currentTimeGridView?.invalidateContentSize()
		self.view.layoutIfNeeded()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.currentTimeGridView.isHidden = true
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
			self.currentTimeGridView?.invalidateContentSize()
			self.view.layoutIfNeeded()
		})
	}

	// MARK: - Resource updater

	func refreshDataSource() {
		if !programList.isEmpty || isLoading {
			return
		}
		isLoading = true
		if let subview = Bundle.main.loadNibNamed("DataLoadingView", owner: self, options: nil)?.first as? UIView {
			self.view.addSubview(subview)
		}
		ChinachuAPI.GuideRequest().send { result in
			self.isLoading = false
			switch result {
			case .success(let data):
				DispatchQueue.global().async {
					self.refreshedTime = Date()
					let start = (self.refreshedTime - 1.hour).startOf(component: .hour)
					let end = start + 7.days
					var channelList: [String] = []
					self.programList = data.map {
						$0.filter { $0.program!.startTime >= start && $0.program!.endTime < end }
						}.map { $0.map {$0.program!} }
						.filter {!$0.isEmpty}
						.map { progs in
							var programs = progs as [Any & ProgramDuration]
							progs.dropFirst().reversed().enumerated().forEach { (index, program) in
								let before = progs[progs.count - index - 2]
								if before.endTime != program.startTime {
									let dummy = DummyProgram(startTime: before.endTime, endTime: program.startTime)
									programs.insert(dummy, at: progs.count - index - 1)
								}
							}
							if let program = programs.first as? Program {
								channelList.append(program.channel!.name)
							}
							if programs.first!.startTime != start {
								let dummy = DummyProgram(startTime: start, endTime: programs.first!.startTime)
								programs.insert(dummy, at: 0)
							}
							return programs
						}
					DispatchQueue.main.sync {
						let realm = try! Realm()
						try! realm.write {
							let data = data.flatMap { $0 }
							realm.add(data, update: true)
						}
						self.channelListDataSource.set(channels: channelList)
						self.dateTimeDataSource.tableGridView = self.tableGridView
						self.timeGridView.reloadData()
						self.channelGridView.reloadData()
						self.tableGridView.reloadData()
						self.currentTimeGridView.reloadData()
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

// MARK: - 3D touch Peek and Pop delegate
extension GuideViewController: UIViewControllerPreviewingDelegate {
	func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
		let indexPath = tableGridView.indexPathForRow(at: location)
		guard let program = programList[indexPath.column][indexPath.row] as? Program else {
			return nil
		}

		previewingContext.sourceRect = tableGridView.rectForRow(at: indexPath)

		guard let programDetailViewController = self.storyboard!.instantiateViewController(withIdentifier: "ProgramDetailTableViewController") as?
			ProgramDetailTableViewController else {
				return nil
		}
		programDetailViewController.program = program
		return programDetailViewController
	}

	func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
		self.navigationController?.pushViewController(viewControllerToCommit, animated: true)
	}
}

// MARK: - GridView dataSource, delegate
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
		currentTimeGridView.contentScale(scale)
	}

	func gridView(_ gridView: GridView, didSelectRowAt indexPath: IndexPath) {
		gridView.deselectRow(at: indexPath)
		guard let program = programList[indexPath.column][indexPath.row] as? Program else {
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
		if scrollView == tableGridView {
			channelGridView.contentOffset.x = scrollView.contentOffset.x
		}
		timeGridView.contentOffset.y = scrollView.contentOffset.y
		tableGridView.contentOffset.y = scrollView.contentOffset.y
		currentTimeGridView.contentOffset.y = scrollView.contentOffset.y
	}
}

final class CurrentTimeGridViewDataSource: NSObject, GridViewDataSource, GridViewDelegate {
	var refreshedTime: Date!
	private var isEnabled: Bool {
		return refreshedTime != nil
	}

	func numberOfColumns(in gridView: GridView) -> Int {
		return isEnabled ? 6 : 0 // For infinity columns
	}

	func gridView(_ gridView: GridView, numberOfRowsInColumn column: Int) -> Int {
		return isEnabled ? 1 : 0
	}

	func gridView(_ gridView: GridView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		guard let guideTop = refreshedTime.atTime(hour: refreshedTime.hour - 1, minute: 0, second: 0) else {
			return 0
		}
		return CGFloat(Date().timeIntervalSince(guideTop).in(.minute) ?? 0) * 2 + 1
	}

	func gridView(_ gridView: GridView, cellForRowAt indexPath: IndexPath) -> GridViewCell {
		return gridView.dequeueReusableCell(withReuseIdentifier: "CurrentTimeGridViewCell", for: indexPath)
	}
}

final class DateTimeGridViewDataSource: NSObject, GridViewDataSource, GridViewDelegate {
	var tableGridView: GridView!
	var refreshedTime: Date! {
		didSet {
			currentDate = refreshedTime
		}
	}
	private var isEnabled: Bool {
		return refreshedTime != nil
	}
	private var currentDate: Date!

	func gridView(_ gridView: GridView, numberOfRowsInColumn column: Int) -> Int {
		return isEnabled ? 24*10 : 0
	}

	func gridView(_ gridView: GridView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 60 * 2
	}

	func gridView(_ gridView: GridView, cellForRowAt indexPath: IndexPath) -> GridViewCell {
		let cell = gridView.dequeueReusableCell(withReuseIdentifier: "TimeItemGridViewCell", for: indexPath)
		if let cell = cell as? TimeItemGridViewCell {
			cell.setCellEntities((indexPath.row + refreshedTime.hour + 23) % 24)
		}
		return cell
	}

	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		tableGridView.scrollViewDidScroll(scrollView)
		guard let gridView = scrollView as? GridView else {
			return
		}
		let indexPath = gridView.indexPathForRow(at: CGPoint(x: 0, y: gridView.contentOffset.y))
		let indexDate = refreshedTime.add(components: [.hour: indexPath.row])
		if currentDate.day != indexDate.day {
			PKHUD.sharedHUD.dimsBackground = false
			HUD.flash(.label(indexDate.string(dateStyle: .short, timeStyle: .none)))
			PKHUD.sharedHUD.dimsBackground = true
		}
		currentDate = indexDate
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

