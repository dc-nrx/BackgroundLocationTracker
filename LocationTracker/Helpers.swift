//
//  Helpers.swift
//  LocationTracker
//
//  Created by Dmytro Chapovskyi on 29.03.2020.
//  Copyright © 2020 Dmytro Chapovskyi. All rights reserved.
//

import Foundation
import CoreLocation

typealias LocationTime = (location: CLLocation, date: Date)

extension CLLocation {
	
	var shortDescription: String {
		"(lat: \(coordinate.latitude), long: \(coordinate.longitude))"
	}
	
	func toJSON() -> JSON {
		return [
			"latitude": coordinate.latitude,
			"longitude": coordinate.longitude,
		]
	}
	
}
