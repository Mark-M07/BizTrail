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
      // Android handling with fallback
      final androidUrl = Uri.parse('https://www.google.com/maps/search/?api=1'
          '&query=${Uri.encodeComponent(title)}'
          '&zoom=15');

      bool launched = false;
      try {
        launched = await launchUrl(
          androidUrl,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('Error launching Android maps: $e');
      }

      // If app fails, try web browser
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
    }
  }

  static Future<void> openDirections({
    required String title,
    required String address,
    required GeoPoint position,
    required BuildContext context,
  }) async {
    if (Platform.isIOS) {
      // Try Google Maps first with business name instead of coordinates
      final googleMapsUrl =
          Uri.parse('comgooglemaps://?daddr=${Uri.encodeComponent(title)}'
              '&destination_place_id=${Uri.encodeComponent(address)}'
              '&center=${position.latitude},${position.longitude}');

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
            Uri.parse('maps://?address=${Uri.encodeComponent(title)}'
                '&ll=${position.latitude},${position.longitude}'
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
            '&destination=${Uri.encodeComponent(title)}'
            '&destination_place_id=${Uri.encodeComponent(address)}'
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
      // Android handling with fallback
      final androidUrl = Uri.parse('https://www.google.com/maps/dir/?api=1'
          '&destination=${Uri.encodeComponent(title)}'
          '&travelmode=driving');

      bool launched = false;
      try {
        launched = await launchUrl(
          androidUrl,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('Error launching Android maps: $e');
      }

      // If app fails, try web browser with full URL
      if (!launched) {
        final webUrl = Uri.parse('https://www.google.com/maps/dir/?api=1'
            '&destination=${Uri.encodeComponent(title)}'
            '&destination_place_id=${Uri.encodeComponent(address)}'
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
