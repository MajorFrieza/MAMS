import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:geocoding/geocoding.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  /// Get singleton instance
  static LocationService get instance => _instance;

  /// Get current location as a formatted string (without requesting permission)
  Future<String?> getCurrentLocationString() async {
    try {
      // Check permission status without requesting
      final status = await Geolocator.checkPermission();

      if (status == LocationPermission.denied ||
          status == LocationPermission.deniedForever) {
        return 'Location permission not granted';
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return 'Location service disabled';
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        return 'Unable to get location';
      }

      // Format: "Latitude, Longitude"
      return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    } catch (e) {
      return 'Error: Unable to access location';
    }
  }

  /// Reverse-geocode a Position into a readable address
  Future<String?> getAddressFromPosition(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      // Build a human readable address (locality, subLocality, thoroughfare, country)
      final parts = <String>[];
      if (p.name != null && p.name!.isNotEmpty) parts.add(p.name!);
      if (p.subLocality != null && p.subLocality!.isNotEmpty) {
        parts.add(p.subLocality!);
      }
      if (p.locality != null && p.locality!.isNotEmpty) parts.add(p.locality!);
      if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) {
        parts.add(p.administrativeArea!);
      }
      if (p.country != null && p.country!.isNotEmpty) parts.add(p.country!);
      return parts.join(', ');
    } catch (e) {
      return null;
    }
  }

  /// Get a human-readable address for the current location (requests permission if needed)
  Future<String?> getCurrentAddressString() async {
    final pos = await getCurrentPosition();
    if (pos == null) return null;
    final addr = await getAddressFromPosition(pos);
    if (addr != null && addr.isNotEmpty) return addr;
    return '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
  }

  /// Request location permission explicitly (using permission_handler to avoid geolocator manifest check)
  Future<bool> requestLocationPermission() async {
    final status = await ph.Permission.location.request();
    return status.isGranted;
  }

  /// Get current position with detailed information
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        position = await Geolocator.getLastKnownPosition();
      }

      return position;
    } catch (e) {
      return null;
    }
  }

  /// Check if location service is enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Open device location settings
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      return false;
    }
  }
}
