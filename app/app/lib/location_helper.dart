import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// طلب الموقع مع التحقق من تشغيل GPS والأذونات (مناسب للمحاكي والأجهزة الحقيقية).
class LocationHelper {
  LocationHelper._();

  static Future<Position?> getCurrentPosition(BuildContext context) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'خدمة الموقع (GPS) متوقفة. فعّلها من إعدادات الجهاز ثم أعد المحاولة.',
              ),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'فتح الإعدادات',
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                },
              ),
            ),
          );
        }
        return null;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('يُرجى السماح بالوصول إلى الموقع لاستخدام هذه الميزة.'),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'إعدادات التطبيق',
                onPressed: () => ph.openAppSettings(),
              ),
            ),
          );
        }
        return null;
      }

      if (perm == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'تم رفض الموقع نهائياً. فعّل الإذن من إعدادات التطبيق → الأذونات.',
              ),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'الإعدادات',
                onPressed: () => ph.openAppSettings(),
              ),
            ),
          );
        }
        return null;
      }

      return await _resolvePosition();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'تعذر قراءة الموقع. في المحاكي: ⋮ → Location وحدد إحداثيات، أو فعّل GPS على الهاتف.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return null;
    }
  }

  /// محاولة [medium] ثم [low] ثم آخر موقع مخزّن (أحياناً يُنقذ المحاكي).
  static Future<Position?> _resolvePosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 0,
        ),
      );
    } catch (_) {
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            distanceFilter: 0,
          ),
        );
      } catch (_) {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) return last;
        rethrow;
      }
    }
  }
}
