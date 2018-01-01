/**
 *
 * AppDelegate.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/06/22.
 * 
 * Copyright (c) 2016-2017, Yuki MIZUNO
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
import CoreData
import Material
import RealmSwift
import Fabric
import Crashlytics
import APIKit
import CoreSpotlight
import DropDown
import SwiftDate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

		let statusBarController = StatusBarController(rootViewController: (window?.rootViewController)!)
		statusBarController.statusBarStyle = .lightContent
		statusBarController.statusBar.backgroundColor = Material.Color.blue.darken2
		let navigationDrawerController = NavigationDrawerController(rootViewController: statusBarController,
		                                                            leftViewController: NavigationDrawerTableViewController())
		window!.rootViewController = SnackbarController(rootViewController: navigationDrawerController)

		// Global appearance configuration
		UITabBar.appearance().tintColor = Material.Color.blue.darken1
		UINavigationBar.appearance().backIndicatorImage = UIImage(named: "ic_arrow_back_white")
		UINavigationBar.appearance().backIndicatorTransitionMaskImage = UIImage(named: "ic_arrow_back_white")
		DropDown.appearance().backgroundColor = UIColor.white
		DropDown.appearance().cellHeight = 48
		DropDown.appearance().textFont = RobotoFont.regular(with: 16)
		DropDown.appearance().cornerRadiusPreset = .cornerRadius1
		DropDown.appearance().direction = .bottom
		DropDown.appearance().animationduration = 0.2

		// Realm configuration
		let config = Realm.Configuration(inMemoryIdentifier: "InMemoryRealm")
		Realm.Configuration.defaultConfiguration = config

		// Crashlytics, Answers
		Fabric.sharedSDK().debug = true
		Fabric.with([Crashlytics.self])

		// SwiftDate setting
		Date.setDefaultRegion(Region(tz: Date.defaultRegion.timeZone, cal: Date.defaultRegion.calendar, loc: Locale(identifier: "ja_JP")))

		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state.
		// This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or
		// when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers,
		// and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive.
		// If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		// Saves changes in the application's managed object context before the application terminates.
		self.saveContext()
	}

	// Launch with URL scheme
	func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {
		guard let host = url.host else {
			return true // Only protocol type launching
		}

		switch host {
		case "program":
			let components = url.pathComponents
			if components.count != 3 {
				return false
			}
			let storyboard = UIStoryboard(name: "Main", bundle: nil)

			switch components[1] {
			case "view":
				let request = ChinachuAPI.RecordingDetailRequest(id: components[2])
				Session.send(request) { result in
					switch result {
					case .success(let data):
						guard let programDetailViewController = storyboard.instantiateViewController(withIdentifier: "ProgramDetailTableViewController") as?
							ProgramDetailTableViewController else {
							return
						}
						programDetailViewController.program = data
						guard let rootController = self.window?.rootViewController! as? TransitionController else {
							return
						}
						guard let rootViewController = rootController.rootViewController as? NavigationDrawerController else {
							return
						}
						guard let navigationController = rootViewController.rootViewController as? MainNavigationController else {
							return
						}
						navigationController.pushViewController(programDetailViewController, animated: true)
					case .failure:
						return
					}
				}
			case "watch":
				let request = ChinachuAPI.RecordingDetailRequest(id: components[2])
				Session.send(request) { result in
					switch result {
					case .success(let data):
						guard let videoPlayViewController = storyboard.instantiateViewController(withIdentifier: "VideoPlayerViewController") as? VideoPlayerViewController else {
							return
						}
						videoPlayViewController.program = data
						videoPlayViewController.modalPresentationStyle = .custom
						guard let rootController = self.window?.rootViewController! as? TransitionController else {
							return
						}
						guard let rootViewController = rootController.rootViewController else {
							return
						}
						rootViewController.present(videoPlayViewController, animated: true, completion: nil)
					case .failure:
						return
					}
				}
			default:
				return false
			}
		default:
			return false
		}

		return true
	}

	// Launch with Quick Action
	func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		switch shortcutItem.type {
		case "org.harekaze.Harekaze.search":
			let searchNavigationController = storyboard.instantiateViewController(withIdentifier: "ProgramSearchResultTableViewController")
			let searchBarController = SearchBarController(rootViewController: searchNavigationController)
			searchBarController.modalTransitionStyle = .crossDissolve
			guard let rootController = self.window?.rootViewController! as? TransitionController else {
				return
			}
			guard let rootViewController = rootController.rootViewController as? NavigationDrawerController else {
				return
			}
			rootViewController.present(SearchNavigationController(rootViewController: searchBarController), animated: true, completion: nil)
		default:
			return
		}
	}

	// Launch from Spotlight search result
	func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
		if userActivity.activityType != CSSearchableItemActionType {
			return false
		}
		guard let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
			return false
		}

		let request = ChinachuAPI.RecordingDetailRequest(id: identifier)
		Session.send(request) { result in
			switch result {
			case .success(let data):
				let storyboard = UIStoryboard(name: "Main", bundle: nil)
				guard let programDetailViewController = storyboard.instantiateViewController(withIdentifier: "ProgramDetailTableViewController") as?
					ProgramDetailTableViewController else {
					return
				}
				programDetailViewController.program = data
				guard let rootController = self.window?.rootViewController! as? TransitionController else {
					return
				}
				guard let rootViewController = rootController.rootViewController as? NavigationDrawerController else {
					return
				}
				guard let navigationController = rootViewController.rootViewController as? MainNavigationController else {
					return
				}
				navigationController.pushViewController(programDetailViewController, animated: true)
			case .failure:
				return
			}
		}
		return true
	}

	// MARK: - Core Data stack

	lazy var applicationDocumentsDirectory: URL = {
		// The directory the application uses to store the Core Data store file.
		// This code uses a directory named "org.harekaze.Harekaze" in the application's documents Application Support directory.
		let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		return urls[urls.count-1]
	}()

	lazy var managedObjectModel: NSManagedObjectModel = {
		// The managed object model for the application. This property is not optional.
		// It is a fatal error for the application not to be able to find and load its model.
		let modelURL = Bundle.main.url(forResource: "Harekaze", withExtension: "momd")!
		return NSManagedObjectModel(contentsOf: modelURL)!
	}()

	lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
		// The persistent store coordinator for the application.
		// This implementation creates and returns a coordinator, having added the store for the application to it.
		// This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
		// Create the coordinator and store
		let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
		let url = self.applicationDocumentsDirectory.appendingPathComponent("SingleViewCoreData.sqlite")
		var failureReason = "There was an error creating or loading the application's saved data."
		do {
			try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
		} catch {
			// Report any error we got.
			var dict = [String: AnyObject]()
			dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
			dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?

			dict[NSUnderlyingErrorKey] = error as NSError
			let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
			// Replace this with code to handle the error appropriately.
			// abort() causes the application to generate a crash log and terminate.
			// You should not use this function in a shipping application, although it may be useful during development.
			NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
			abort()
		}

		return coordinator
	}()

	lazy var managedObjectContext: NSManagedObjectContext = {
		// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
		// This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
		let coordinator = self.persistentStoreCoordinator
		var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		managedObjectContext.persistentStoreCoordinator = coordinator
		return managedObjectContext
	}()

	// MARK: - Core Data Saving support

	func saveContext () {
		if managedObjectContext.hasChanges {
			do {
				try managedObjectContext.save()
			} catch {
				// Replace this implementation with code to handle the error appropriately.
				// abort() causes the application to generate a crash log and terminate.
				// You should not use this function in a shipping application, although it may be useful during development.
				let nserror = error as NSError
				NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
				abort()
			}
		}
	}

}
