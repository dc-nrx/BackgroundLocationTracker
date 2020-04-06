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
		NotificationCenter.default.addObserver(forName: .loggerEntryAddedNotification, object: nil, queue: nil) { [weak self] (_) in
			self?.onRefresh()
		}
	}

	@IBAction func onRefresh(_ sender: Any? = nil) {
		textView.text = Logger.entries.value?.joined(separator: "\n----\n")
	}
}

