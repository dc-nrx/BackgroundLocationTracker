//
//  Logger.swift
//  LocationTracker
//
//  Created by Dmytro Chapovskyi on 29.03.2020.
//  Copyright © 2020 Dmytro Chapovskyi. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

extension Notification.Name {
	static let loggerEntryAddedNotification = Notification.Name("Logger.entryAdded")
}

class Logger {
	
	static let entries = StoredProperty<[String]>(key: "Logger.text")

	static func appLaunch(options: [UIApplication.LaunchOptionsKey: Any]?) {
		log("▣▣▣▣ App launched with options: \(String(describing: options))")
	}
	
	static func appLaunchedBecauseOfLocationEvent() {
		log("appLaunchedBecauseOfLocationEvent")
	}
	
	static func didUpdateLocationTime(_ locationTime: LocationTime) {
		log("new location time registered: \(locationTime.location.shortDescription), \(locationTime.date)")
	}
	
	static func didUpdateLocations(_ locations: [CLLocation]) {
		let locationStrings = locations.map { $0.shortDescription }
		log("didUpdateLocations triggered with data: \(locationStrings)")
	}
	
	static func bgTask(location: CLLocation?) {
		log("[bg task] ~~~~ location: \(location?.shortDescription)")
	}
	
	static func timer(location: CLLocation?) {
		log("[timer] ~~~~ location: \(location?.shortDescription)")
	}
	
	static func clearAll() {
		entries.value = nil
	}
	
	private static func log(_ entry: String) {
		let appState: String
		if UIApplication.shared.applicationState == .background {
			appState = "BG"
		}
		else if UIApplication.shared.applicationState == .active {
			appState = "A"
		}
		else {
			appState = "??"
		}
		var currentEntries = entries.value ?? [String]()
		currentEntries.append("[\(appState)] \(Date())# \(entry)")
		entries.value = currentEntries
		NotificationCenter.default.post(name: .loggerEntryAddedNotification, object: nil)
	}
}
