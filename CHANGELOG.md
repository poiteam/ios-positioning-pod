# Changelog

All notable changes to this project will be documented in this file.

## [1.2.2] - 2026-11-11

### Added
- `PLPositioningMode` is public (`INDOOR` / `OUTDOOR` / `EDGE`).
- `PLPositioningModeInfo` exposes `mode`, `score`, `beaconCount`, `insideCounter`, `outsideCounter` and `edgeThreshold`.
- Optional delegate method `poilabsPositioning(didChangeMode:)`, called when hybrid positioning switches mode. Existing delegates compile unchanged.

### Fixed
- `stopPoilabsPositioning()` and `closeAllActions()` now also stop the GPS updates and the mode timer started by `startHybridPositioning()`.

## [1.2.1] - 2026-11-11

### Changed
- Hybrid positioning: only beacons in the venue's beacon list are counted for the indoor/edge/outdoor decision. Beacons removed from the list (e.g. deactivated in the panel) no longer make an outdoor user appear indoors. While the beacon list is empty (venue discovery), all filtered beacons are counted as before.

## [1.0.20] - 2024-03-06

### Added
- Swift Package Manager (SPM) support
- Support for iOS 12.0 and above

## [1.0.19] and earlier

- Previous version history 