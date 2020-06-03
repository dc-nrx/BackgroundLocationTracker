//
//  BackgroundLocationTracker.swift
//
//
//  Created by Dmytro Chapovskyi on 28.03.2020.
//  Copyright © 2020 Dmytro Chapovskyi. All rights reserved.
//
import Foundation
import CoreLocation
import UIKit

/**
 The class is intended for tracking significant location changes (including situations when the app is killed) and sending an update request to the backend (see `actionMinInterval`, `url` and `httpHeader` for configuration details).
 To use it just call `BackgroundLocationTracker.shared.start(...)` on `application: didFinishLaunchingWithOptions:` in AppDelegate.
 The request body structure is determined by `makeLocationDateDict` method.
 */
@objc(BackgroundLocationTracker)
class BackgroundLocationTracker: NSObject {

	//MARK:- Configuration
	
	let trackSignificantLocationChange = true
   
	let trackRegularLocationChange = true

	let minimumActionInterval: TimeInterval = 15 * 60
	
	let locationAccuracy: CLLocationAccuracy = kCLLocationAccuracyHundredMeters

	let distanceFilter: Double = 50
	
	//MARK:- Public members

	@objc static let shared = BackgroundLocationTracker()

	/**
	A URL to send the update location request to.
	*/
	var storedURLString = StoredProperty<String>(key: "BackgroundLocationTracker.storedURLString")

	/**
	A header to construct a location update request.
	*/
	var storedHTTPHeaders = StoredProperty<[String: String]>(key: "BackgroundLocationTracker.storedHTTPHeaders")

	//MARK:- Private members

	/**
	The standard location manager.
	*/
	private let locationManager = CLLocationManager()

	/**
	An array with "location-date" dictionary records (see `makeTimeLocationDict` for the records structure), which hasn't been sent to the server for some reasons.
	*/
	private var storedUnsentLocations = StoredProperty<[[String: String]]>(key: "BackgroundLocationTracker.storedUnsentLocations")

	/**
	Timestamp of the last location-date tracked.
	*/
	private var storedLastActionDate = StoredProperty<Date>(key: "BackgroundLocationTracker.storedLastActionDate")

	private var trackingEnabled = StoredProperty<Bool>(key: "BackgroundLocationTracker.trackingEnabled")
  
  /**
   Call the function whenever nesseccary; then to support background tracking you must call `continueIfAppropriate()` - see the doc.
   WARNING: parameter `actionMinimumInterval` is ignored
   */
   @objc func start(url: NSURL, httpHeaders: [String: String]) {
    if self != BackgroundLocationTracker.shared {
      BackgroundLocationTracker.shared.start(url: url, httpHeaders: httpHeaders)
      return
    }
    
    self.storedURLString.value = url.absoluteString
    self.storedHTTPHeaders.value = httpHeaders
    
    trackingEnabled.value = true
    setupLocationManager()
  }
  
  /**
   Call this method in `application: didFinishLaunchingWithOptions:` to enable background location updates
   If `start(...)` hasn't been called before, nothing will happen.
   */
  @objc func continueIfAppropriate() {
    
    if self != BackgroundLocationTracker.shared {
      BackgroundLocationTracker.shared.continueIfAppropriate()
      return
    }
    
    if let isEnabled = trackingEnabled.value,
      isEnabled,
      self.storedURLString.value != nil,
      self.storedHTTPHeaders.value != nil {
      
      setupLocationManager()
    }
  }
  
  @objc func didReceiveUpdateLocationPushNotification() {
    
    if self != BackgroundLocationTracker.shared {
      BackgroundLocationTracker.shared.didReceiveUpdateLocationPushNotification()
      return
    }
    
    Logger.log("\(#function): start")
    
    continueIfAppropriate()
    
    guard let location = locationManager.location else {
      Logger.log("\(#function):  (ERROR) location == nil")
      return
    }
    
    main(locations: [location])
  }
  
  @objc func stop() {
    if self != BackgroundLocationTracker.shared {
      BackgroundLocationTracker.shared.stop()
    }
    
    locationManager.stopMonitoringSignificantLocationChanges()
    
    locationManager.allowsBackgroundLocationUpdates = false
    
    storedURLString.value = nil
    storedHTTPHeaders.value = nil
    storedUnsentLocations.value = nil
    
    trackingEnabled.value = false
  }
  
  @objc func sendFromBackgroundFetch(completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    
    setupLocationManager()
    
    if let location = locationManager.location {
      main(locations: [location]) {
        Logger.log("\(#function) -- flow finished; calling completion handler")
        completionHandler(.newData)
      }
    }
    else {
      Logger.log("\(#function) has failed (locationManager.location == nil)")
      completionHandler(.noData)
    }
  }
  
