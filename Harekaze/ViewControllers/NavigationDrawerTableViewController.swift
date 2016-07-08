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

	/// A list of all the navigation items.
	private var dataSourceItems: Array<Item>!

	/// A list of section item height.
	private var itemHeight: Array<CGFloat> = [48]

    override func viewDidLoad() {
        super.viewDidLoad()

		tableView.registerClass(NavigationDrawerMaterialTableViewCell.self, forCellReuseIdentifier: "MaterialTableViewCell")
		tableView.separatorStyle = UITableViewCellSeparatorStyle.None
		prepareCells()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source


    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 5
    }

	/// Prepares the items that are displayed within the tableView.
	private func prepareCells() {
		dataSourceItems = Array<Item>()
		dataSourceItems.append(Item(text: "On Air", image: UIImage(named: "ic_tv")?.imageWithRenderingMode(.AlwaysTemplate)))
		dataSourceItems.append(Item(text: "Guide", image: UIImage(named: "ic_view_list")?.imageWithRenderingMode(.AlwaysTemplate)))
		dataSourceItems.append(Item(text: "Recordings", image: UIImage(named: "ic_video_library")?.imageWithRenderingMode(.AlwaysTemplate)))
		dataSourceItems.append(Item(text: "Timers", image: UIImage(named: "ic_av_timer")?.imageWithRenderingMode(.AlwaysTemplate)))
		dataSourceItems.append(Item(text: "Search", image: UIImage(named: "ic_search")?.imageWithRenderingMode(.AlwaysTemplate)))
	}
	

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MaterialTableViewCell", forIndexPath: indexPath)

		let item: Item = dataSourceItems[indexPath.row]

        // Configure the cell...
		cell.textLabel!.text = item.text
		cell.imageView!.image = item.image

        return cell
    }


	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		super.tableView(tableView, heightForRowAtIndexPath: indexPath)
		return itemHeight[indexPath.section]
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
