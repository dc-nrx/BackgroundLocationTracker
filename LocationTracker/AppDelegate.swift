//
//  AppDelegate.swift
//  LocationTracker
//
//  Created by Dmytro Chapovskyi on 28.03.2020.
//  Copyright © 2020 Dmytro Chapovskyi. All rights reserved.
//

import UIKit
import BackgroundTasks

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	//MARK:- Configuration
	let enableBackgroundFetch = true
	let minimumBackgroundFetchInterval: TimeInterval = 15 * 60
	
	//MARK:-
	private let bgTaskId = "dc.LocationTracker.sendLocation"
		
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
			
		let urlString = "https://www.mocky.io/v2/5185415ba171ea3a00704eed"
		let headers = ["foo": "bar"]
		
		// Start tracking
		BackgroundLocationTracker.shared.start(url: NSURL(string: urlString)!, httpHeaders: headers)
		
		// Support relaunch on significant location change
		BackgroundLocationTracker.shared.continueIfAppropriate()
		Logger.log("\(#function)")
		
		if enableBackgroundFetch {
			if #available(iOS 13, *) {
				// Modern
				Logger.log("\(#function) - `BGTaskScheduler` flow")
				BGTaskScheduler.shared.register(forTaskWithIdentifier: bgTaskId, using: nil) { task in
					// Downcast the parameter to an app refresh task as this identifier is used for a refresh request.
					self.handleAppRefresh(task: task as! BGAppRefreshTask)
				}
			}
			else {
				// Legacy (iOS <= 12)
				Logger.log("\(#function) - `setMinimumBackgroundFetchInterval` flow")
				UIApplication.shared.setMinimumBackgroundFetchInterval(minimumBackgroundFetchInterval)
			}
		}
				
		return true
	}
	
	func handleAppRefresh(task: BGAppRefreshTask) {
		Logger.log("\(#function)")
		
		scheduleAppRefresh()
		
		let queue = OperationQueue()
		queue.maxConcurrentOperationCount = 1
		
		task.expirationHandler = {
				// After all operations are cancelled, the completion block below is called to set the task to complete.
				queue.cancelAllOperations()
		}

		queue.addOperation {
			BackgroundLocationTracker.shared.sendFromBackgroundFetch { (result) in
				task.setTaskCompleted(success: result != .failed)
			}
		}
	}
	
	func scheduleAppRefresh() {
		Logger.log("\(#function)")
		let request = BGAppRefreshTaskRequest(identifier: bgTaskId)
		request.earliestBeginDate = Date(timeIntervalSinceNow: minimumBackgroundFetchInterval)
		do {
			try BGTaskScheduler.shared.submit(request)
			Logger.log("\(#function) - success")
		} catch {
			Logger.log("\(#function) ERROR - Could not schedule app refresh: \(error)")
		}
	}
	
	// MARK: UISceneSession Lifecycle

//	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
//		// Called when a new scene session is being created.
//		// Use this method to select a configuration to create the new scene with.
//		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
//	}
//
//	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
//		// Called when the user discards a scene session.
//		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
//		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
//	}

	func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		Logger.log(#function)
		BackgroundLocationTracker.shared.sendFromBackgroundFetch(completionHandler: completionHandler)
	}
	
	func applicationDidEnterBackground(_ application: UIApplication) {
		BackgroundLocationTracker.shared.willEnterBackground();
		
		Logger.log("\(#function)")
	}
	
	func applicationWillResignActive(_ application: UIApplication) {
		Logger.log("\(#function)")
	}
	
	func applicationWillEnterForeground(_ application: UIApplication) {
		Logger.log("\(#function)")
	}
	
	func applicationWillTerminate(_ application: UIApplication) {
		Logger.log("\(#function)")
	}
}


