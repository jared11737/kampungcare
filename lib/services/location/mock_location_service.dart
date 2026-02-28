import 'location_service_base.dart';

/// Mock location service that returns hardcoded Kuantan, Pahang coordinates.
/// Used for development and demo without requiring GPS permissions.
class MockLocationService implements LocationServiceBase {
  // Kuantan, Pahang, Malaysia coordinates
  static const double _kuantanLat = 3.8077;
  static const double _kuantanLng = 103.3260;

  @override
  Future<Map<String, double>?> getCurrentLocation() async {
    // Simulate GPS acquisition delay
    await Future.delayed(const Duration(milliseconds: 500));

    print('[Location] Returning Kuantan coordinates: $_kuantanLat, $_kuantanLng');

    return {
      'latitude': _kuantanLat,
      'longitude': _kuantanLng,
    };
  }
}
