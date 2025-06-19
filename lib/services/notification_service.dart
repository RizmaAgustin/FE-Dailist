import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Global navigator key untuk menampilkan dialog dari mana saja
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Inisialisasi notifikasi dan minta permission
  static Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          _showNotificationDialog(response.payload!);
        }
      },
    );
    await requestPermission();
    print('DEBUG: NotificationService initialized!');
  }

  /// Permission notifikasi Android 13+ dan iOS
  static Future<void> requestPermission() async {
    // Android 13+ (API 33+)
    final androidImplementation =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidImplementation?.requestNotificationsPermission();

    // iOS
    final iosImplementation =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
    await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    print('DEBUG: Notification permission requested');
  }

  // Tampilkan dialog jika notifikasi diklik saat app foreground
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

  /// Jadwalkan hanya notifikasi tepat saat deadline (tanpa 5 menit sebelumnya)
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
  }) async {
    print(
      'DEBUG: MASUK scheduleNotification dengan id: $id, title: $title, waktu: $scheduledDateTime',
    );
    try {
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
        scheduledDateTime,
        tz.local,
      );
      print('Menjadwalkan notifikasi deadline pada: $scheduledDate');

      // Notifikasi utama (tepat saat deadline)
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
      print('Error scheduling notification: $e\n$s');
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
    print('DEBUG: Notifikasi dengan id $id dibatalkan');
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    print('DEBUG: Semua notifikasi dibatalkan');
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
          showWhen: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: '$title\n$body',
    );
    print('DEBUG: showInstantNotification tampil dengan id: $id');
  }

  static Future<bool> areNotificationsEnabled() async {
    // Untuk Android/iOS bisa tambahkan pengecekan lebih lanjut jika ingin
    return true;
  }
}
