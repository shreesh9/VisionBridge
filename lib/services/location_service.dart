/// Emergency Location Service by Shreesh Nalawade | Ref: SN09092005
///
/// VisionBridge — Location Service
///
/// Wraps geolocator for SOS location sharing.
/// Always checks permission first — never silently fails.
library;

import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Get current position with high accuracy.
  /// Returns null if permission denied — caller must handle.
  Future<Position?> getCurrentPosition() async {
    final permission = await _ensurePermission();
    if (!permission) return null;

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  /// Stream position updates for live location sharing during SOS.
  Stream<Position>? getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  /// Ensure location permissions are granted.
  Future<bool> _ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Check if location is available without requesting.
  Future<bool> isLocationAvailable() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }
}
