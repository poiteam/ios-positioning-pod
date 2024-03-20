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
    let multilateration: Bool
    
    @objc
    public init(scanInterval: Double, locationUpdateInterval: Double, beaconFilters: [PLPBeaconFilter], rssiFilter: Double, beaconList: [PLPBeaconNode], multilateration: Bool) {
        self.scanInterval = scanInterval
        self.locationUpdateInterval = locationUpdateInterval
        self.beaconFilters = beaconFilters
        self.rssiFilter = rssiFilter
        self.beaconList = beaconList
        self.multilateration = multilateration
    }
    
    func getBeaconNode(beacon: CLBeacon) -> PLPBeaconNode? {
        return self.beaconList.first(where: {$0.major == Int(truncating: beacon.major) && $0.minor == Int(truncating: beacon.minor) && $0.uuid == beacon.proximityUUID.uuidString})
    }
}
