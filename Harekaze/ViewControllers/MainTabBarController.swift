//
//  MainTabBarController.swift
//  Harekaze
//
//  Created by Yuki MIZUNO on 2016/07/16.
//  Copyright © 2016年 Yuki MIZUNO. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {

	// MARK: - View initialization

    override func viewDidLoad() {
        super.viewDidLoad()

		// Set tab bar transparent background
		let emptyImage = UIImage()
		tabBar.hidden = true
		tabBar.translucent = true
		tabBar.shadowImage = emptyImage
		tabBar.backgroundColor = UIColor.clearColor()
		tabBar.backgroundImage = emptyImage
    }

	// MARK: - Memory/resource management
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
