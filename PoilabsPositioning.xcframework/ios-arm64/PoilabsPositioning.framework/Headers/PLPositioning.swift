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
    @objc func poilabsPositioning(didUpdateLocation location: CLLocationCoordinate2D, area: Double)
    @objc func poilabsPositioning(didUpdateHeading heading: CLHeading)
    @objc func poilabsPositioningDidStart()
}
@objc
public class PLPositioning: NSObject {
    
    private var timer: Timer?
    private var locationNotFoundCounter = 0
    private var lastLocation: CLLocationCoordinate2D? = nil
    private var lastMultiLocation: CLLocationCoordinate2D? = nil
    private var accuracy = 3.0
    
    private var multiCrosscheckCounter = 0
    
    var config: PLPConfig!
    var conversionFactor: Double!
    var beaconLocationManager: PLPBeaconPositionFinder!
    var pdrManager: PLPPDRManager!
    @objc public var delegate: PoilabsPositioningDelegate?
    
    @objc
    public init(config: PLPConfig) {
        super.init()
        self.config = config
        conversionFactor = config.conversionFactor
        pdrManager = PLPPDRManager(conversionFactor: conversionFactor)
    }
    
//    public func gettestdata() -> [([PLPLocation],CLLocationCoordinate2D, PLPLocation, Int, [[PLPLocation]])] {
//        return PLPIndoorPositioning.shared.testData
//    }
//    
//    public func startPdr(location: CLLocationCoordinate2D) {
//        pdrManager.startPDR(startCoordinate: location)
//    }
    
    @objc
    public func startPoilabsPositioning() {
        if self.config.usePDR {
            
        }
        if self.config.useMultilateration {
            
        }
        if self.config.useGPS {
            
        }
        if beaconLocationManager == nil {
            beaconLocationManager = PLPBeaconPositionFinder(config: config)
        }
        beaconLocationManager.delegate = self
        delegate?.poilabsPositioning(didStatusChange: .waitingForLocation, reason: .noReason)
        beaconLocationManager.startBeaconPositioning()
        self.startTimer()

        pdrManager.delegate = self
    }
    
    @objc public func startPoilabsPositioning(with beaconList: [PLPBeaconNode]) {
        self.config.beaconList = beaconList
        //beaconLocationManager.startTest()
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

extension PLPositioning {
    private func startTimer() {
        let locationUpdateInterval = self.config.locationUpdateInterval
        timer = Timer.scheduledTimer(timeInterval: locationUpdateInterval*5, target: self, selector: #selector(tickOnlocationUpdateInterval), userInfo: nil, repeats: false)
    }
    
    private func stopTimer() {
        PoilabsPositioningUtils.logDebugInformations(log: "Timer stoped", priority: 10)
        timer?.invalidate()
    }
    
    @objc func tickOnlocationUpdateInterval() {
        if lastLocation == nil {
            delegate?.poilabsPositioning(didFail: .beaconNotFound)
            delegate?.poilabsPositioning(didStatusChange: .locationNotFound, reason: .beaconNotFound)
        }
        stopTimer()
    }
}


extension PLPositioning: PLPBeaconPositionFinderDelegate {    
    func beaconPositionFinder(didFindLocation location: PLPLocation, area: Double) {
        let locationCoordinates = location.getLocation()
        self.accuracy = area
        self.lastLocation = locationCoordinates
        delegate?.poilabsPositioning(didUpdateLocation: locationCoordinates, area: area)
        pdrManager.startPDR(startCoordinate: locationCoordinates)
    }
    
    func beaconPositionFinderDidStart() {
        delegate?.poilabsPositioningDidStart()
    }
    
    func beaconPositionFinder(didFindBeacon uuid: String, major: String, minor: String) {
        delegate?.poilabsPositioning(didFindBeacon: uuid, major: major, minor: minor)
    }
    
    func beaconPositionFinder(didFindHeading heading: CLHeading) {
        delegate?.poilabsPositioning(didUpdateHeading: heading)
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
        case .bluetoothNotAvaible:
            delegate?.poilabsPositioning(didFail: .bluetoothNotAvaible)
            delegate?.poilabsPositioning(didStatusChange: .locationNotFound, reason: .missingPermission)
        case .locationNotAvaible:
            delegate?.poilabsPositioning(didFail: .locationNotAvaible)
            delegate?.poilabsPositioning(didStatusChange: .locationNotFound, reason: .missingPermission)
        }
    }
}


extension PLPositioning: PLPPDRManagerDelegate {
    func plpPdrManagerStuck() {
        self.multiCrosscheckCounter = 5
    }
    
    func plpPdrManager(newLocationCalculated location: CLLocationCoordinate2D) {
        self.accuracy += 0.1
        delegate?.poilabsPositioning(didUpdateLocation: location, area: self.accuracy)
        self.lastLocation = location
        PLPIndoorPositioning.shared.setLastPdrLocation(coordinates: location)
    }
}
