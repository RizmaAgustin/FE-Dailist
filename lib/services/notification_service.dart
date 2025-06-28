import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Inisialisasi timezone otomatis sesuai device
  static Future<void> configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    print('🕒 Timezone lokal: $timeZoneName');
  }

  static Future<void> initialize() async {
    await configureLocalTimeZone();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          _showNotificationDialog(response.payload!);
        }
      },
    );

    // Channel untuk reminder
    const AndroidNotificationChannel taskChannel = AndroidNotificationChannel(
      'task_channel_id',
      'Task Notifications',
      description: 'Pengingat tugas dan deadline',
      importance: Importance.max,
    );
    final androidImplementation =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidImplementation?.createNotificationChannel(taskChannel);

    await requestPermission();
    print('✅ NotificationService berhasil diinisialisasi');
  }

  static Future<void> requestPermission() async {
    final android =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await android?.requestNotificationsPermission();

    final ios =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    print('📢 Permission notifikasi diminta');
  }

  static Future<void> openExactAlarmSettings() async {
    if (Platform.isAndroid) {
      const intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
      print('⚙️ Membuka pengaturan Exact Alarm');
    }
  }

  static Future<void> requestExactAlarmPermissionWithDialog(
    BuildContext context,
  ) async {
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Izin Notifikasi Presisi'),
            content: const Text(
              'Untuk mengingatkan tugas tepat waktu, aplikasi perlu izin notifikasi presisi. Buka pengaturan sekarang?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Tidak'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Buka'),
              ),
            ],
          ),
    );
    if (shouldOpen == true) {
      await openExactAlarmSettings();
    }
  }

  static void _showNotificationDialog(String payload) {
    final context = navigatorKey.currentState?.overlay?.context;
    if (context != null) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Pengingat Tugas'),
              content: Text(payload),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    BuildContext? context,
  }) async {
    // JANGAN panggil requestExactAlarmPermissionWithDialog di sini!
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      scheduledDateTime,
      tz.local,
    );
    print('📆 Menjadwalkan notifikasi: $title pada $scheduledDate');
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_channel_id',
            'Task Notifications',
            channelDescription: 'Pengingat tugas dan deadline',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: '$title\n$body',
      );
    } catch (e, s) {
      print('❌ Gagal menjadwalkan notifikasi: $e\n$s');
    }
  }

  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_channel_id',
          'Instant Notifications',
          channelDescription: 'Notifikasi langsung tanpa jadwal',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: '$title\n$body',
    );
    print('🔔 Notifikasi langsung ditampilkan: $title');
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
    print('🗑️ Notifikasi dengan ID $id dibatalkan');
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    print('🧹 Semua notifikasi dibatalkan');
  }

  static Future<bool> areNotificationsEnabled() async {
    // Bisa tambahkan pengecekan lebih lanjut kalau perlu
    return true;
  }
}
