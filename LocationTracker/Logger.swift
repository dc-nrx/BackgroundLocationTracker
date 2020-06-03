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

@objc class Logger: NSObject {
	
	static let logFileName = "LocationTrackerLog.txt"
    
	static let terminationRecord = StoredProperty<String>(key: "Logger.terminationRecord")
  
	static var text: String = {
				
		let fileURL = getDocumentsDirectory().appendingPathComponent(Logger.logFileName)
		do {
			let result = try String(contentsOf: fileURL, encoding: .utf8)
			return result
		}
		catch {
			// No file yet
			return ""
		}
	}()
		
	static func clearAll() {
		text = ""
		saveToDisc()
	}
	
	@objc static func log(_ entry: String) {
		
		text.append(makeRecordString(from: entry))
    
//		DispatchQueue.main.async {
		Logger.saveToDisc()
//		}
	}
  
  @objc static func logAppLaunch() {
    if let terminationRecordValue = terminationRecord.value {
      text.append(terminationRecordValue)
      terminationRecord.value = nil
    }
    log("### APP LAUNCHED ###")
  }
  
  @objc static func logAppTermination() {
    terminationRecord.value = makeRecordString(from: "### APP TERMINATED ###")
  }
  
	private static func saveToDisc() {
		let filePath = getDocumentsDirectory().appendingPathComponent(logFileName)

		do {
			try text.write(to: filePath, atomically: true, encoding: String.Encoding.utf8)
		} catch {
			print("\(error)")
		}
	}

  private static func makeRecordString(from entry: String) -> String {
    return String(format: "\n[%@]# %@", Date().description, entry)
  }
  
  private static func getDocumentsDirectory() -> URL {
      let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
      return paths[0]
  }
    
}
