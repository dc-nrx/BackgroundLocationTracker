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

	let enableBackgroundFetch = true
	
	let minimumBackgroundFetchInterval: TimeInterval = 15 * 60
	
	let bgTaskId = "dc.LocationTracker.sendLocation"
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
			
		let urlString = "https://www.mocky.io/v2/5185415ba171ea3a00704eed"
		let headers = ["foo": "bar"]
		
		// Start tracking
		BackgroundLocationTracker.shared.start(url: NSURL(string: urlString)!, httpHeaders: headers)
		
		// Support relaunch on significant location change
		BackgroundLocationTracker.shared.continueIfAppropriate()
		
		if enableBackgroundFetch {
			if #available(iOS 13, *) {
				let request = BGAppRefreshTaskRequest(identifier: bgTaskId)
				// Fetch no earlier than 15 minutes from now
				request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
						 
				do {
					 try BGTaskScheduler.shared.submit(request)
				} catch {
					 print("Could not schedule app refresh: \(error)")
				}
			}
			else {
				UIApplication.shared.setMinimumBackgroundFetchInterval(minimumBackgroundFetchInterval)
			}
		}
				
		return true
	}

	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
	}

}

