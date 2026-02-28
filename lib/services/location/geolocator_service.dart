import 'package:geolocator/geolocator.dart';
import 'location_service_base.dart';

class GeolocatorService implements LocationServiceBase {
  @override
  Future<Map<String, double>?> getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return null;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return {'latitude': pos.latitude, 'longitude': pos.longitude};
    } catch (e) {
      print('[Location] $e');
      return null;
    }
  }
}
