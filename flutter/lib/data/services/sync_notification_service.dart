import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SyncNotificationService {
  SyncNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();
  final FlutterLocalNotificationsPlugin _plugin;
  static const String channelId = 'sync_status';
  static const String groupKey = 'ferreplus_sync';

  Future<void> initialize() async {
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
  }

  Future<void> showPending(int count) async {
    if (count <= 0) return;
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
  }

  Future<void> showAuthRequired() => _show('Sesion requerida para sincronizar');
  Future<void> showFailure() => _show('Error de sincronizacion: revisa la app');

  Future<void> _show(String title) => _plugin.show(
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

  Future<void> dispose() async {}
}
