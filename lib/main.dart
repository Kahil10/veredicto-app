import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/matches_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/notifications_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase y notificaciones push
  try {
    await Firebase.initializeApp();
    await NotificationsService.init();
  } catch (_) {
    // Si Firebase no está configurado aún, la app sigue funcionando
  }

  final auth = AuthProvider();
  await auth.init();
  final showOnboarding = !auth.isLoggedIn && await OnboardingScreen.shouldShow();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => MatchesProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: VeredictoApp(showOnboarding: showOnboarding),
    ),
  );
}

class VeredictoApp extends StatelessWidget {
  final bool showOnboarding;
  const VeredictoApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    return MaterialApp(
      title: 'Veredicto',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      initialRoute: isLoggedIn ? '/home' : (showOnboarding ? '/onboarding' : '/login'),
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}
