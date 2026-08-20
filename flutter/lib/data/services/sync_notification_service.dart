import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SyncNotificationService {
  SyncNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();
  final FlutterLocalNotificationsPlugin _plugin;
  static const String channelId = 'sync_status';
  static const String groupKey = 'ferreplus_sync';
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      final AndroidFlutterLocalNotificationsPlugin? android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          'Sincronizacion',
          description: 'Estado de sincronizacion',
          importance: Importance.low,
        ),
      );
      await android?.requestNotificationsPermission();
      _initialized = true;
    } catch (_) {
      // Notification permission/plugin failures must never stop offline sync.
    }
  }

  Future<void> showPending(int count) async {
    if (count <= 0) return;
    try {
      await _plugin.show(
        1,
        'Operaciones pendientes de sincronizar',
        '$count operaciones pendientes',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'Sincronizacion',
            channelDescription: 'Estado de sincronizacion',
            importance: Importance.low,
            groupKey: groupKey,
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> showAuthRequired() => _show('Sesion requerida para sincronizar');
  Future<void> showFailure() => _show('Error de sincronizacion: revisa la app');

  Future<void> _show(String title) async {
    try {
      await _plugin.show(
        2,
        title,
        null,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'Sincronizacion',
            groupKey: groupKey,
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> dispose() async {}
}
