//
//  ViewController.swift
//  LocationTracker
//
//  Created by Dmytro Chapovskyi on 28.03.2020.
//  Copyright © 2020 Dmytro Chapovskyi. All rights reserved.
//

import UIKit
import CoreLocation

typealias JSON = [String: Any?]

class ViewController: UIViewController {

	@IBOutlet private var textView: UITextView!

	override func viewDidLoad() {
		super.viewDidLoad()
			
		onRefresh()
	}

	@IBAction func onRefresh(_ sender: Any? = nil) {
		let tracker = BackgroundLocationTracker.shared
		textView.text = "FromBG: \(tracker.launchFromBG.value as Any)\n\n savedTimeStampedLocations:\n--------------\n\(tracker.savedTimeStampedLocations.value as Any)\n\nsavedLocationCallbacks:\n--------------\n\(tracker.savedLocationCallbacks.value as Any)"
	}
}

