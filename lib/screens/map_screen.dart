import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
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
    setState(() => _isLoading = false);
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      debugPrint('Location permission not granted');
      return;
    }
    debugPrint('Location permission granted');
  }

  Future<void> _loadLocations() async {
    try {
      setState(() => _isLoading = true);

      final locations = await FirebaseFirestore.instance
          .collection('events')
          .doc('businessKyneton')
          .collection('locations')
          .get();

      final Set<Marker> newMarkers = {};
      for (var doc in locations.docs) {
        final data = doc.data();
        final geoPoint = data['position'] as GeoPoint;
        final position = LatLng(geoPoint.latitude, geoPoint.longitude);

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

      setState(() {
        _markers.addAll(newMarkers);
      });

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
      setState(() => _isLoading = false);
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
                ElevatedButton.icon(
                  onPressed: () => MapLauncher.openDirections(
                    title: title,
                    address: address,
                    position: position,
                    context: bottomSheetContext,
                  ),
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions'),
                ),
                ElevatedButton.icon(
                  onPressed: () => MapLauncher.openLocation(
                    title: title,
                    address: address,
                    position: position,
                    context: bottomSheetContext,
                  ),
                  icon: const Icon(Icons.info),
                  label: const Text('More Info'),
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
      ],
    );
  }
}
