import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

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
  static const String _mapStyle = '''
[
  {
    "featureType": "poi",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "transit",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  }
]
''';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _requestLocationPermission();
    await _debugPrintFirestoreData();
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

  Future<void> _debugPrintFirestoreData() async {
    try {
      debugPrint('Fetching Firestore data...');
      final locations = await FirebaseFirestore.instance
          .collection('events')
          .doc('businessKyneton')
          .collection('locations')
          .get();

      debugPrint('Number of locations found: ${locations.docs.length}');
      for (var doc in locations.docs) {
        final data = doc.data();
        debugPrint('Location: ${data['title']}, Position: ${data['position']}');
      }
    } catch (e) {
      debugPrint('Error fetching Firestore data: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController?.setMapStyle(_mapStyle);
    _loadLocations();
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

        final marker = Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(geoPoint.latitude, geoPoint.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: data['title'] as String,
            snippet: '${data['points']} points',
          ),
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
    // Platform-specific map controls
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
          zoomControlsEnabled: Platform.isAndroid, // Hide on iOS
          mapToolbarEnabled: Platform.isAndroid, // Hide on iOS
          onMapCreated: _onMapCreated,
        ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
