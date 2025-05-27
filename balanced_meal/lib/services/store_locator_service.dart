// lib/services/store_locator_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class StoreLocatorService {
  Future<Position?> getUserLocation() async {
    final status = await Permission.location.request();
    if (!status.isGranted) return null;

    try {
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
    } catch (e) {
      throw Exception('Error getting location: $e');
    }
  }

  Future<List<dynamic>> findNearbyStores(
      Position position, String recipeTitle) async {
    try {
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? "apiKey";
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
          'location=${position.latitude},${position.longitude}'
          '&radius=5000'
          '&keyword=$recipeTitle'
          '&type=grocery_or_supermarket'
          '&key=$apiKey');

      final response = await http.get(url);
      final data = json.decode(response.body);

      return data['status'] == 'OK' ? data['results'] : [];
    } catch (e) {
      throw Exception('Error finding stores: $e');
    }
  }

  double calculateDistance(Position position, double lat, double lng) {
    return Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          lat,
          lng,
        ) /
        1000; // Convert to km
  }
}
