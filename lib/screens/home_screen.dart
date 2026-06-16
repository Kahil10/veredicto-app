import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../core/navigator_key.dart';
import '../providers/auth_provider.dart';
import '../providers/matches_provider.dart';
import '../widgets/match_card.dart';
import 'chat_screen.dart';
import 'live_games_screen.dart';
import 'match_detail_screen.dart';
import 'profile_screen.dart';
import 'picks_screen.dart';
import 'guia_screen.dart';
import 'world_cup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      context.read<MatchesProvider>().loadMatches(token: token);
      // Si una notificación pidió abrir una pestaña (ej. Picks), aplicarlo.
      _aplicarPestanaSolicitada();
    });
    requestedHomeTab.addListener(_aplicarPestanaSolicitada);
  }

  void _aplicarPestanaSolicitada() {
    final t = requestedHomeTab.value;
    if (t != null && mounted) {
      setState(() => _tab = t);
      requestedHomeTab.value = null;
    }
  }

  @override
  void dispose() {
    requestedHomeTab.removeListener(_aplicarPestanaSolicitada);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          _MatchesTab(),
          LiveGamesScreen(),
          PicksScreen(),
          ChatScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) {
          // Al entrar a Picks (índice 2), mostrar la guía explicativa.
          // La gente la lee y puede dar "Saltar". Se abre cada vez que entran.
          if (i == 2 && _tab != 2) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const GuiaScreen(),
              fullscreenDialog: true,
            ));
          }
          setState(() => _tab = i);
        },
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.sports_baseball_outlined),
              activeIcon: Icon(Icons.sports_baseball),
              label: 'Partidos'),
          BottomNavigationBarItem(
              icon: _LiveTabIcon(active: _tab == 1),
              label: 'En Vivo'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.bolt_outlined),
              activeIcon: Icon(Icons.bolt),
              label: 'Picks'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              activeIcon: Icon(Icons.auto_awesome),
              label: 'Vera'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil'),
        ],
      ),
    );
  }
}

// ── Ícono del tab En Vivo con punto verde pulsante ────────────────────────────

class _LiveTabIcon extends StatefulWidget {
  final bool active;
  const _LiveTabIcon({required this.active});

  @override
  State<_LiveTabIcon> createState() => _LiveTabIconState();
}

class _LiveTabIconState extends State<_LiveTabIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          widget.active ? Icons.play_circle : Icons.play_circle_outline,
          color: widget.active ? kAccent : null,
        ),
        Positioned(
          top: -2,
          right: -4,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22c55e).withOpacity(_anim.value),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _MatchesTab extends StatelessWidget {
  const _MatchesTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MatchesProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt, color: kPurple, size: 22),
            SizedBox(width: 6),
            Text('Veredicto'),
          ],
        ),
        actions: [
          // Acceso elegante a la Copa del Mundo — solo durante el torneo
          if (_WorldCupBanner.shouldShow)
            IconButton(
              icon: const Text('⚽', style: TextStyle(fontSize: 20)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WorldCupScreen()),
              ),
              tooltip: 'Copa del Mundo 2026',
            ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () =>
                provider.loadMatches(token: auth.token, syncLive: true),
            tooltip: 'Actualizar scores en vivo',
          ),
        ],
      ),
      body: Column(
        children: [
          // Accuracy banner
          const _AccuracyBanner(),
          // Acceso a la Copa del Mundo — franja fija visible durante el torneo
          // (no scrollea con los partidos, no estorba el feed)
          if (_WorldCupBanner.shouldShow) const _WorldCupAccessBar(),
          // Sport selector + date picker
          _ControlBar(provider: provider, token: auth.token),
          // Match list
          Expanded(child: _MatchList(provider: provider, token: auth.token)),
        ],
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  final MatchesProvider provider;
  final String? token;
  const _ControlBar({required this.provider, this.token});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kSurface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Sport tabs — un tab por deporte (agrupa todas las ligas del mismo deporte)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SportTab(
                  label: '⚾ Béisbol',
                  active: provider.sport == 'baseball' || provider.sport == 'baseball_lvbp',
                  onTap: () => provider.setSport('baseball', token: token),
                ),
                const SizedBox(width: 6),
                _SportTab(
                  label: '⚽ Fútbol',
                  active: provider.sport == 'football' || provider.sport == 'football_ven',
                  onTap: () => provider.setSport('football', token: token),
                ),
                const SizedBox(width: 6),
                _SportTab(
                  label: '🏀 Baloncesto',
                  active: provider.sport == 'basketball',
                  onTap: () => provider.setSport('basketball', token: token),
                ),
                const SizedBox(width: 6),
                _SportTab(
                  label: '🏈 F. Americano',
                  active: provider.sport == 'american_football',
                  onTap: () =>
                      provider.setSport('american_football', token: token),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Date picker row
          _DateRow(provider: provider, token: token),
        ],
      ),
    );
  }
}

