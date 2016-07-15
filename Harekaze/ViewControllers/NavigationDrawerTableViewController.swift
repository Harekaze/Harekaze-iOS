//
//  NavigationDrawerTableViewController.swift
//  Harekaze
//
//  Created by Yuki MIZUNO on 2016/07/07.
//  Copyright © 2016年 Yuki MIZUNO. All rights reserved.
//

import UIKit
import Material

private struct Item {
	var text: String
	var image: UIImage?
}

class NavigationDrawerTableViewController: UITableViewController {

	// MARK: - Private instance fileds

	/// A list of all the navigation items.
	private var dataSourceItems: Array<Item>! = Array<Item>()

	/// A list of section item height.
	private let itemHeight: Array<CGFloat> = [64, 48]

	/// A list of section item height.
	private let itemNumber: Array<Int> = [1, 5]


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
		dataSourceItems.append(Item(text: "Search", image: UIImage(named: "ic_search")?.imageWithRenderingMode(.AlwaysTemplate)))

		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false

		// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		// self.navigationItem.rightBarButtonItem = self.editButtonItem()
	}

	// MARK: - Memory/resource management

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// MARK: - Table view data source


	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		// #warning Incomplete implementation, return the number of sections
		return itemNumber.count
	}

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// #warning Incomplete implementation, return the number of rows
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
		default:
			let item: Item = dataSourceItems[indexPath.row]

			// Configure the cell...
			cell.textLabel!.text = item.text
			cell.imageView!.image = item.image
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

		let line = CALayer()
		line.borderColor = MaterialColor.grey.lighten1.CGColor
		line.borderWidth = 1
		line.frame = CGRect(x: 0, y: -0.5, width: tableView.frame.width, height: 1)

		layerView.layer.addSublayer(line)

		return layerView
	}

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let item: Item = dataSourceItems[indexPath.row]

		// Change current selected tab
		if let v: UITabBarController = navigationDrawerController?.rootViewController as? UITabBarController {
			switch item.text {
			case "Recordings":
				for viewController:AnyObject in v.viewControllers! {
					if let id = viewController.restorationIdentifier! {
						if id == "RecordingNavigationViewController" {
							v.selectedViewController = viewController as? UIViewController

							break
						}
					}
				}
			default:return
			}
		}

		// Highlight current selected tab
		for i in 0..<tableView.numberOfRowsInSection(indexPath.section) {
			let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: indexPath.section))
			cell?.textLabel?.textColor = MaterialColor.grey.darken3
		}
		let cell = tableView.cellForRowAtIndexPath(indexPath)
		cell?.textLabel?.textColor = MaterialColor.blue.darken3

	}

	/*
	// Override to support conditional editing of the table view.
	override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
	// Return false if you do not want the specified item to be editable.
	return true
	}
	*/

	/*
	// Override to support editing the table view.
	override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
	if editingStyle == .Delete {
	// Delete the row from the data source
	tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
	} else if editingStyle == .Insert {
	// Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
	}
	}
	*/

	/*
	// Override to support rearranging the table view.
	override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

	}
	*/

	/*
	// Override to support conditional rearranging of the table view.
	override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
	// Return false if you do not want the item to be re-orderable.
	return true
	}
	*/

	/*
	// MARK: - Navigation

	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
	// Get the new view controller using segue.destinationViewController.
	// Pass the selected object to the new view controller.
	}
	*/

}
