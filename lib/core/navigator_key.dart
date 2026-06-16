import 'package:flutter/material.dart';

final navigatorKey = GlobalKey<NavigatorState>();

/// Pestaña solicitada para HomeScreen desde fuera (ej. al tocar una notificación).
/// HomeScreen la escucha y cambia de pestaña. null = sin solicitud.
final ValueNotifier<int?> requestedHomeTab = ValueNotifier<int?>(null);
