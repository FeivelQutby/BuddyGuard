//
//  WatchConnector.swift
//  BuddyGuard WatchOs Watch App
//
//  Created by Benedicta Joyce Sutandyo on 09/07/26.
//

import Foundation
import WatchConnectivity
import CoreLocation

class WatchConnector: NSObject, WCSessionDelegate {
    static let shared = WatchConnector()
    var session: WCSession
    
    init(session: WCSession = .default){
        self.session = session
        super.init()
        session.delegate = self
        session.activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        
    }
    
    func sendStartSession(with coordinate: CLLocationCoordinate2D) {
        session.transferUserInfo([
            "action": "startSession",
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude
        ])
    }
    
    func sendUploadLocation(with coordinate: CLLocationCoordinate2D){
        session.transferUserInfo([
            "action": "uploadLocation",
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude
        ])
    }
    
    func sendUpdateDestination(name: String, coordinate: CLLocationCoordinate2D){
        session.transferUserInfo([
            "action": "updateDestination",
            "name": name,
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude
            
        ])
    }
    
    func sendUpdateStatus(_ status: UserState){
        session.transferUserInfo([
            "action": "updateStatus",
            "status": status.rawValue
        ])
    }
    
}
