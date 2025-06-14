import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Global navigator key untuk menampilkan dialog dari mana saja
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Inisialisasi notifikasi
  static Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    // Setup initialization settings untuk Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // Initialize plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle ketika notifikasi di-tap
        if (response.payload != null) {
          _showNotificationDialog(response.payload!);
        }
      },
    );
  }

  // Menampilkan dialog dari payload notifikasi
  static void _showNotificationDialog(String payload) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder:
            (context) => AlertDialog(
              title: const Text('Pengingat Tugas'),
              content: Text(payload),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
        fullscreenDialog: true,
      ),
    );
  }

  // Menjadwalkan notifikasi utama dan notifikasi pengingat 1 menit sebelumnya
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
  }) async {
    try {
      // Konversi ke timezone lokal
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
        scheduledDateTime,
        tz.local,
      );

      // Setup detail notifikasi untuk Android
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'task_channel_id', // Channel ID
            'Task Notifications', // Channel name
            channelDescription: 'Pengingat tugas dan deadline',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          );

      // Detail notifikasi
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      // Jadwalkan notifikasi utama pada waktu deadline
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: body, // Payload untuk dialog
      );

      // Jadwalkan notifikasi pengingat 1 menit sebelum deadline
      final tz.TZDateTime reminderDate = scheduledDate.subtract(
        const Duration(minutes: 1),
      );

      await _notificationsPlugin.zonedSchedule(
        id + 1000, // ID berbeda untuk notifikasi pengingat
        'Pengingat: $title',
        'Deadline dalam 1 menit: $body',
        reminderDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminder_channel_id',
            'Task Reminder Notifications',
            channelDescription: 'Pengingat 1 menit sebelum deadline',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'Deadline dalam 1 menit: $body',
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  // Membatalkan notifikasi berdasarkan ID
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
    await _notificationsPlugin.cancel(
      id + 1000,
    ); // Batalkan juga notifikasi pengingat
  }

  // Membatalkan semua notifikasi
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // Menampilkan notifikasi langsung (tanpa jadwal)
  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'instant_channel_id',
          'Instant Notifications',
          channelDescription: 'Notifikasi langsung tanpa jadwal',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: body,
    );
  }

  // ---- Tambahan untuk setting screen ----
  /// Cek izin notifikasi (dummy, return true agar switch tidak error)
  static Future<bool> areNotificationsEnabled() async {
    // Untuk saat ini, switch selalu aktif.
    return true;
  }

  /// Minta izin notifikasi (untuk Android 13+, iOS, dll)
  static Future<void> requestPermission() async {
    // Untuk saat ini, biarkan kosong agar tidak error di UI.
    // Jika ingin support permission_handler, bisa isi di sini.
  }
}
