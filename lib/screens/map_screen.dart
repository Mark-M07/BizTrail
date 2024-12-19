import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
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
          onTap: () {
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(
                  LatLng(geoPoint.latitude, geoPoint.longitude)),
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
                  onPressed: () => _openDirections(address),
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openMapsApp(title, position),
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

  Future<void> _openDirections(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    Uri? url;
    bool launched = false;

    if (Platform.isIOS) {
      // Try Google Maps first for better information
      url = Uri.parse(
          'comgooglemaps://?daddr=$encodedAddress&directionsmode=driving');
      try {
        launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        launched = false;
      }

      if (!launched) {
        // Fallback to Apple Maps if Google Maps isn't installed
        url = Uri.parse('maps://?daddr=$encodedAddress');
        try {
          launched = await launchUrl(url, mode: LaunchMode.externalApplication);
        } catch (e) {
          launched = false;
        }
      }
    } else {
      // Android navigation
      url = Uri.parse('google.navigation:q=$encodedAddress&mode=d');
      try {
        launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        launched = false;
      }

      if (!launched) {
        url = Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$encodedAddress');
      }
    }

    if (!mounted) return;
    _showMessage('Opening maps application...');

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (!mounted) return;
        _showMessage('Could not open maps application', isError: true);
      }
    } catch (e) {
      debugPrint('Error launching maps: $e');
      if (!mounted) return;
      _showMessage('Could not open maps application', isError: true);
    }
  }

  Future<void> _openMapsApp(String title, GeoPoint position) async {
    final String encodedTitle = Uri.encodeComponent(title);
    Uri? url;
    bool launched = false;

    if (Platform.isIOS) {
      // Try Google Maps first for better information
      url = Uri.parse(
          'comgooglemaps://?q=${position.latitude},${position.longitude}($encodedTitle)');
      try {
        launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        launched = false;
      }

      if (!launched) {
        // Fallback to Apple Maps
        url = Uri.parse(
            'maps://?ll=${position.latitude},${position.longitude}&q=$encodedTitle');
        try {
          launched = await launchUrl(url, mode: LaunchMode.externalApplication);
        } catch (e) {
          launched = false;
        }
      }
    } else {
      url = Uri.parse(
          'geo:${position.latitude},${position.longitude}?q=$encodedTitle');
      try {
        launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        launched = false;
      }

      if (!launched) {
        url = Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}');
      }
    }

    if (!mounted) return;
    _showMessage('Opening maps application...');

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (!mounted) return;
        _showMessage('Could not open maps application', isError: true);
      }
    } catch (e) {
      debugPrint('Error launching maps: $e');
      if (!mounted) return;
      _showMessage('Could not open maps application', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    // Using the State's context to ensure correctness
    if (!mounted) return; // Check before using context
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        duration:
            isError ? const Duration(seconds: 3) : const Duration(seconds: 1),
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
          zoomControlsEnabled: false, // Hide for both platforms
          mapToolbarEnabled: false, // Hide for both platforms
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
