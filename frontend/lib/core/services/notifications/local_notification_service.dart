import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../models/maintenance_request_response_dto.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService _instance = LocalNotificationService._();

  factory LocalNotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initializationSettings);
    await _requestPermissions();
    _initialized = true;
  }

  Future<void> showOrderNotification(MaintenanceRequestResponseDto order) async {
    if (!_initialized) {
      await init();
    }

    final title = 'Новое оповещение';
    final buffer = StringBuffer('Заявка №${order.requestId}');
    if (order.clubName != null && order.clubName!.isNotEmpty) {
      buffer.write(' • ${order.clubName}');
    }
    if (order.status != null && order.status!.isNotEmpty) {
      buffer.write(' • ${order.status}');
    }

    const androidDetails = AndroidNotificationDetails(
      'order_alerts',
      'Оповещения о заявках',
      channelDescription: 'Уведомления о новых и обновленных заявках',
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      order.requestId ?? DateTime.now().millisecondsSinceEpoch,
      title,
      buffer.toString(),
      details,
    );
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }
}
