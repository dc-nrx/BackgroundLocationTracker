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

/**
The class is intended for tracking significant location changes (including situations when the app is killed) and sending an update request to the backend (see `actionMinInterval`, `url` and `httpHeader` for configuration details).
To use it just call `LocationTracker.shared.start(...)` on `application: didFinishLaunchingWithOptions:` in AppDelegate.
*/
@objc class LocationTracker: NSObject {
	
	static let shared = LocationTracker()
		
	/**
	The minimum interval (in seconds) before execute the action (in the current implementation - send a request on location update event).
	*/
	@objc var actionMinInterval: TimeInterval {
		get {
			return storedActionMinInterval.value ?? 0
		}
		set {
			storedActionMinInterval.value = newValue
		}
	}
	/**
	Needed to store the value between application launches (see `actionMinInterval`).
	*/
	private var storedActionMinInterval = StoredProperty<TimeInterval>(key: "LocationTracker.storedActionMinInterval")
	
	/**
	A URL to send the update location request to.
	*/
	@objc var url: NSURL? {
		get {
			return storedUrl.value as NSURL?
		}
		set {
			storedUrl.value = newValue as URL?
		}
	}
	/**
	Needed to store the value between application launches (see `url`).
	*/
	private var storedUrl = StoredProperty<URL>(key: "LocationTracker.storedUrl")
	
	/**
	A header to construct a location update request.
	*/
	@objc var httpHeader: [String: String]? {
		get {
			return storedHttpHeader.value
		}
		set {
			storedHttpHeader.value = newValue
		}
	}
	/**
	Needed to store the value between application launches (see `httpHeader`).
	*/
	private var storedHttpHeader = StoredProperty<[String: String]>(key: "LocationTracker.storedHttpHeader")
	
	private let locationManager = CLLocationManager()
	
	private var storedLastActionDate = StoredProperty<Date>(key: "LocationTracker.storedLastActionDate")
	
	/**
	The single function you should call. If needed, additional
	*/
	func start(actionMinInterval: TimeInterval, url: URL, httpHeader: [String: String]) {
		
//		actionMinInterval.value =
		
		locationManager.requestAlwaysAuthorization()
		locationManager.allowsBackgroundLocationUpdates = true

		locationManager.delegate = self
		locationManager.startMonitoringSignificantLocationChanges()
		locationManager.distanceFilter = 500;	// might be useless
	}
		
}

//MARK:- Private
private extension LocationTracker {

	/**
	The main function to trigger on location update
	*/
	func main(locations: [CLLocation]) {
		if let lastActionDate = storedLastActionDate.value,
			Date().timeIntervalSince(lastActionDate) < actionMinInterval {
			// The last action has been performed less than `actionMinInterval` seconds ago.
			return
		}
		// Record the new location
		if let lastLocation = locations.last {
			appendToSavedLocations(lastLocation)
		}
		
		sendSavedLocations()
	}
	
	func appendToSavedLocations(_ location: CLLocation) {
		
	}
	
	/**
	Send all the saved locations to the specified `url` (see `makeTimeLocationDict` for the single "location" item structure).
	*/
	func sendSavedLocations() {
		guard let url = url,
			let httpHeader = httpHeader else {
			// TODO: Report error
			return
		}
		
		
	}
	
	func makeTimeLocationDict(location: CLLocation) -> [String: String] {
		return [
			"lat": String(location.coordinate.latitude),
			"long": String(location.coordinate.longitude),
			"timestamp": String(Date().timeIntervalSince1970)
		]
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
