//
//  PLPGeoJSONMapManager.swift
//  PoilabsPositioning
//
//  Created by Emre Kuru on 10.10.2022.
//

import Foundation
import CoreLocation

@objc
public class PLPGeoJSONMapManager: NSObject {
    
    var walkways = [MultiPolygon]()
    var linestrings = [LineString]()
    var lastPdrLocation: CLLocationCoordinate2D?
    
    @objc public static var shared = PLPGeoJSONMapManager()
    
    
    func isInWalkway(point: CLLocationCoordinate2D) -> Bool {
        var result = false
        for polygon in walkways {
            result = polygon.contains(point)
            if result == true {
                break
            }
        }
        return result
    }
    
    func nearestPointOnLine(point: CLLocationCoordinate2D, heading: Double? = nil) -> CLLocationCoordinate2D? {
        var minDistance: Double = .greatestFiniteMagnitude
        var nearestPoint: CLLocationCoordinate2D!
        
        linestrings.forEach { lineString in
            if let degree = getLineDegree(line: lineString), let heading = heading, let nearestPointOnLine = lineString.closestCoordinate(to: point)?.coordinate {
                if isSameDirection(wallLine: degree, heading: heading) {
                     let distance = nearestPointOnLine.distance(to: point)
                     if distance < minDistance && distance < 5 {
                         minDistance = distance
                         nearestPoint = nearestPointOnLine
                     }
                }
            }
            if heading == nil {
                if let nearestPointOnLine = lineString.closestCoordinate(to: point)?.coordinate {
                    let distance = nearestPointOnLine.distance(to: point)
                    if distance < minDistance {
                        minDistance = distance
                        nearestPoint = nearestPointOnLine
                    }
                }
            }
        }
        return nearestPoint
    }
    
    @objc
    public func setWalkways(dict: NSDictionary?) {
        guard let dict = dict else {
            walkways = []
            return
        }
        guard let featureCollection = try? decodeGeoJSON(from: dict) else { return }
        
        featureCollection.features.forEach { feature in
                guard case let .multiPolygon(multiPolygon) = feature.geometry else {
                    return
                }
                walkways.append(multiPolygon)
        }
        
        walkways.forEach { walkway in
            walkway.polygons.forEach({ polygon in
                polygon.coordinates.forEach { coordinates in
                    for i in 0..<coordinates.count {
                        let second = (i+1 < coordinates.count) ? i+1 : 0
                        let newLine = LineString([coordinates[i], coordinates[second]])
                        linestrings.append(newLine)
                    }
                }
            })
        }
    }
    
    internal func decodeGeoJSON(from dict: NSDictionary) throws -> FeatureCollection? {
        var featureCollection: FeatureCollection?
        do {
            let data = try JSONSerialization.data(withJSONObject: dict)
            featureCollection = try JSONDecoder().decode(FeatureCollection.self, from: data)
        } catch {
            
        }
        return featureCollection
    }
    
    private func isSameDirection(wallLine: Double, heading: Double) -> Bool {
        let lineDegree = wallLine
        var dif = lineDegree - heading
         if dif < 0 {
             dif += 360
         } else if dif > 360 {
             dif -= 360
         }
         var rDif = lineDegree - 180 - heading
         if rDif < 0 {
             rDif += 360
         } else if rDif > 360 {
             rDif -= 360
         }
         if (dif < 30) || (dif > 330) || (rDif < 30) || (rDif > 330) {
             return true
         } else {
             return false
         }
    }
    
    private func getLineDegree(line: LineString) -> Double? {
        if let first = line.coordinates.first,
           let last = line.coordinates.last {
            return getRotation(first: first, second: last)
        }
        return nil
    }
    
    func getRotation(first : CLLocationCoordinate2D, second : CLLocationCoordinate2D) -> Double {
        let lat1 = first.latitude.deg2rad
        let lon1 = first.longitude.deg2rad

        let lat2 = second.latitude.deg2rad
        let lon2 = second.longitude.deg2rad

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)

        var degreeResult = radiansBearing.rad2deg
        
        if degreeResult < 0 {
            degreeResult += 360
        }
        if degreeResult > 360 {
            degreeResult -= 360
        }
        
        return degreeResult
    }

}
