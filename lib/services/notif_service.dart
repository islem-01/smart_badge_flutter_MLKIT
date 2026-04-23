import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotifService {
  static final NotifService instance = NotifService._();
  NotifService._();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidInit,
    );

    await _plugin.initialize(initSettings);
  }

  Future<void> showScanSuccess(String name, String dept, String type) async {
    const androidDetails = AndroidNotificationDetails(
      'scan_channel',
      'Scan Notifications',
      channelDescription: 'Présence des employés',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    final isIn = type == 'checkIn';

    await _plugin.show(
      0,
      isIn ? '✅ Entrée enregistrée' : '👋 Sortie enregistrée',
      '$name — $dept',
      notificationDetails,
    );
  }
}