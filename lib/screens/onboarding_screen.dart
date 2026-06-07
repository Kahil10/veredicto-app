import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('onboarding_done') ?? false);
  }

  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      emoji: '⚡',
      title: 'Bienvenido a\nVeredicto',
      subtitle: 'Pronósticos deportivos\ncon motor de inteligencia artificial',
      accent: kAccent,
      tag: 'MOTOR IA · COPA DEL MUNDO · MLB',
      bg1: Color(0xFF0f1318),
      bg2: Color(0xFF111a10),
    ),
    _Slide(
      emoji: '⚽',
      title: 'Copa del Mundo\n2026',
      subtitle: '72 partidos · Rankings FIFA\nPredicciones en tiempo real',
      accent: Color(0xFF4ade80),
      tag: '11 JUN – 19 JUL · USA · CAN · MEX',
      bg1: Color(0xFF0a1a0f),
      bg2: Color(0xFF0f1318),
    ),
    _Slide(
      emoji: '⚾',
      title: 'Béisbol\nen vivo',
      subtitle: 'Diamante en vivo · Alineaciones\nEstadísticas entrada por entrada',
      accent: Color(0xFF38bdf8),
      tag: 'MLB · 30 EQUIPOS · TEMPORADA 2026',
      bg1: Color(0xFF0a1220),
      bg2: Color(0xFF0f1318),
    ),
    _Slide(
      emoji: '🏆',
      title: 'Gratis para\nempezar',
      subtitle: '2 predicciones gratuitas por día\nPremium para análisis sin límites',
      accent: kGold,
      tag: 'FREEMIUM · PAGO MÓVIL · USDT',
      bg1: Color(0xFF1a1400),
      bg2: Color(0xFF0f1318),
    ),
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await OnboardingScreen.markDone();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo animado
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [slide.bg1, slide.bg2, const Color(0xFF0f1318)],
              ),
            ),
          ),

          // Círculo decorativo
          Positioned(
            top: -80,
            right: -60,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [slide.accent.withAlpha(30), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [slide.accent.withAlpha(15), Colors.transparent],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      onPressed: _finish,
                      child: Text('Saltar',
                          style: GoogleFonts.dmSans(
                              color: kMuted, fontSize: 14)),
                    ),
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: _slides.length,
                    itemBuilder: (_, i) => _SlidePage(slide: _slides[i]),
                  ),
                ),

                // Dots + botón
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    children: [
                      // Dots indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (i) {
                          final active = i == _page;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active ? slide.accent : kMuted.withAlpha(80),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 28),

                      // Botón principal
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: slide.accent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isLast ? 'Comenzar ahora' : 'Siguiente',
                            style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black),
                          ),
                        ),
                      ),

                      if (isLast) ...[
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: _finish,
                          child: Text(
                            'Ya tengo cuenta — Iniciar sesión',
                            style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: kMuted,
                                decoration: TextDecoration.underline,
                                decorationColor: kMuted),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlidePage extends StatelessWidget {
  final _Slide slide;
  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji grande con fondo
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: slide.accent.withAlpha(20),
              border: Border.all(color: slide.accent.withAlpha(50), width: 1.5),
            ),
            child: Center(
              child: Text(slide.emoji,
                  style: const TextStyle(fontSize: 56)),
            ),
          ),
          const SizedBox(height: 36),

          // Tag tipo chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: slide.accent.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: slide.accent.withAlpha(60)),
            ),
            child: Text(
              slide.tag,
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  color: slide.accent,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 20),

          // Título
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.bebasNeue(
                fontSize: 42,
                color: kText,
                letterSpacing: 1.5,
                height: 1.1),
          ),
          const SizedBox(height: 14),

          // Subtítulo
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
                fontSize: 16,
                color: kMuted,
                height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accent;
  final String tag;
  final Color bg1;
  final Color bg2;

  const _Slide({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.tag,
    required this.bg1,
    required this.bg2,
  });
}
