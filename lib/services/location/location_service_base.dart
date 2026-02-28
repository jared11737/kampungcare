/// Abstract interface for location service.
/// Provides GPS coordinates for SOS emergency features.
abstract class LocationServiceBase {
  /// Get the current device location.
  /// Returns a map with 'latitude' and 'longitude' keys,
  /// or null if location is unavailable.
  Future<Map<String, double>?> getCurrentLocation();
}
