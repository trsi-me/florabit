import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'api_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'florabit_care',
    'تذكيرات العناية بالنباتات',
    description: 'تنبيهات الري والتسميد والإضاءة',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    if (_ready) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _plugin.initialize(initSettings);
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(_channel);
      await android?.requestNotificationsPermission();
    }
    _ready = true;
  }

  static Future<void> cancelAllCare() async {
    await _plugin.cancelAll();
  }

  static Future<void> syncCareReminders(int? userId) async {
    if (!_ready) await initialize();
    var enabled = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled = prefs.getBool(AppSettings.keyCareNotifications) ?? true;
    } catch (_) {
      // قد يفشل بعد Hot Restart أو قبل اكتمال القناة
    }
    if (!enabled) {
      await _plugin.cancelAll();
      return;
    }
    await _plugin.cancelAll();
    if (userId == null) return;
    try {
      final list = await ApiService.getUpcomingCare(userId);
      var id = 1;
      for (final item in list) {
        final name = item['name'] as String? ?? 'نبتة';
        final wid = item['watering_days_until'];
        final fid = item['fertilizing_days_until'];
        final wo = item['watering_overdue'] == true;
        final fo = item['fertilizing_overdue'] == true;
        if (wo == true) {
          await _plugin.show(
            id++,
            'فلورابيت — وقت الري',
            'يُنصح بري «$name» قريباً',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'florabit_care',
                'تذكيرات العناية بالنباتات',
                channelDescription: 'تنبيهات الري والتسميد والإضاءة',
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(),
            ),
          );
        }
        if (fo == true) {
          await _plugin.show(
            id++,
            'فلورابيت — التسميد',
            'تحقق من حاجة «$name» للتسميد',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'florabit_care',
                'تذكيرات العناية بالنباتات',
                channelDescription: 'تنبيهات الري والتسميد والإضاءة',
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(),
            ),
          );
        }
        if (wid is int && wid == 1 && wo != true) {
          final when = tz.TZDateTime.now(tz.local).add(const Duration(days: 1));
          await _plugin.zonedSchedule(
            id++,
            'فلورابيت — تذكير الري',
            'غداً موعد ري «$name»',
            when,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'florabit_care',
                'تذكيرات العناية بالنباتات',
                channelDescription: 'تنبيهات الري والتسميد والإضاءة',
                importance: Importance.defaultImportance,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
        if (fid is int && fid == 1 && fo != true) {
          final when = tz.TZDateTime.now(tz.local).add(const Duration(days: 1));
          await _plugin.zonedSchedule(
            id++,
            'فلورابيت — التسميد',
            'تذكير بتسميد «$name»',
            when,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'florabit_care',
                'تذكيرات العناية بالنباتات',
                channelDescription: 'تنبيهات الري والتسميد والإضاءة',
                importance: Importance.defaultImportance,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    } catch (_) {}
  }
}
