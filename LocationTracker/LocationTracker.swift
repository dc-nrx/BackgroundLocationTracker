//
//  BackgroundLocationTracker.swift
//  LocationTracker
//
//  Created by Dmytro Chapovskyi on 28.03.2020.
//  Copyright © 2020 Dmytro Chapovskyi. All rights reserved.
//

import Foundation
import CoreLocation
import BackgroundTasks

class LocationTracker: NSObject {
	
	static let shared = LocationTracker()
	let readLocationInterval: Double = 1 * 60
	
	let backroundTaskId = "com.dc.LocationTracker.readLocation"
	
	let locationManager = CLLocationManager()
	
	func start() {
		
		registerBgTaskUpdateBlock()
		submitBgRequest(interval: readLocationInterval)
		
		locationManager.requestAlwaysAuthorization()
		locationManager.allowsBackgroundLocationUpdates = true

		locationManager.delegate = self
		locationManager.startMonitoringSignificantLocationChanges()
		locationManager.distanceFilter = 500;	// might be useless
	}
	
	func appLaunchedBecauseOfLocationEvent() {
		start()
	}
	
	func registerBgTaskUpdateBlock() {
		BGTaskScheduler.shared.register(forTaskWithIdentifier:
		backroundTaskId,
		using: nil)
		  {[weak self] task in
			if let sself = self {
				Logger.bgTask(location: sself.locationManager.location)
				sself.submitBgRequest(interval: sself.readLocationInterval)
				RunLoop.main.add(Timer(timeInterval: 1, repeats: true) { [weak self] (timer) in
					if let sself = self {
						Logger.timer(location: sself.locationManager.location)
					}
				}, forMode: .default)
			}
		  }
	}
	
	func submitBgRequest(interval: TimeInterval) {
		   let request = BGAppRefreshTaskRequest(identifier: backroundTaskId)
		   request.earliestBeginDate = Date(timeIntervalSinceNow: readLocationInterval)
		   do {
			  try BGTaskScheduler.shared.submit(request)
		   } catch {
			  print("Could not schedule app refresh: \(error)")
		   }
	}
}

//MARK:-
extension LocationTracker: CLLocationManagerDelegate {
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

		if let lastLocation = locations.last {
			let locationTime = (lastLocation, Date())
			Logger.didUpdateLocationTime(locationTime)
		}
		
		Logger.didUpdateLocations(locations)
		
	}
	
}
