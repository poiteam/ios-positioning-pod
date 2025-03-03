//
//  PLPLocationCalculator.swift
//  PoilabsPositioning
//
//  Created by Emre Kuru on 11.12.2023.
//

import CoreLocation

class PLPLocationCalculator {
    
    init() {
        
    }
    
    static let shared = PLPLocationCalculator()
    
    private var previous_estimation: CLLocationCoordinate2D?
    private var kalmanFilter: KalmanFilter!
    private let numParticles = 100
    private let particalFilter = PLPParticalFilter()
    private var lastHeading = 0.0
    
    private var lastBestBeaconLocation: CLLocationCoordinate2D?
    
    private func simpleAverageMethod(coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        let sum = coordinates.reduce((latitude: 0.0, longitude: 0.0)) { (result, coordinate) in
            return (latitude: result.latitude + coordinate.latitude, longitude: result.longitude + coordinate.longitude)
        }
        
        let avgLat = sum.latitude / Double(coordinates.count)
        let avgLon = sum.longitude / Double(coordinates.count)
        
        return CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)
    }
    
    func shiftKalman(heading: Double, lenght: Double) {
        self.lastHeading = heading
        kalmanFilter.shiftMeasurements(heading: heading, lenght: lenght)
    }
    
    func feedKalman(location: CLLocationCoordinate2D) {
        previous_estimation = kalmanFilter.update(z_k: location)
    }
    
    private func incrementalLocation(prev_location: CLLocationCoordinate2D, heading: Double, stepLength: Double) -> CLLocationCoordinate2D {
        let lat1 = prev_location.latitude.deg2rad
        let lon1 = prev_location.longitude.deg2rad
        
        let R = PLPPDRConstants.earthR
        let d = stepLength
        let brng = heading.deg2rad
        
        let lat2 = asin(sin(lat1)*cos(d/R) + cos(lat1)*sin(d/R)*cos(brng))
        let lon2 = lon1 + atan2(sin(brng)*sin(d/R)*cos(lat1), cos(d/R)-sin(lat1)*sin(lat2))
        
        return CLLocationCoordinate2D(latitude: lat2.rad2deg, longitude: lon2.rad2deg)
    }
    
    private func multilateration(beacons: [PLPBeacon]) -> CLLocationCoordinate2D {
        let multi = PLPMultilateration(beacons: beacons)
        if let multiResult = multi.findLocation().0?.getLocation() {
            return multiResult
        } else {
            return simpleAverageMethod(coordinates: beacons.compactMap({$0.location?.getLocation()}))
        }
    }
    
    func getSimpleBeaconLocation(coordinates: [PLPBeacon]) -> CLLocationCoordinate2D {
        var estimated_position = multilateration(beacons: coordinates)
        let particles = tile(estimated_position, numParticles: numParticles)
        estimated_position = particalFilter.particleFilter(measurements: coordinates, initialParticles: particles)
        return estimated_position
    }
    
    
    /// Bir merkez koordinat ve açının görüş alanında verilen bir hedef koordinatın olup olmadığını kontrol eder.
    /// - Parameters:
    ///   - center: Merkez koordinat (latitude, longitude).
    ///   - angle: Kuzeyle yapılan açı (derece cinsinden, 0-360).
    ///   - target: Kontrol edilecek hedef koordinat.
    /// - Returns: Bool - Hedef koordinat görüş alanında mı?
//    func isTargetInFieldOfView(center: CLLocationCoordinate2D, angle: Double, target: CLLocationCoordinate2D) -> Bool {
//        // 1. İki koordinat arasındaki açıyı hesapla
//        func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
//            let fromLat = from.latitude.toRadians()
//            let fromLon = from.longitude.toRadians()
//            let toLat = to.latitude.toRadians()
//            let toLon = to.longitude.toRadians()
//            
//            let deltaLon = toLon - fromLon
//            let y = sin(deltaLon) * cos(toLat)
//            let x = cos(fromLat) * sin(toLat) - sin(fromLat) * cos(toLat) * cos(deltaLon)
//            let bearing = atan2(y, x).toDegrees()
//            return (bearing + 360).truncatingRemainder(dividingBy: 360) // Normalize to 0-360
//        }
//        
//        // 2. Görüş alanı sınırlarını hesapla
//        let minAngle = (angle - 30 + 360).truncatingRemainder(dividingBy: 360) // Minimum açı
//        let maxAngle = (angle + 30).truncatingRemainder(dividingBy: 360)       // Maksimum açı
//        
//        // 3. Hedef koordinatın merkeze göre açısını hesapla
//        let targetBearing = calculateBearing(from: center, to: target)
//        
//        // 4. Görüş alanı içinde mi kontrol et
//        if minAngle < maxAngle {
//            // Normal durum: Görüş alanı sınırları 0-360 arasında
//            return targetBearing >= minAngle && targetBearing <= maxAngle
//        } else {
//            // Yay sınırı 0-360 döngüsünü aşıyor
//            return targetBearing >= minAngle || targetBearing <= maxAngle
//        }
//    }
    
    func isTargetInFieldOfView(center: CLLocationCoordinate2D, angle: Double, target: CLLocationCoordinate2D) -> Bool {
        let target1 = incrementalLocation(prev_location: center, heading: angle-30, stepLength: 50)
        let target2 = incrementalLocation(prev_location: center, heading: angle+30, stepLength: 50)
        
        let polygon = Polygon([[center, target1, target2]])
        
        return polygon.contains(target)
    }
    
    
    func calculateLocation(coordinates: [PLPBeacon], reset: Bool? = false) -> CLLocationCoordinate2D {
        var estimated_position: CLLocationCoordinate2D!
        
        var beacons = coordinates
        if beacons.count > 15 {
            beacons.sort(by: {$0.rssi > $1.rssi})
            beacons.removeLast(beacons.count - 15)
        }
        
        if let previous_estimation = previous_estimation, reset == false {
            
            if let bestRssi = beacons.first(where: {$0.rssi > -67}), lastBestBeaconLocation != bestRssi.location?.getLocation(), isTargetInFieldOfView(center: previous_estimation, angle: self.lastHeading, target: bestRssi.location!.getLocation()) {
                lastBestBeaconLocation = bestRssi.location?.getLocation()
                estimated_position = bestRssi.location?.getLocation()
                kalmanFilter = nil
                kalmanFilter = KalmanFilter(initialLocation: estimated_position)
            } else {
                let particles = tile(previous_estimation, numParticles: numParticles)
                let particalLocation = particalFilter.particleFilter(measurements: beacons, initialParticles: particles)
                
                if !PLPGeoJSONMapManager.shared.isInWalkway(point: particalLocation) {
                    estimated_position = PLPGeoJSONMapManager.shared.nearestPointOnLine(point: particalLocation)
                } else {
                    estimated_position = particalLocation
                }
                estimated_position = kalmanFilter.update(z_k: estimated_position)
            }
            
        } else {
            estimated_position = getSimpleBeaconLocation(coordinates: beacons)
            kalmanFilter = KalmanFilter(initialLocation: estimated_position)
        }
        
        if !(estimated_position.latitude.isNaN && estimated_position.longitude.isNaN) {
            previous_estimation = estimated_position
        }
        
        return estimated_position
    }
    
    private func tile(_ coordinate: CLLocationCoordinate2D, numParticles: Int) -> [CLLocationCoordinate2D] {
        return Array(repeating: coordinate, count: numParticles)
    }
}
