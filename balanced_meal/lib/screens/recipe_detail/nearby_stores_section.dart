import 'dart:convert';
import 'package:balanced_meal/models/recipe_model.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class NearbyStoresSection extends StatefulWidget {
  final Recipe recipe;
  final Color accentColor;

  const NearbyStoresSection({
    required this.recipe,
    required this.accentColor,
  });

  @override
  State<NearbyStoresSection> createState() => _NearbyStoresSectionState();
}

class _NearbyStoresSectionState extends State<NearbyStoresSection> {
  bool _isLoadingStores = false;
  List<dynamic> _nearbyStores = [];
  Position? _currentPosition;
  double _selectedRadius = 1000;
  final List<double> _radiusOptions = [500, 1000, 2000, 3000, 4000, 5000];

  Future<void> _openStoreInMaps(String storeName, String address) async {
    final query = Uri.encodeComponent('$storeName $address');
    final googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$query';

    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl));
    } else {
      throw 'Could not launch $googleMapsUrl';
    }
  }

  Future<void> _getUserLocation() async {
    setState(() => _isLoadingStores = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Enable location services in device settings')),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions permanently denied')),
        );
      }
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      await _findNearbyStores();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingStores = false);
    }
  }

  Future<void> _findNearbyStores() async {
    debugPrint('Finding nearby stores for title: ${widget.recipe.title}');
    if (_currentPosition == null) return;

    try {
      final apiKey = "AIzaSyDXu_xLLUSKPcnJUxr4BtAjadr69WS8rIo";
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
          'location=${_currentPosition!.latitude},${_currentPosition!.longitude}'
          '&radius=$_selectedRadius'
          '&keyword=${widget.recipe.title}'
          '&key=$apiKey');

      final response = await http.get(url);
      final data = json.decode(response.body);
      if (data['status'] != 'OK') return;

      final stores = (data['results'] as List?)?.map((store) {
            final lat = store['geometry']['location']['lat']?.toDouble() ?? 0;
            final lng = store['geometry']['location']['lng']?.toDouble() ?? 0;
            final distance = _calculateDistance(lat, lng);

            return {
              'name': store['name']?.toString() ?? 'Unknown Store',
              'vicinity':
                  store['vicinity']?.toString() ?? 'Address not available',
              'geometry': store['geometry'] ??
                  {
                    'location': {'lat': lat, 'lng': lng}
                  },
              'distance': distance,
            };
          }).toList() ??
          [];

      stores.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));

      setState(() {
        _nearbyStores = stores;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finding stores: $e')),
        );
      }
    }
  }

  double _calculateDistance(double lat, double lng) {
    if (_currentPosition == null) return 0;
    return Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lng,
        ) /
        1000;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Find The Food Nearby',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: widget.accentColor,
          ),
        ),
        const SizedBox(height: 8),
        if (_currentPosition != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Search Radius:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              DropdownButton<double>(
                value: _selectedRadius,
                items: _radiusOptions.map((radius) {
                  return DropdownMenuItem<double>(
                    value: radius,
                    child: Text('${(radius / 1000).toStringAsFixed(1)} km'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRadius = value;
                      _findNearbyStores();
                    });
                  }
                },
              ),
            ],
          ),
        ],
        _isLoadingStores
            ? Center(
                child: CircularProgressIndicator(color: widget.accentColor))
            : _currentPosition == null
                ? ElevatedButton(
                    onPressed: _getUserLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Find Nearby Stores'),
                  )
                : _nearbyStores.isEmpty
                    ? Text(
                        'No nearby stores found for this recipe',
                        style: TextStyle(color: Colors.grey[600]),
                      )
                    : Column(
                        children: _nearbyStores
                            .map((store) => Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      _openStoreInMaps(store['name'],
                                          store['vicinity'] ?? '');
                                    },
                                    child: ListTile(
                                      leading: Icon(Icons.store,
                                          color: widget.accentColor),
                                      title: Text(store['name']),
                                      subtitle: Text(store['vicinity'] ?? ''),
                                      trailing: Text(
                                        '${(store['distance'] as double).toStringAsFixed(1)} km',
                                        style: TextStyle(
                                          color: widget.accentColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      )
      ],
    );
  }
}
