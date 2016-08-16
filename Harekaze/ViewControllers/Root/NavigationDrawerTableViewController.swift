/**
 *
 * NavigationDrawerTableViewController.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/07/07.
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

import UIKit
import Material

private struct Item {
	var text: String
	var image: UIImage?
}

class NavigationDrawerTableViewController: UITableViewController {

	// MARK: - Private instance fileds
	private var dataSourceItems: Array<Item>! = Array<Item>()
	private var secondDataSourceItems: Array<Item>! = Array<Item>()
	private let itemHeight: Array<CGFloat> = [64, 48, 48]
	private let itemNumber: Array<Int> = [1, 4, 1]


	// MARK: - View initialization

	override func viewDidLoad() {
		super.viewDidLoad()

		tableView.registerClass(NavigationDrawerMaterialTableViewCell.self, forCellReuseIdentifier: "MaterialTableViewCell")
		tableView.separatorStyle = UITableViewCellSeparatorStyle.None

		/// Prepares the items that are displayed within the tableView.
		dataSourceItems.append(Item(text: "On Air", image: UIImage(named: "ic_tv")?.imageWithRenderingMode(.AlwaysTemplate)))
		dataSourceItems.append(Item(text: "Guide", image: UIImage(named: "ic_view_list")?.imageWithRenderingMode(.AlwaysTemplate)))
		dataSourceItems.append(Item(text: "Recordings", image: UIImage(named: "ic_video_library")?.imageWithRenderingMode(.AlwaysTemplate)))
		dataSourceItems.append(Item(text: "Timers", image: UIImage(named: "ic_av_timer")?.imageWithRenderingMode(.AlwaysTemplate)))

		secondDataSourceItems.append(Item(text: "Settings", image: UIImage(named: "ic_settings")?.imageWithRenderingMode(.AlwaysTemplate)))
	}

	// MARK: - Memory/resource management

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	// MARK: - Table view data source

	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return itemNumber.count
	}

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return itemNumber[section]
	}


	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("MaterialTableViewCell", forIndexPath: indexPath)

		switch indexPath.section {
		case 0:
			cell.imageView?.image = UIImage(named: "Harekaze")
			cell.imageView?.layer.cornerRadius = 12
			cell.imageView?.clipsToBounds = true
			cell.textLabel?.text = "Harekaze"
			cell.textLabel?.textColor = MaterialColor.grey.darken3
		case 1:
			let item: Item = dataSourceItems[indexPath.row]

			cell.textLabel!.text = item.text
			cell.imageView!.image = item.image
		case 2:
			let item: Item = secondDataSourceItems[indexPath.row]

			cell.textLabel!.text = item.text
			cell.imageView!.image = item.image
		default:break
		}

		return cell
	}


	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return itemHeight[indexPath.section]
	}



	override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 8
	}

	override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		let layerView = UIView()
		layerView.clipsToBounds = true

		if section != itemNumber.count - 1 {
			let line = CALayer()
			line.borderColor = MaterialColor.grey.lighten1.CGColor
			line.borderWidth = 1
			line.frame = CGRect(x: 0, y: -0.5, width: tableView.frame.width, height: 1)
			layerView.layer.addSublayer(line)
		}

		return layerView
	}

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		// Change current selected tab
		guard let navigationController = navigationDrawerController?.rootViewController as? NavigationController else {
			return
		}

		switch indexPath.section {
		case 1:
			let item: Item = dataSourceItems[indexPath.row]

			if let v = navigationController.viewControllers.first as? BottomNavigationController {
				for viewController: UIViewController in v.viewControllers! {
					if item.text == viewController.title! {
						v.selectedViewController = viewController

						// Highlight current selected tab
						for i in 0..<tableView.numberOfRowsInSection(indexPath.section) {
							let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: indexPath.section))
							cell?.textLabel?.textColor = MaterialColor.grey.darken3
						}
						let cell = tableView.cellForRowAtIndexPath(indexPath)
						cell?.textLabel?.textColor = MaterialColor.blue.darken3

						break
					}
				}
			}
		case 2:
			let item: Item = secondDataSourceItems[indexPath.row]
			let navigationController = navigationController.storyboard!.instantiateViewControllerWithIdentifier("\(item.text)NavigationController")
			presentViewController(navigationController, animated: true, completion: {
				self.navigationDrawerController?.closeLeftView()
			})
			
		default:break
		}
	}


}
