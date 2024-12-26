import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/map_launcher.dart';
import 'dart:convert';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  static const LatLng _defaultLocation =
      LatLng(-37.24909666554568, 144.45323073712373);
  bool _isLoading = true;
  Map<String, Map<String, dynamic>> _locationData = {};

  // Define map style as JSON string
  static final String _mapStyle = jsonEncode([
    {
      "featureType": "poi",
      "stylers": [
        {"visibility": "off"}
      ]
    },
    {
      "featureType": "transit",
      "stylers": [
        {"visibility": "off"}
      ]
    },
    {
      "featureType": "road",
      "elementType": "labels.icon",
      "stylers": [
        {"visibility": "off"}
      ]
    },
    {
      "featureType": "road",
      "elementType": "labels.text",
      "stylers": [
        {"visibility": "on"}
      ]
    }
  ]);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _requestLocationPermission();
    await _loadLocations();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      debugPrint('Location permission not granted');
      return;
    }
    debugPrint('Location permission granted');
  }

  Future<void> _findNearestLocation() async {
    try {
      setState(() => _isLoading = true);

      // Get current location with proper settings
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;

      if (_locationData.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No locations available')),
          );
        }
        return;
      }

      // Find nearest location
      double? shortestDistance;
      Map<String, dynamic>? nearestLocation;

      _locationData.forEach((id, locationData) {
        final GeoPoint locationPosition = locationData['position'] as GeoPoint;
        final double distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          locationPosition.latitude,
          locationPosition.longitude,
        );

        if (shortestDistance == null || distance < shortestDistance!) {
          shortestDistance = distance;
          nearestLocation = locationData;
        }
      });

      if (nearestLocation != null && mounted) {
        final GeoPoint nearestPoint = nearestLocation!['position'] as GeoPoint;
        final LatLng latLng =
            LatLng(nearestPoint.latitude, nearestPoint.longitude);

        // Animate camera to the nearest location without changing zoom
        await _mapController?.animateCamera(
          CameraUpdate.newLatLng(latLng),
        );

        // Show location details
        if (mounted) {
          _showLocationDetails(nearestLocation!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finding nearest location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadLocations() async {
    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }

      final locations = await FirebaseFirestore.instance
          .collection('events')
          .doc('businessKyneton')
          .collection('locations')
          .get();

      final Set<Marker> newMarkers = {};
      final Map<String, Map<String, dynamic>> newLocationData = {};

      for (var doc in locations.docs) {
        final data = doc.data();
        final geoPoint = data['position'] as GeoPoint;
        final position = LatLng(geoPoint.latitude, geoPoint.longitude);

        // Store location data
        newLocationData[doc.id] = data;

        final marker = Marker(
          markerId: MarkerId(doc.id),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          onTap: () {
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(position),
            );
            _showLocationDetails(data);
          },
        );
        newMarkers.add(marker);
      }

      if (mounted) {
        setState(() {
          _markers.addAll(newMarkers);
          _locationData = newLocationData;
        });
      }

      if (newMarkers.isNotEmpty && _mapController != null) {
        await _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(
            _getBounds(newMarkers),
            50.0,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading locations: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showLocationDetails(Map<String, dynamic> locationData) {
    final String title = locationData['title'] as String;
    final String address = locationData['address'] as String;
    final GeoPoint position = locationData['position'] as GeoPoint;

    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('${locationData['points']} points'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(24),
                  child: ElevatedButton.icon(
                    onPressed: () => MapLauncher.openDirections(
                      title: title,
                      address: address,
                      position: position,
                      context: bottomSheetContext,
                    ),
                    icon: const Icon(Icons.directions),
                    label: const Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(24),
                  child: ElevatedButton.icon(
                    onPressed: () => MapLauncher.openLocation(
                      title: title,
                      address: address,
                      position: position,
                      context: bottomSheetContext,
                    ),
                    icon: const Icon(Icons.info),
                    label: const Text('More Info'),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  LatLngBounds _getBounds(Set<Marker> markers) {
    double? minLat, maxLat, minLng, maxLng;

    for (final marker in markers) {
      if (minLat == null || marker.position.latitude < minLat) {
        minLat = marker.position.latitude;
      }
      if (maxLat == null || marker.position.latitude > maxLat) {
        maxLat = marker.position.latitude;
      }
      if (minLng == null || marker.position.longitude < minLng) {
        minLng = marker.position.longitude;
      }
      if (maxLng == null || marker.position.longitude > maxLng) {
        maxLng = marker.position.longitude;
      }
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: _defaultLocation,
            zoom: 15,
          ),
          markers: _markers,
          myLocationButtonEnabled: true,
          myLocationEnabled: true,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          style: _mapStyle,
        ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
        // Find Nearest Button
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: Center(
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(24),
              child: ElevatedButton.icon(
                onPressed: _findNearestLocation,
                icon: const Icon(Icons.near_me),
                label: const Text('Find Nearest'),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
