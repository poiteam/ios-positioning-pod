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
    @objc func poilabsPositioning(didUpdateLocation location: CLLocationCoordinate2D, method: String, area: Double)
    @objc func poilabsPositioning(didUpdateHeading heading: CLHeading)
    @objc func poilabsPositioningDidStart()
}
@objc
public class PLPositioning: NSObject {
    
    private var timer: Timer?
    private var locationNotFoundCounter = 0
    private var lastCalculatedLocation: PLPBeaconNode? = nil
    private var lastPdrLocation: CLLocationCoordinate2D? = nil
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
        timer = Timer.scheduledTimer(timeInterval: locationUpdateInterval, target: self, selector: #selector(tickOnlocationUpdateInterval), userInfo: nil, repeats: true)
    }
    
    private func stopTimer() {
        PoilabsPositioningUtils.logDebugInformations(log: "Timer stoped", priority: 10)
        timer?.invalidate()
    }
    
    @objc func tickOnlocationUpdateInterval() {
        guard lastCalculatedLocation != nil else {
            self.locationNotFoundCounter += 1
            PoilabsPositioningUtils.logDebugInformations(log: "No location calculated", priority: 20)
            if self.locationNotFoundCounter >= 5 {
                delegate?.poilabsPositioning(didFail: .beaconNotFound)
                delegate?.poilabsPositioning(didStatusChange: .locationNotFound, reason: .beaconNotFound)
            }
            return
        }
        self.locationNotFoundCounter = 0
        PoilabsPositioningUtils.logDebugInformations(log: "poilabsPositioning(didUpdateLocation) \(Date()) ", priority: 10)
    }
}


extension PLPositioning: PLPBeaconPositionFinderDelegate {
    func beaconPositionFinder(possibleLocations: [PLPLocation]) {
//        if let lastPdrLocation = lastPdrLocation {
//            var minDistance: Double = .greatestFiniteMagnitude
//            var decidedLocation: PLPLocation?
//            possibleLocations.forEach { location in
//                let distance = location.getDistanceTo(location: PLPLocation(latitude: lastPdrLocation.latitude, longitude: lastPdrLocation.longitude))
//                if (distance*conversionFactor < 5) && distance < minDistance {
//                    minDistance = distance
//                    decidedLocation = location
//                }
//            }
//            let area = PLPIndoorPositioning.shared.findRadiusOfPolygon(coordinates: possibleLocations)
//            if let decidedLocation = decidedLocation {
//                let distance = decidedLocation.getLocation().distance(to: lastPdrLocation)
//                PoilabsPositioningUtils.writeToFile(logString: "distance: \(distance), counter: \(self.multiCrosscheckCounter)\n", filename: "croscheck.txt")
//                if let lastMultiLocation = self.lastMultiLocation {
//                    if lastMultiLocation.distance(to: decidedLocation.getLocation()) >= 5 {
//                        delegate?.poilabsPositioning(didUpdateLocation: decidedLocation.getLocation(), method: "multi", area: area)
//                        pdrManager.startPDR(startCoordinate: decidedLocation.getLocation())
//                    }
//                } else {
//                    delegate?.poilabsPositioning(didUpdateLocation: decidedLocation.getLocation(), method: "multi", area: area)
//                    pdrManager.startPDR(startCoordinate: decidedLocation.getLocation())
//                }
//
//                self.lastMultiLocation = decidedLocation.getLocation()
//                self.multiCrosscheckCounter = 0
//            } else {
//                self.multiCrosscheckCounter += 1
//                PoilabsPositioningUtils.writeToFile(logString: "decided location nil, counter: \(self.multiCrosscheckCounter)\n", filename: "croscheck.txt")
//            }
//
//            if self.multiCrosscheckCounter >= 3 {
//                if let center = PLPIndoorPositioning.shared.findCenterOfPolygon(coordinates: possibleLocations) {
//                    delegate?.poilabsPositioning(didUpdateLocation: center, method: "center of \(possibleLocations.count)", area: area)
//                    pdrManager.startPDR(startCoordinate: center)
//                    self.multiCrosscheckCounter = 0
//                }
//            }
//        }
    }
    
    func beaconPositionFinder(didFindLocation location: PLPLocation, method: String, area: Double) {
        let locationCoordinates = location.getLocation()
        self.accuracy = area
        delegate?.poilabsPositioning(didUpdateLocation: locationCoordinates, method: method, area: area)
        pdrManager.startPDR(startCoordinate: locationCoordinates)
//        if let lastPdrLocation = lastPdrLocation {
//            let distance = locationCoordinates.distance(to: lastPdrLocation)*conversionFactor
//            PoilabsPositioningUtils.writeToFile(logString: "distance: \(distance), counter: \(self.multiCrosscheckCounter)\n", filename: "croscheck.txt")
//            if (distance < 5) || (self.multiCrosscheckCounter >= 3) {
//                lastMultiLocation = locationCoordinates
//                delegate?.poilabsPositioning(didUpdateLocation: locationCoordinates, method: "\(distance) \(self.multiCrosscheckCounter)", area: 1.0)
//                pdrManager.startPDR(startCoordinate: locationCoordinates)
//                self.multiCrosscheckCounter = 0
//            } else {
//                self.multiCrosscheckCounter += 1
//            }
//        } else {
//            lastMultiLocation = locationCoordinates
//            delegate?.poilabsPositioning(didUpdateLocation: locationCoordinates, method: method, area: 1.0)
//            pdrManager.startPDR(startCoordinate: locationCoordinates)
//        }
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
            lastCalculatedLocation = nil
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
        delegate?.poilabsPositioning(didUpdateLocation: location, method: "pdr", area: self.accuracy)
        self.lastPdrLocation = location
        PLPIndoorPositioning.shared.setLastPdrLocation(coordinates: location)
    }
}
