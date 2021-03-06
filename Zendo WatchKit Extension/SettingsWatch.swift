//
//  SettingsWatch.swift
//  Zendo WatchKit Extension
//
//  Created by Anton Pavlov on 15/10/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import Foundation
import HealthKit


class SettingsWatch  {
    
    static let defaults = UserDefaults.standard
    
    static let dailyMediationGoalKey = "dailyMediationGoal"
    
    static var fullName: String? {
        set {
            defaults.set(newValue, forKey: "fullNameWatch")
            defaults.synchronize()
        }
        get {
            return defaults.string(forKey: "fullNameWatch")
        }
    }
    
    static var email: String? {
        set {
            defaults.set(newValue, forKey: "emailWatch")
            defaults.synchronize()
        }
        get {
            return defaults.string(forKey: "emailWatch")
        }
    }
    
    static var localNotications: Bool {
        set {
            defaults.set(newValue, forKey: "requestedNotificationPermission")
            defaults.synchronize()
        }
        get {
            return defaults.bool(forKey: "requestedNotificationPermission")
        }
    }
    
    static var dailyMediationGoal: Int {
        set {
            defaults.set(newValue, forKey: dailyMediationGoalKey)
            defaults.synchronize()
        }
        get {
            return defaults.integer(forKey: dailyMediationGoalKey)
        }
    }
    
    static var currentDailyMediationPercent: Int {
        set {
            defaults.set(newValue, forKey: "currentDailyMediationPercent")
            defaults.synchronize()
        }
        get {
            return defaults.integer(forKey: "currentDailyMediationPercent")
        }
    }
    
    static var isFirstSession: Bool {
        set {
            defaults.set(newValue, forKey: "isFirsrSession")
            defaults.synchronize()
        }
        get {
            return defaults.bool(forKey: "isFirsrSession")
        }
    }
    
    static func getHealthKitTypes() -> Set<HKSampleType> {
        let healthKitTypes: Set<HKSampleType> = [
            .workoutType(),
            .quantityType(forIdentifier: .heartRate)!,
            .quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            .categoryType(forIdentifier: .mindfulSession)!
        ]

        return healthKitTypes
    }
    
    static func checkAuthorizationStatus(handle: ((_ success: Bool)->())? = nil) {
        if #available(watchOSApplicationExtension 5.0, *) {
            
            let healthKitTypes = getHealthKitTypes()
            
            var isRequestAuthorization = false
            
            for type in healthKitTypes {
                let status = HKHealthStore().authorizationStatus(for: type)
                
                if status == .sharingDenied || status == .notDetermined {
                    isRequestAuthorization = true
                    break
                }
            }
            
            handle?(!isRequestAuthorization)
                                                                                    
        } else {
            handle?(true)
        }
        
    }
    
}

