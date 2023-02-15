//
//  PoilabsPositioningConfig.swift
//  PoilabsPositioning
//
//  Created by Emre Kuru on 13.01.2022.
//

import Foundation
import CoreLocation

@objc
public class PLPConfig: NSObject {
    let scanInterval: Double
    let locationUpdateInterval: Double
    let beaconFilters: [PLPBeaconFilter]
    let rssiFilter: Double?
    var beaconList: [PLPBeaconNode]
    let conversionFactor: Double
    let mapRotateAngle: Double
    
    @objc
    public init(scanInterval: Double, locationUpdateInterval: Double, beaconFilters: [PLPBeaconFilter], rssiFilter: Double, beaconList: [PLPBeaconNode], conversionFactor: Double, mapRotateAngle: Double, weinbergConstant: Double) {
        self.scanInterval = scanInterval
        self.locationUpdateInterval = locationUpdateInterval
        self.beaconFilters = beaconFilters
        self.rssiFilter = rssiFilter
        self.beaconList = beaconList
        self.conversionFactor = conversionFactor
        self.mapRotateAngle = mapRotateAngle
        PLPPDRConstants.PLPStep.weinberg = weinbergConstant
    }
    
    func getBeaconNode(beacon: CLBeacon) -> PLPBeaconNode? {
        return self.beaconList.first(where: {$0.major == Int(truncating: beacon.major) && $0.minor == Int(truncating: beacon.minor) && $0.uuid == beacon.proximityUUID.uuidString})
    }
}
