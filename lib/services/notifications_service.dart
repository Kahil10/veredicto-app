import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';

// Handler para mensajes en background (debe ser top-level)
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // Firebase ya lo muestra automáticamente en background
}

class NotificationsService {
  static final _messaging = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  static const _channelId   = 'veredicto_main';
  static const _channelName = 'Veredicto';

  // Token FCM local — disponible tras init()
  static String? _fcmToken;

  static Future<void> init() async {
    // Pedir permiso al usuario
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Canal Android (requerido para Android 8+)
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Partidos, resultados y análisis de Vera',
      importance: Importance.high,
      playSound: true,
    );
    final androidPlugin = _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidChannel);

    // Inicializar local notifications (para mostrar en primer plano)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onLocalTap,
    );

    // Handler background
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    // Handler primer plano — mostrar con local notifications
    FirebaseMessaging.onMessage.listen(_showForeground);

    // Obtener y guardar el token FCM localmente — el registro en backend
    // requiere auth y se hace desde AuthProvider después del login.
    _fcmToken = await _messaging.getToken();

    // Actualizar token local si Firebase lo renueva — el re-registro con
    // auth es responsabilidad de AuthProvider al detectar el cambio.
    _messaging.onTokenRefresh.listen((t) => _fcmToken = t);
  }

  // ── Registro autenticado del token en el backend ──────────────────────────
  // Llamar desde AuthProvider después de login/init cuando el JWT está disponible.

  static Future<void> registerWithAuth(String jwtToken) async {
    final token = _fcmToken ?? await _messaging.getToken();
    if (token == null) return;
    _fcmToken = token;
    try {
      await http.post(
        Uri.parse('$kBaseUrl/api/notifications/register-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({'token': token}),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      // Silencioso — no romper la app si el backend no responde
    }
  }

  // ── Mostrar notificación en primer plano ───────────────────────────────────

  static Future<void> _showForeground(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    await _local.show(
      message.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  static void _onLocalTap(NotificationResponse response) {
    // Aquí se puede navegar a la pantalla correcta según payload
  }

  // ── Desregistrar token al cerrar sesión ───────────────────────────────────

  static Future<void> unregisterToken(String jwtToken) async {
    final token = _fcmToken ?? await _messaging.getToken();
    if (token == null) return;
    try {
      await http.delete(
        Uri.parse('$kBaseUrl/api/notifications/unregister-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({'token': token}),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }
}
