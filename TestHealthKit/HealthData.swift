//
//  HealthData.swift
//  TestHealthKit
//
//  Created by Masamichi Ebata on 2024/07/29.
//

import Foundation
import HealthKit

class HealthData {

    static var healthStore: HKHealthStore = HKHealthStore()

    static var readDataTypes: [HKSampleType] {
        return allHealthDataTypes
    }
    
    static var shareDataTypes: [HKSampleType] {
        return allHealthDataTypes
    }
    
    private static var allHealthDataTypes: [HKSampleType] {
        let typeIdentifiers: [String] = [
            HKQuantityTypeIdentifier.stepCount.rawValue,
            HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue,
            HKQuantityTypeIdentifier.sixMinuteWalkTestDistance.rawValue
        ]
        
        return typeIdentifiers.compactMap { getSampleType(for: $0) }
    }
    
    static func getSampleType(for identifier: String) -> HKSampleType? {
        if let quantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: identifier)) {
            return quantityType
        }
        
        if let categoryType = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: identifier)) {
            return categoryType
        }
        
        return nil
    }
    
    /// Request health data from HealthKit if needed.
    class func requestHealthDataAccessIfNeeded(toShare shareTypes: Set<HKSampleType>?,
                                               read readTypes: Set<HKObjectType>?,
                                               completion: @escaping (_ success: Bool) -> Void) {
        if HKHealthStore.isHealthDataAvailable() {
            print("Requesting HealthKit authorization...")
            healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { (success, error) in
                if let error = error {
                    print("requestAuthorization error:", error.localizedDescription)
                }
                
                if success {
                    print("HealthKit authorization request was successful!")
                } else {
                    print("HealthKit authorization was not successful.")
                }
                
                completion(success)
            }
        } else {
            fatalError("Health data is not available!")
        }
    }    
}