  @objc func willEnterBackground() {
    // testing - try to force 'always allow' popup (doesn't seem to work)
    // locationManager.requestAlwaysAuthorization()
  }
  
}

//MARK:- Private
private extension BackgroundLocationTracker {
  
  func setupLocationManager() {
    Logger.log("\(#function)")
    
		// Initial setup
    locationManager.requestAlwaysAuthorization()
    locationManager.allowsBackgroundLocationUpdates = true
    locationManager.delegate = self
    
		// Significant
		if trackSignificantLocationChange {
			locationManager.startMonitoringSignificantLocationChanges()
		}
    
		// Regular
		if trackRegularLocationChange {
			locationManager.startUpdatingLocation()
			locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
			locationManager.distanceFilter = distanceFilter
		}
		
  }
  
  /**
   The main function to trigger on location update
   */
  func main(locations: [CLLocation], _ completion: (()->())? = nil) {
    
    if self != BackgroundLocationTracker.shared {
      return
    }
    
    Logger.log("\(#function)")
    
    if let lastLocation = locations.last {
      appendToSavedLocations(lastLocation)
    }
    
    sendSavedLocations(completion)
  }
  
  /**
   Store the newly tracked location-date.
   */
  func appendToSavedLocations(_ location: CLLocation) {
    var unsentLocations = storedUnsentLocations.value ?? [[String: String]]()
    unsentLocations.append(makeLocationDateDict(location: location))
    storedUnsentLocations.value = unsentLocations
  }
  
  /**
   Send all the saved locations to the specified `url` (see `makeTimeLocationDict` for the single "location" item structure).
   */
  func sendSavedLocations(_ completion: (()->())? = nil) {
    Logger.log("\(#function)")
    guard let locations = storedUnsentLocations.value else {
      Logger.log("\(#function): (ERROR) no locations stored")
      return
    }
    send(locations: locations, completion)
  }
  
  func send(locations: [[String: String]], _ completion: (()->())? = nil) {
    Logger.log("\(#function): start")
    
    // Ensure all required data is in place
    guard let urlString = storedURLString.value,
      let url = URL(string: urlString),
      var httpHeaders = storedHTTPHeaders.value else {
        
        Logger.log("\(#function): (ERROR) no configuration for request")
        completion?()
        return
    }
    
    // Check that the minimum interval have passed
    if let lastActionDate = storedLastActionDate.value,
      Date().timeIntervalSince(lastActionDate) < minimumActionInterval {
      // The last action has been performed less than `minimumActionInterval` seconds ago.
      Logger.log("\(#function): minimum interval haven't passed yet")
      completion?()
      return
    }
    storedLastActionDate.value = Date()
    
    // Prepare the request
    var request = URLRequest(url: url as URL)
    request.httpMethod = "POST"
    // Headers
    httpHeaders["Content-Type"] = "application/json"
    request.allHTTPHeaderFields = httpHeaders
    // Body
    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: locations, options: JSONSerialization.WritingOptions.prettyPrinted)
    } catch {
      emergencyUnsentLocationsCleanup()
      Logger.log("\(#function): (ERROR) serialization failed with error \(error)")
    }
    
    // Send the request
    let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
      guard error == nil,
        let httpResponse = response as? HTTPURLResponse,
        200...299 ~= httpResponse.statusCode else {
          // do nothing - try again later
          Logger.log("\(#function): (ERROR) request failed with error: \(String(describing: error))")
          completion?()
          return
      }
      // Delete the locations that have been sent
      self.storedUnsentLocations.value = nil
      Logger.log("\(#function): request succeeded")
      completion?()
    })
    
    task.resume()
    Logger.log("\(#function): request sent")
  }
  
  /**
   Constrct a location-date dictionary to save -> send to the backend.
   */
  func makeLocationDateDict(location: CLLocation) -> [String: String] {
    let result = [
      "lat": String(location.coordinate.latitude),
      "long": String(location.coordinate.longitude),
      "timestamp": location.timestamp.description
    ]
    
    return result
  }
  
  /**
   Not supposed to be ever executed - just in case of unexpected cached data corruption or overflow.
   */
  func emergencyUnsentLocationsCleanup() {
    self.storedUnsentLocations.value = nil
  }
}

//MARK:-
extension BackgroundLocationTracker: CLLocationManagerDelegate {
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    Logger.log("\(#function): new locations = \(locations)")
    main(locations: locations)
  }
  
}
