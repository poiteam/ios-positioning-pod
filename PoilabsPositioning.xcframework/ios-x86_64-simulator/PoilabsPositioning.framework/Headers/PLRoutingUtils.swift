//
//  PLRoutingUtils.swift
//  PoilabsPositioning
//
//  Created by Emre Kuru on 15.11.2022.
//

import Foundation
import CoreLocation


@objc
public class PLRoutingUtils: NSObject {
    
    @objc public static var shared = PLRoutingUtils()
    
    @objc public func getNearestPointOnRoute(location: CLLocationCoordinate2D, route: [CLLocation]) -> CLLocationCoordinate2D {
        let line = LineString(route.map({$0.coordinate}))
        let pointOnLine = line.closestCoordinate(to: location)
        return pointOnLine?.coordinate ?? CLLocationCoordinate2D()
    }
    
    @objc public func distanceToRoute(location: CLLocationCoordinate2D, route: [CLLocation]) -> Double {
        let line = LineString(route.map({$0.coordinate}))
        let pointOnLine = line.closestCoordinate(to: location)
        return pointOnLine?.coordinate.distance(to: location) ?? 0.0
    }
//    
//    @objc public func isUserBetweenTwoLocations(userLocation: CLLocation, firstLocation: CLLocation, secondLocation: CLLocation) -> Bool {
//        let line = LineString([firstLocation.coordinate, secondLocation.coordinate])
//        
//        return line.coordinates.contains(userLocation.coordinate)
//    }
}
