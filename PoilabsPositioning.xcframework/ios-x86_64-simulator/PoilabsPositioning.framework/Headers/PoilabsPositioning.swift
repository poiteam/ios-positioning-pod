//
//  PoilabsPositioning.swift
//  PoilabsPositioning
//
//  Created by Emre Kuru on 13.01.2022.
//

import Foundation
import CoreLocation

@objc
public protocol PoilabsPositioningDelegate {
    @objc func poilabsPositioning(didStatusChange status: PLPStatus, reason: PLPLocationStatusReason)
    @objc func poilabsPositioning(didFindBeacon uuid: String, major: String, minor: String)
    @objc func poilabsPositioning(didFail error: PoilabsPositioningError)
    @objc func poilabsPositioning(didUpdateLocation location: PLPBeaconNode)
    @objc func poilabsPositioning(didUpdateHeading heading: CLHeading)
}
@objc
public class PoilabsPositioning: NSObject {
    
    private var timer: Timer?
    private var locationNotFoundCounter = 0
    private var lastCalculatedLocation: PLPBeaconNode? = nil
    
    var config: PLPConfig!
    var beaconLocationManager: PLPBeaconPositionFinder!
    @objc public var delegate: PoilabsPositioningDelegate?
    
    @objc
    public init(config: PLPConfig) {
        super.init()
        self.config = config
    }
    
    deinit {
        print("deinit olduk babam")
    }
    
    @objc
    public func startPoilabsPositioning() {
        if self.config.usePDR {
            
        }
        if self.config.useMultilateration {
            
        }
        if self.config.useGPS {
            
        }
        beaconLocationManager = PLPBeaconPositionFinder(config: config)
        beaconLocationManager.delegate = self
        delegate?.poilabsPositioning(didStatusChange: .waitingForLocation, reason: .noReason)
        beaconLocationManager.startBeaconPositioning()
        self.startTimer()
    }
    
    @objc public func startPoilabsPositioning(with beaconList: [PLPBeaconNode]) {
        self.config.beaconList = beaconList
        startPoilabsPositioning()
    }
    
    @objc
    public func stopPoilabsPositioning() {
        self.stopTimer()
        beaconLocationManager.stopBeaconPositioning()
    }
    
    @objc
    public func closeAllActions() {
        beaconLocationManager.closeBeaconPositioning()
        beaconLocationManager = nil
    }
    
}

extension PoilabsPositioning {
    private func startTimer() {
        let locationUpdateInterval = self.config.locationUpdateInterval
        timer = Timer.scheduledTimer(timeInterval: locationUpdateInterval, target: self, selector: #selector(tickOnlocationUpdateInterval), userInfo: nil, repeats: true)
    }
    
    private func stopTimer() {
        PoilabsPositioningUtils.logDebugInformations(log: "Timer stoped", priority: 10)
        timer?.invalidate()
    }
    
    @objc func tickOnlocationUpdateInterval() {
        guard let lastCalculatedLocation = lastCalculatedLocation else {
            self.locationNotFoundCounter += 1
            PoilabsPositioningUtils.logDebugInformations(log: "No location calculated", priority: 20)
            if self.locationNotFoundCounter >= 3 {
                delegate?.poilabsPositioning(didFail: .beaconNotFound)
                delegate?.poilabsPositioning(didStatusChange: .locationNotFound, reason: .beaconNotFound)
            }
            return
        }
        self.locationNotFoundCounter = 0
        delegate?.poilabsPositioning(didUpdateLocation: lastCalculatedLocation)
    }
}

extension PoilabsPositioning: PLPBeaconPositionFinderDelegate {
    func beaconPositionFinder(didFindBeacon uuid: String, major: String, minor: String) {
        delegate?.poilabsPositioning(didFindBeacon: uuid, major: major, minor: minor)
    }
    
    func beaconPositionFinder(didFindHeading heading: CLHeading) {
        delegate?.poilabsPositioning(didUpdateHeading: heading)
    }
    
    func beaconPositionFinder(didFindPosition location: PLPBeaconNode) {
        lastCalculatedLocation = location
    }
    
    func beaconPositionFinder(didFailWithError error: PoilabsPositioningError) {
        switch error {
        case .emptyList:
            delegate?.poilabsPositioning(didStatusChange: .locationNotFound, reason: .emptyList)
        case .invalidUUID:
            delegate?.poilabsPositioning(didStatusChange: .locationNotFound, reason: .invalidUUID)
        case .didFailWithError:
            delegate?.poilabsPositioning(didStatusChange: .locationNotFound, reason: .noReason)
        case .monitoringDidFailFor:
            delegate?.poilabsPositioning(didStatusChange: .locationNotFound, reason: .noReason)
        case .didFailRangingFor:
            delegate?.poilabsPositioning(didStatusChange: .locationNotFound, reason: .noReason)
        case .timeIntervalInvalid:
            delegate?.poilabsPositioning(didStatusChange: .locationNotFound, reason: .noReason)
        case .beaconNotFound:
            PoilabsPositioningUtils.logDebugInformations(log: "beacon not found", priority: 20)
            lastCalculatedLocation = nil
        case .bluetoothNotAvaible:
            delegate?.poilabsPositioning(didStatusChange: .locationNotFound, reason: .missingPermission)
        case .locationNotAvaible:
            delegate?.poilabsPositioning(didStatusChange: .locationNotFound, reason: .missingPermission)
        }
    }
}
