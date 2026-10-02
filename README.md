# PoilabsPositioning

Indoor positioning framework used by Poilabs iOS SDKs (PoilabsNavigation, PoilabsVdNavigation). It scans Poilabs beacons and reports the user's indoor location, floor and heading.

PoilabsPositioning is installed automatically as a dependency of PoilabsVdNavigation and PoilabsNavigation; you do not need to add it separately when you use those SDKs.

## Requirements

- iOS 12.0 or later
- Xcode 16 or later

## Installation

PoilabsPositioning is distributed with Swift Package Manager. CocoaPods is no longer supported; new versions are not published there.

### Swift Package Manager

1. In Xcode, select **File > Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/poiteam/ios-positioning-pod.git`
3. Choose **Exact Version** `1.2.0` and add the **PoilabsPositioning** product to your app target.

## Pre-requirements

Add the following keys to your `Info.plist`:

+Privacy - Location When In Use Usage Description

## Usage

```swift
import CoreLocation
import PoilabsPositioning

final class PositioningController: NSObject, PoilabsPositioningDelegate {

    private var positioning: PLPositioning?

    func start() {
        guard let filter = PLPBeaconFilter(uuid: "BEACON_UUID", majors: [], isEncrypted: true) else { return }
        let config = PLPConfig(scanInterval: 3,
                               locationUpdateInterval: 3,
                               beaconFilters: [filter],
                               rssiFilter: -80,
                               beaconList: [],
                               multilateration: true)
        positioning = PLPositioning(config: config)
        positioning?.delegate = self
        positioning?.startPoilabsPositioning()
    }

    func stop() {
        positioning?.stopPoilabsPositioning()
    }

    // MARK: - PoilabsPositioningDelegate

    func poilabsPositioning(didUpdateLocation location: CLLocationCoordinate2D, floorLevel: Int, accuracy: Double, placeId: String) {
        // indoor location update
    }

    func poilabsPositioning(didStatusChange status: PLPStatus, reason: PLPLocationStatusReason) {}
    func poilabsPositioning(didFindBeacon uuid: String, major: String, minor: String) {}
    func poilabsPositioning(didFail error: PoilabsPositioningError) {}
    func poilabsPositioning(didUpdateHeading heading: CLHeading) {}
    func poilabsPositioningDidStart() {}
    func poilabsPositioning(didThresholdChange threshold: Int) {}
    func poilabsPositioning(didUpdateLocation location: CLLocation, placeId: String) {}
    func poilabsPositioning(didUpdate modeInfo: PLPositioningModeInfo) {}
}
```

The beacon UUID, scan interval and RSSI filter are provided by Poilabs for your venue.
