////
////  Experiment.swift
////  LocationTracker
////
////  Created by Dmytro Chapovskyi on 05.04.2020.
////  Copyright © 2020 Dmytro Chapovskyi. All rights reserved.
////
//
//import UIKit
//​
//class DataProvider: NSObject {
//    
//    var downloadTask: URLSessionDownloadTask!
//    var fileLocation: ((URL) -> ())?
//    var onProgress: ((Double) -> ())?
//    
//    private lazy var bgSession: URLSession = {
//        let config = URLSessionConfiguration.background(withIdentifier: "____________identifier____________")
//        config.isDiscretionary = true
//        config.sessionSendsLaunchEvents = true
//        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
//    }()
//    
//    func startDownload() {
//        if let url = URL(string: "https://speed.hetzner.de/100MB.bin") {
//            downloadTask = bgSession.downloadTask(with: url)
//            downloadTask.earliestBeginDate = Date().addingTimeInterval(1)
//            downloadTask.countOfBytesClientExpectsToSend = 512
//            downloadTask.countOfBytesClientExpectsToReceive = 100 * 1024 * 1024 // 100MB
//            downloadTask.resume()
//        }
//    }
//    
//    func stopDownload() {
//        downloadTask.cancel()
//    }
//}
//​
//extension DataProvider: URLSessionDelegate {
//    
//    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
//        DispatchQueue.main.async {
//            guard
//                let appDelegate = UIApplication.shared.delegate as? AppDelegate,
//                let completionHandler = appDelegate.bgSessionCompletionHandler
//                else { return }
//            
//            appDelegate.bgSessionCompletionHandler = nil
//            completionHandler()
//        }
//    }
//}
//​
//// MARK: - URLSessionDownloadDelegate
//extension DataProvider: URLSessionDownloadDelegate {
//    
//    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
//        print("Did finish downloading: \(location.absoluteString)")
//        DispatchQueue.main.async {
//            self.fileLocation?(location)
//        }
//    }
//    
//    func urlSession(_ session: URLSession,
//                    downloadTask: URLSessionDownloadTask,
//                    didWriteData bytesWritten: Int64,
//                    totalBytesWritten: Int64,
//                    totalBytesExpectedToWrite: Int64) {
//        
//        guard totalBytesExpectedToWrite != NSURLSessionTransferSizeUnknown else { return }
//        
//        let progress = Double(Double(totalBytesWritten)/Double(totalBytesExpectedToWrite))
//        print("Download progress: \(progress)")
//        DispatchQueue.main.async {
//            self.onProgress?(progress)
//        }
//    }
//}
//
//func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//	BGTaskScheduler.shared.register(
//		forTaskWithIdentifier: "pl.snowdog.example.train",
//		using: DispatchQueue.global()
//	) { task in
//		let timer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
//		timer.tolerance = 0.2
//	}
//	return true
//}
