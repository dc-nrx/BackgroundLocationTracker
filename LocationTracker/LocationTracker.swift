//
//  BackgroundLocationTracker.swift
//  LocationTracker
//
//  Created by Dmytro Chapovskyi on 28.03.2020.
//  Copyright © 2020 Dmytro Chapovskyi. All rights reserved.
//

import Foundation
import CoreLocation

/**
The class is intended for tracking significant location changes (including situations when the app is killed) and sending an update request to the backend (see `actionMinInterval`, `url` and `httpHeader` for configuration details).
To use it just call `LocationTracker.shared.start(...)` on `application: didFinishLaunchingWithOptions:` in AppDelegate.
*/
@objc class LocationTracker: NSObject {
	
	//MARK:- Public members
	
	@objc static let shared = LocationTracker()
	
	/**
	The minimum interval (in seconds) before execute the action (in the current implementation - send a request on location update event).
	*/
	@objc var actionMinInterval: TimeInterval = 1 // 14 * 60
	
	/**
	A URL to send the update location request to.
	*/
	@objc var url: NSURL!
	
	/**
	A header to construct a location update request.
	*/
	@objc var httpHeader: [String: String]!
	
	//MARK:- Private members
	
	private let locationManager = CLLocationManager()
	private var storedLastActionDate = StoredProperty<Date>(key: "LocationTracker.storedLastActionDate")
	/**
	An array with "location-date" dictionary records (see `makeTimeLocationDict` for structure).
	*/
	private var storedUnsentLocations = StoredProperty<[[String: String]]>(key: "LocationTracker.storedUnsentLocations")
	
	/**
	Call the function on `application: didFinishLaunchingWithOptions:`.
	*/
	@objc func start(actionMinInterval: TimeInterval, url: NSURL, httpHeader: [String: String]) {
		
		self.actionMinInterval = actionMinInterval
		self.url = url
		self.httpHeader = httpHeader
		
		setupLocationManager()
	}
		
}

//MARK:- Private
private extension LocationTracker {

	func setupLocationManager() {
		locationManager.requestAlwaysAuthorization()
		locationManager.allowsBackgroundLocationUpdates = true

		locationManager.delegate = self
		locationManager.startMonitoringSignificantLocationChanges()
		
		locationManager.distanceFilter = 500;	// might be useless
	}
	
	/**
	The main function to trigger on location update
	*/
	func main(locations: [CLLocation]) {
		Logger.log("### main")
		if let lastActionDate = storedLastActionDate.value,
			Date().timeIntervalSince(lastActionDate) < actionMinInterval {
			// The last action has been performed less than `actionMinInterval` seconds ago.
			return
		}
		// Record the new location
		if let lastLocation = locations.last {
			appendToSavedLocations(lastLocation)
			storedLastActionDate.value = Date()
		}
		
		sendSavedLocations()
	}
	
	func appendToSavedLocations(_ location: CLLocation) {
		var unsentLocations = storedUnsentLocations.value ?? [[String: String]]()
		unsentLocations.append(makeTimeLocationDict(location: location))
		storedUnsentLocations.value = unsentLocations
	}
	
	/**
	Send all the saved locations to the specified `url` (see `makeTimeLocationDict` for the single "location" item structure).
	*/
	func sendSavedLocations() {
		guard let url = url else {
			// TODO: Report "no url" error
			return
		}
		
		guard let locations = storedUnsentLocations.value else { return }
		// Setup request
		var request = URLRequest(url: url as URL)
		request.httpMethod = "POST"
		request.allHTTPHeaderFields = httpHeader
		// Make the request body
		do {
			request.httpBody = try JSONSerialization.data(withJSONObject: locations, options: JSONSerialization.WritingOptions.prettyPrinted)
		} catch { // let myJSONError {
			// TODO: report serialization error
		}
		// Send the request
		let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
			Logger.log("request finished with error \(String(describing: error)); response code: \(String(describing: response))")
			guard error == nil,
				let httpResponse = response as? HTTPURLResponse,
				200...299 ~= httpResponse.statusCode else {
				// do nothing - try again later
				return
			}
			// Delete locations which has been sent
			self.storedUnsentLocations.value = nil
		})
		task.resume()
	}
	
	func makeTimeLocationDict(location: CLLocation) -> [String: String] {
		let result = [
			"lat": String(location.coordinate.latitude),
			"long": String(location.coordinate.longitude),
			"timestamp": Date().description
		]		
		return result
		
	}
}

//MARK:-
extension LocationTracker: CLLocationManagerDelegate {
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

		main(locations: locations)
		
//		if let lastLocation = locations.last {
//			let locationTime = (lastLocation, Date())
//			Logger.didUpdateLocationTime(locationTime)
//		}
//
		Logger.didUpdateLocations(locations)
		
	}
	
}
