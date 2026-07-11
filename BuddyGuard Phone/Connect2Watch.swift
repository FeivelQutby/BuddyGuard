//
//  Connect2Watch.swift
//  BuddyGuard WatchOs Watch App
//
//  Created by Benedicta Joyce Sutandyo on 11/07/26.
//

//import Foundation
//import WatchConnectivity
//import CoreLocation
//
//class PhoneConnector: NSObject, WCSessionDelegate {
//    static let shared = PhoneConnector()
//    var session: WCSession
//    
//    init(session: WCSession = .default){
//        self.session = session
//        super.init()
//        session.delegate = self
//        session.activate()
//    }
//    
//    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
//        
//    }
//    
//    func sessionDidBecomeInactive(_ session: WCSession) {
//        
//    }
//    
//    func sessionDidDeactivate(_ session: WCSession) {
//        session.activate()
//    }
//    
//    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
//        guard let action = userInfo["action"] as? String else { return }
//        
//        if action == "startSession"{
//            guard let latitude = userInfo["latitude"] as? Double, let longitude = userInfo["longitude"] as? Double else { return }
//            
//            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//            LiveTrackingManager().startSession(coordinate: coordinate)
//        } else if action == "uploadLocation"{
//            guard let latitude = userInfo["latitude"] as? Double, let longitude = userInfo["longitude"] as? Double else { return }
//            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//            
//            LiveTrackingManager().uploadLocation(coordinate)
//        } else if action == "updateDestination"{
//            guard let name = userInfo["name"] as? String, let latitude = userInfo["latitude"] as? Double, let longitude = userInfo["longitude"] as? Double else { return }
//            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//            
//            LiveTrackingManager().updateDestination(name: name, coordinate: coordinate)
//        } else if action == "updateStatus"{
//            guard let status = userInfo["status"] as? String else { return }
//            LiveTrackingManager().updateStatus(UserState(rawValue: status) ?? .OnTheWay)
//        }
//    }
//}
