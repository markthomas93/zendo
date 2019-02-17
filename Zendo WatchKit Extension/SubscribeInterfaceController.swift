//
//  SubscribeInterfaceController.swift
//  Zendo WatchKit Extension
//
//  Created by Anton Pavlov on 15/02/2019.
//  Copyright © 2019 zenbf. All rights reserved.
//

import WatchKit

class SubscribeInterfaceController: WKInterfaceController {

    @IBAction func subscribeAction() {
        if #available(watchOSApplicationExtension 5.0, *) {
            let userActivity = NSUserActivity(activityType: SettingsWatch.sharedUserActivityType)
            userActivity.userInfo = [SettingsWatch.sharedIdentifierKey: "opneApp"]
            
            update(userActivity)
        } else {
            updateUserActivity(SettingsWatch.sharedUserActivityType, userInfo: [SettingsWatch.sharedIdentifierKey: "opneApp"], webpageURL: nil)
        }
    }
    
    @IBAction func cancelAction() {
        
        Session.current = Session()
        
        Session.current?.start()
        
        WKInterfaceDevice.current().play(WKHapticType.start)
        
        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "SessionInterfaceController", context: Session.current as AnyObject)])
        
    }
    
}
