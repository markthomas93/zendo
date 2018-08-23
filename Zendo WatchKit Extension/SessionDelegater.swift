//
//  SessionDelegater.swift
//  FinanceWatch Extension
//
//  Created by Anton Pavlov on 24/06/2018.
//  Copyright © 2018 Anton Pavlov. All rights reserved.
//

import UIKit
import WatchConnectivity

class SessionDelegater: NSObject, WCSessionDelegate, SessionCommands {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Session activation did complete")
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("watch received app context: ", applicationContext)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {

    }
    
}
