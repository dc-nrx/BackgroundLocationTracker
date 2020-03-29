//
//  BackgroundLocationTracker.swift
//  LocationTracker
//
//  Created by Dmytro Chapovskyi on 28.03.2020.
//  Copyright © 2020 Dmytro Chapovskyi. All rights reserved.
//

import Foundation
import CoreLocation

class BackgroundLocationTracker: NSObject {
	
	static let shared = BackgroundLocationTracker()
	
	let locationManager = CLLocationManager()
	let savedTimeStampedLocations = StoredProperty<[JSON]>(key: "locations")
	let savedLocationCallbacks = StoredProperty<[[String]]>(key: "locationCallbacks")
	let launchFromBG = StoredProperty<Bool>(key: "launchFromBG")
	
	func start() {
		locationManager.requestAlwaysAuthorization()
		
		locationManager.delegate = self
		locationManager.startMonitoringSignificantLocationChanges()
	}
	
	func appLaunchedBecauseOfLocationEvent() {
		launchFromBG.value = true
		start()
	}
}

//MARK:-
extension BackgroundLocationTracker: CLLocationManagerDelegate {
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		
		var updatedTimeStampedLocations = savedTimeStampedLocations.value ?? [JSON]()
		if let newLocation = locations.last {
			let newTimestampedLocation = TimestampedLocation(location: newLocation, timestamp: Date())
			updatedTimeStampedLocations.append(newTimestampedLocation.toJSON())
//			print("\nnewTimestampedLocation: \(newTimestampedLocation.toJSON())")
		}
		
		savedTimeStampedLocations.value = updatedTimeStampedLocations
		
		var updatedSavedLocationCallbacks = savedLocationCallbacks.value ?? [[String]]()
		updatedSavedLocationCallbacks.append(locations.map { "\n\($0.toJSON())" } )
		savedLocationCallbacks.value = updatedSavedLocationCallbacks
		
//		print("\nupdatedTo: \(locations)")
	}
	
}

//MARK:- Helpers
struct TimestampedLocation {
	
	var location: CLLocation
	var timestamp: Date
	
	func toJSON() -> JSON {
		return [
			"latitude": location.coordinate.latitude,
			"longitude": location.coordinate.longitude,
			"timestamp": timestamp.description
		]
	}
}

extension CLLocation {
	func toJSON() -> JSON {
		return [
			"latitude": coordinate.latitude,
			"longitude": coordinate.longitude,
		]
	}
}