class _SportTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SportTab(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? kPurple : kCard,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(
              color: active ? Colors.white : kMuted,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            )),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final MatchesProvider provider;
  final String? token;
  const _DateRow({required this.provider, this.token});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dates = List.generate(
        16, (i) => today.subtract(Duration(days: 2)).add(Duration(days: i)));

    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = dates[i];
          final isSelected = DateFormat('yyyy-MM-dd').format(d) ==
              DateFormat('yyyy-MM-dd').format(provider.selectedDate);
          final isToday = DateFormat('yyyy-MM-dd').format(d) ==
              DateFormat('yyyy-MM-dd').format(today);
          return GestureDetector(
            onTap: () => provider.setDate(d, token: token),
            child: Container(
              width: 52,
              decoration: BoxDecoration(
                color: isSelected ? kPurple : kCard,
                borderRadius: BorderRadius.circular(10),
                border: isToday && !isSelected
                    ? Border.all(color: kPurple.withAlpha(120))
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(d).toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white70 : kMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    d.day.toString(),
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: isSelected ? Colors.white : kText),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Copa del Mundo — el acceso vive en el AppBar del tab Partidos (ver _MatchesTab)
// y solo se muestra durante la ventana del torneo.
// ─────────────────────────────────────────────────────────────────────────────

class _WorldCupBanner {
  const _WorldCupBanner._();

  /// True entre 4 días antes del inicio (7 jun) y el cierre del torneo (19 jul 2026).
  static bool get shouldShow {
    final now = DateTime.now();
    final bannerStart = DateTime(2026, 6, 7);
    final bannerEnd = DateTime(2026, 7, 19, 23, 59, 59);
    return !now.isBefore(bannerStart) && now.isBefore(bannerEnd);
  }
}

/// Franja compacta de acceso a la Copa del Mundo. Va fija debajo del selector,
/// no scrollea con los partidos. Toca → abre los grupos y resultados.
class _WorldCupAccessBar extends StatelessWidget {
  const _WorldCupAccessBar();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WorldCupScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0b3a20), Color(0xFF0a2e1a)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kGreen.withOpacity(0.45)),
          boxShadow: [
            BoxShadow(
              color: kGreen.withOpacity(0.18),
              blurRadius: 16,
              spreadRadius: -2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Insignia circular con balón
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kGreen.withOpacity(0.16),
                shape: BoxShape.circle,
                border: Border.all(color: kGreen.withOpacity(0.4)),
              ),
              child: const Text('⚽', style: TextStyle(fontSize: 19)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'COPA DEL MUNDO 2026',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 16,
                          color: kText,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 7),
                      // Punto vivo
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: kGreen.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'EN CURSO',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 8,
                            color: kGreen,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Grupos · Tabla de posiciones · Resultados',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: kGreen.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Pastilla "VER"
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: kGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'VER',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.black, size: 17),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Banner de estadísticas de acierto del motor Veredicto
// ─────────────────────────────────────────────────────────────────────────────

class _AccuracyBanner extends StatefulWidget {
  const _AccuracyBanner();

  @override
  State<_AccuracyBanner> createState() => _AccuracyBannerState();
}

class _AccuracyBannerState extends State<_AccuracyBanner> {
  Map<String, dynamic>? _data;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final resp = await http
          .get(Uri.parse('$kBaseUrl/api/stats/accuracy'))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200 && mounted) {
        setState(
            () => _data = jsonDecode(resp.body) as Map<String, dynamic>);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || _data == null) return const SizedBox.shrink();

    final globalPct = (_data!['accuracy_pct'] as num).toDouble();
    final week = _data!['this_week'] as Map<String, dynamic>?;
    final weekPct = week != null
        ? (week['accuracy_pct'] as num).toDouble()
        : null;
    final weekCorrect = week?['correct'] as int?;
    final weekTotal = week?['total'] as int?;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Motor Veredicto',
                    style: bebasNeue(13, color: kAccent, letterSpacing: 0.5)),
                Text(
                  '${globalPct.toStringAsFixed(1)}% acierto global',
                  style: dmSans(11, color: kMuted),
                ),
              ],
            ),
          ),
          if (weekPct != null && weekCorrect != null && weekTotal != null) ...[
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Esta semana',
                    style: dmSans(10, color: kMuted)),
                Text(
                  '${weekPct.toStringAsFixed(1)}% ($weekCorrect/$weekTotal) ✓',
                  style: dmSans(11,
                      color: kGreen, weight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyMatchesState extends StatelessWidget {
  final String sport;
  const _EmptyMatchesState({required this.sport});

  static const _info = <String, Map<String, dynamic>>{
    'american_football': {
      'emoji': '🏈',
      'titulo': 'Fútbol Americano',
      'estado': 'TEMPORADA PENDIENTE',
      'color': 0xFFFF6B35,
      'ligas': [
        ('NFL', 'Temporada regular inicia sep 2026'),
        ('NCAA Football', 'Temporada regular inicia ago 2026'),
        ('CFL', 'Temporada en curso — datos pronto'),
      ],
      'hint': 'Los mejores juegos de gridiron se vienen. ¡Regresa en agosto!',
    },
    'baseball': {
      'emoji': '⚾',
      'titulo': 'Béisbol',
      'estado': 'SIN PARTIDOS HOY',
      'color': 0xFF3A86FF,
      'ligas': [
        ('MLB + Ligas Menores', 'Temporada activa — prueba otra fecha'),
        ('LVBP Venezuela', 'Temporada de invierno: nov–ene'),
        ('LIDOM · LMP · LBPRC', 'Temporada de invierno: oct–feb'),
      ],
      'hint': 'Cambia la fecha para ver partidos de MLB, AAA, AA y más.',
    },
    'basketball': {
      'emoji': '🏀',
      'titulo': 'Baloncesto',
      'estado': 'SIN PARTIDOS HOY',
      'color': 0xFFFF9500,
      'ligas': [
        ('NBA', 'Finales en curso — prueba otra fecha'),
        ('WNBA', 'Temporada activa may–sep'),
        ('NCAA Basketball', 'Temporada regular: nov–abr'),
      ],
      'hint': 'Cambia la fecha para ver partidos disponibles.',
    },
    'football': {
      'emoji': '⚽',
      'titulo': 'Fútbol',
      'estado': 'SIN PARTIDOS HOY',
      'color': 0xFF06D6A0,
      'ligas': [
        ('Copa del Mundo 2026', 'Inicia 11 junio 2026 — USA/Canadá/México'),
        ('Champions · Premier · La Liga', 'Temporada activa'),
        ('Copa Libertadores · MLS', 'Temporada activa'),
      ],
      'hint': 'Cambia la fecha o revisa otras ligas disponibles.',
    },
    'football_ven': {
      'emoji': '🇻🇪',
      'titulo': 'Fútbol Venezolano',
      'estado': 'SIN PARTIDOS HOY',
      'color': 0xFFCF0A2C,
      'ligas': [
        ('Primera División', 'Temporada activa — prueba otra fecha'),
        ('Liga FUTVE', 'Partidos disponibles en temporada'),
      ],
      'hint': 'Cambia la fecha para ver partidos de la liga local.',
    },
  };

  @override
  Widget build(BuildContext context) {
    final data = _info[sport] ?? _info['football']!;
    final color = Color(data['color'] as int);
    final ligas = data['ligas'] as List<(String, String)>;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        children: [
          Text(data['emoji'] as String,
              style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text(
            data['titulo'] as String,
            style: GoogleFonts.barlow(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Text(
              data['estado'] as String,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
            child: Column(
              children: [
                for (int i = 0; i < ligas.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: Colors.white.withOpacity(0.06)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ligas[i].$1,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ligas[i].$2,
                                style: TextStyle(
                                  color: kMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 14, color: kMuted),
              const SizedBox(width: 6),
              Text(
                data['hint'] as String,
                style: TextStyle(color: kMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

String _sportEmoji(String sport) {
  switch (sport) {
    case 'baseball':
    case 'baseball_lvbp':
      return '⚾';
    case 'basketball':
      return '🏀';
    case 'american_football':
      return '🏈';
    default:
      return '⚽';
  }
}

class _MatchList extends StatelessWidget {
  final MatchesProvider provider;
  final String? token;
  const _MatchList({required this.provider, this.token});

  @override
  Widget build(BuildContext context) {
    if (provider.loading) {
      return const Center(
          child: CircularProgressIndicator(color: kPurple));
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_outlined, color: kMuted, size: 48),
              const SizedBox(height: 16),
              Text(provider.error!,
                  style: const TextStyle(color: kMuted),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => provider.loadMatches(token: token),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.matches.isEmpty) {
      return _EmptyMatchesState(sport: provider.sport);
    }

    return RefreshIndicator(
      color: kPurple,
      onRefresh: () => provider.loadMatches(token: token),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        itemCount: provider.matches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final match = provider.matches[i];
          return MatchCard(
            match: match,
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: provider,
                  child: MatchDetailScreen(match: match),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
