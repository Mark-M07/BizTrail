import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform;

class MapLauncher {
  static Future<void> openLocation({
    required String title,
    required String address,
    required GeoPoint position,
    required BuildContext context,
  }) async {
    if (Platform.isIOS) {
      // Try Google Maps first
      final googleMapsUrl =
          Uri.parse('comgooglemaps://?q=${Uri.encodeComponent(title)}'
              '&center=${position.latitude},${position.longitude}'
              '&zoom=15'
              '&views=satellite,traffic'
              '&search=${Uri.encodeComponent(title)}');

      bool launched = false;
      try {
        launched = await launchUrl(
          googleMapsUrl,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('Error launching Google Maps: $e');
      }

      // If Google Maps fails, try Apple Maps
      if (!launched) {
        final appleMapsUrl =
            Uri.parse('maps://maps.apple.com/?q=${Uri.encodeComponent(title)}'
                '&ll=${position.latitude},${position.longitude}'
                '&z=15');

        try {
          launched = await launchUrl(
            appleMapsUrl,
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          debugPrint('Error launching Apple Maps: $e');
        }
      }

      // If both native apps fail, open in browser
      if (!launched) {
        final webUrl = Uri.parse('https://www.google.com/maps/search/?api=1'
            '&query=${Uri.encodeComponent(title)}'
            '&query_place_id=${Uri.encodeComponent(address)}');

        try {
          launched = await launchUrl(
            webUrl,
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          debugPrint('Error launching web maps: $e');
        }
      }

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open maps application'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Android handling
      final androidUrl =
          Uri.parse('geo:${position.latitude},${position.longitude}'
              '?q=${Uri.encodeComponent(title)}');

      bool launched = false;
      try {
        launched = await launchUrl(
          androidUrl,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('Error launching Android maps: $e');
      }

      // Fallback to web if native app fails
      if (!launched) {
        final webUrl = Uri.parse('https://www.google.com/maps/search/?api=1'
            '&query=${Uri.encodeComponent(title)}');

        try {
          launched = await launchUrl(
            webUrl,
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          debugPrint('Error launching web maps: $e');
        }
      }

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open maps application'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<void> openDirections({
    required String title,
    required String address,
    required GeoPoint position,
    required BuildContext context,
  }) async {
    if (Platform.isIOS) {
      // Try Google Maps first
      final googleMapsUrl = Uri.parse(
          'comgooglemaps://?daddr=${position.latitude},${position.longitude}'
          '&dname=${Uri.encodeComponent(title)}'
          '&directionsmode=driving');

      bool launched = false;
      try {
        launched = await launchUrl(
          googleMapsUrl,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('Error launching Google Maps: $e');
      }

      // If Google Maps fails, try Apple Maps
      if (!launched) {
        final appleMapsUrl =
            Uri.parse('maps://?daddr=${Uri.encodeComponent(address)}'
                '&dirflg=d');

        try {
          launched = await launchUrl(
            appleMapsUrl,
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          debugPrint('Error launching Apple Maps: $e');
        }
      }

      // If both native apps fail, open in browser
      if (!launched) {
        final webUrl = Uri.parse('https://www.google.com/maps/dir/?api=1'
            '&destination=${Uri.encodeComponent(address)}'
            '&travelmode=driving');

        try {
          launched = await launchUrl(
            webUrl,
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          debugPrint('Error launching web maps: $e');
        }
      }

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open maps application'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Android handling
      final androidUrl = Uri.parse(
          'google.navigation:q=${position.latitude},${position.longitude}'
          '&mode=d');

      bool launched = false;
      try {
        launched = await launchUrl(
          androidUrl,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('Error launching Android navigation: $e');
      }

      // Fallback to web if native app fails
      if (!launched) {
        final webUrl = Uri.parse('https://www.google.com/maps/dir/?api=1'
            '&destination=${Uri.encodeComponent(address)}'
            '&travelmode=driving');

        try {
          launched = await launchUrl(
            webUrl,
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          debugPrint('Error launching web maps: $e');
        }
      }

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open maps application'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
