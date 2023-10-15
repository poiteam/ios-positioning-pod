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
    
    
    var floorChangeZones = [MultiPolygon]()
    var walkways = [MultiPolygon]()
    var zones = [MultiPolygon]()
    var linestrings = [LineString]()
    var linesDict = [Int:[LineString]]()
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
    
    private func getZone(for coordinate: CLLocationCoordinate2D) -> MultiPolygon? {
        for polygon in zones {
            if polygon.contains(coordinate) {
                return polygon
            }
        }
        return nil
    }
    
    private func getZoneId(for polygon: MultiPolygon) -> String? {
        guard case let .string(zoneId) = polygon.foreignMembers["zone_id"] else {
                return nil
            }
        return zoneId
    }
    
    private func getPassList(for polygon: MultiPolygon) -> [String] {
        guard case let .array(passList) = polygon.foreignMembers["pass_list"] else {
            return []
        }
        return (passList.rawValue as? [String]) ?? []
    }
    
    private func getPassList(for zoneId: String) -> [String] {
        guard let polygon = zones.first(where: { polygon in
            if case .string(let zoneIDValue) = polygon.foreignMembers["zone_id"], zoneIDValue == zoneId {
                return true
            }
            return false
        }) else {
            return []
        }
        return getPassList(for: polygon)
    }
    
    func canPassZone(oldCoordinate: CLLocationCoordinate2D, newCoordinate: CLLocationCoordinate2D) -> Bool {
        guard let oldZone = getZone(for: oldCoordinate), let oldZoneId = getZoneId(for: oldZone) else { return true }
        
        if oldZone.contains(newCoordinate) {
            //old coordinate and new coordinate are in the same zone
            return true
        }
        
        //new coordinate is in a different zone
        guard let newZone = getZone(for: newCoordinate), let newZoneId = getZoneId(for: newZone) else { return true }
        
        if oldZoneId == newZoneId {
            return true
        } else {
            return isZoneReachable(from: oldZoneId, to: newZoneId)
        }
    }
    
    func isZoneReachable(from startZone: String, to endZone: String) -> Bool {
        if startZone == endZone {
            return true
        }
        
        var visitedZones = [startZone]
        return traverseOverZoneList(visitedZones: &visitedZones, searchedZone: endZone)
    }

    func traverseOverZoneList(visitedZones: inout [String], searchedZone: String) -> Bool {
        if let currentZone = visitedZones.last {
            let values = getPassList(for: currentZone)
            if values.isEmpty {
                return false
            }
            if values.contains(searchedZone) {
                return true
            } else {
                for value in values {
                    if !visitedZones.contains(value) {
                        visitedZones.append(value)
                        if traverseOverZoneList(visitedZones: &visitedZones, searchedZone: searchedZone) {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
    
    func nearestPointOnLine(point: CLLocationCoordinate2D, heading: Double? = nil, floorLevel: Int? = nil) -> CLLocationCoordinate2D? {
        var minDistance: Double = .greatestFiniteMagnitude
        var nearestPoint: CLLocationCoordinate2D!
        var lines = linestrings
        if let floorLevel = floorLevel, let floorLines = linesDict[floorLevel] {
            lines = floorLines
        }
        
        lines.forEach { lineString in
            if let heading = heading, let degree = getLineDegree(line: lineString) {
                if !isSameDirection(wallLine: degree, heading: heading) {
                    return
                }
            }
            guard let nearestPointOnLine = lineString.closestCoordinate(to: point)?.coordinate else { return }
            let distance = nearestPointOnLine.distance(to: point)
            if distance > 5 {
                return
            }
            if distance < minDistance {
                minDistance = distance
                nearestPoint = nearestPointOnLine
            }
        }
        return nearestPoint
    }
    
    func isInFloorChangeZone(point: CLLocationCoordinate2D) -> Bool {
        if floorChangeZones.contains(where: {$0.contains(point)}) {
            return true
        }
        return false
    }
    
    @objc
    public func setWalkways(dict: NSDictionary?) {
        guard let dict = dict else {
            walkways = []
            return
        }
        guard let featureCollection = try? decodeGeoJSON(from: dict) else { return }
        
        featureCollection.features.forEach { feature in
            guard case var .multiPolygon(multiPolygon) = feature.geometry else {
                    return
                }
            multiPolygon.foreignMembers = feature.properties ?? [:]
            
            if multiPolygon.foreignMembers["category_poi"] == "Walkways" {
                walkways.append(multiPolygon)
            }
            if multiPolygon.foreignMembers["category_poi"] == "Units" {
                floorChangeZones.append(multiPolygon)
            }
            if multiPolygon.foreignMembers["category_poi"] == "Zones" {
                zones.append(multiPolygon)
            }
        }
        
        walkways.forEach { walkway in
            walkway.polygons.forEach({ polygon in
                polygon.coordinates.forEach { coordinates in
                    for i in 0..<coordinates.count {
                        let second = (i+1 < coordinates.count) ? i+1 : 0
                        var newLine = LineString([coordinates[i], coordinates[second]])
                        newLine.foreignMembers = walkway.foreignMembers
                        if case .string(let floorLevelId) = newLine.foreignMembers["level_id"], let floorLevel = Int(floorLevelId) {
                            linestrings.append(newLine)
                            if linesDict[floorLevel] == nil {
                                linesDict[floorLevel] = [newLine]
                            } else {
                                linesDict[floorLevel]?.append(newLine)
                            }
                        }
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
    
    private func getRotation(first : CLLocationCoordinate2D, second : CLLocationCoordinate2D) -> Double {
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
