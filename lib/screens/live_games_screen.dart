import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../models/match_model.dart';
import '../providers/auth_provider.dart';
import 'live_match_screen.dart';

class LiveGamesScreen extends StatefulWidget {
  const LiveGamesScreen({super.key});

  @override
  State<LiveGamesScreen> createState() => _LiveGamesScreenState();
}

class _LiveGamesScreenState extends State<LiveGamesScreen>
    with WidgetsBindingObserver {
  List<MatchModel> _liveGames = [];
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetch();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _fetch());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _timer?.cancel();
      _timer = null;
    } else if (state == AppLifecycleState.resumed && _timer == null) {
      _fetch();
      _startTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final token = context.read<AuthProvider>().token;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final headers = token != null ? {'Authorization': 'Bearer $token'} : <String, String>{};

      // Todos los deportes en paralelo
      final results = await Future.wait([
        http.get(Uri.parse('$kBaseUrl/api/matches?sport=baseball&match_date=$today'), headers: headers)
            .timeout(const Duration(seconds: 10)),
        http.get(Uri.parse('$kBaseUrl/api/matches?sport=football&match_date=$today'), headers: headers)
            .timeout(const Duration(seconds: 10)),
        http.get(Uri.parse('$kBaseUrl/api/matches?sport=basketball&match_date=$today'), headers: headers)
            .timeout(const Duration(seconds: 10)),
        http.get(Uri.parse('$kBaseUrl/api/matches?sport=american_football&match_date=$today'), headers: headers)
            .timeout(const Duration(seconds: 10)),
      ]);

      final all = <MatchModel>[];
      for (final resp in results) {
        if (resp.statusCode == 200) {
          final list = jsonDecode(resp.body) as List;
          all.addAll(list.map((e) => MatchModel.fromJson(e)));
        }
      }

      if (mounted) {
        setState(() {
          _liveGames = all.where((m) => m.isLive).toList()
            ..sort((a, b) => a.kickoff.compareTo(b.kickoff));
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PulsingDot(),
            const SizedBox(width: 8),
            const Text('En Vivo'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              setState(() => _loading = true);
              _fetch();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAccent, strokeWidth: 2))
          : _liveGames.isEmpty
              ? _EmptyState()
              : RefreshIndicator(
                  color: kAccent,
                  onRefresh: _fetch,
                  child: _buildGroupedList(),
                ),
    );
  }

  /// Agrupa los juegos en vivo por deporte y construye una lista plana
  /// intercalando encabezados de sección con las tarjetas de cada deporte.
  /// Solo se muestra el header de un deporte si tiene al menos 1 juego en vivo.
  Widget _buildGroupedList() {
    // Orden y metadatos de cada deporte
    const order = ['baseball', 'football', 'basketball', 'american_football'];
    const meta = {
      'baseball': ('⚾', 'Béisbol'),
      'football': ('⚽', 'Fútbol'),
      'basketball': ('🏀', 'Baloncesto'),
      'american_football': ('🏈', 'F. Americano'),
    };

    String groupKey(MatchModel m) {
      if (m.sport == 'baseball_lvbp') return 'baseball';
      if (m.sport == 'football_ven') return 'football';
      return m.sport;
    }

    // Agrupar respetando el orden de llegada (ya vienen ordenados por kickoff)
    final grouped = <String, List<MatchModel>>{};
    for (final m in _liveGames) {
      grouped.putIfAbsent(groupKey(m), () => []).add(m);
    }

    // Construir lista plana de widgets: header + cards por cada grupo no vacío
    final items = <Widget>[];
    for (final key in order) {
      final games = grouped[key];
      if (games == null || games.isEmpty) continue;
      final info = meta[key]!;
      items.add(_SectionHeader(
        emoji: info.$1,
        label: info.$2,
        count: games.length,
      ));
      for (final game in games) {
        items.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _LiveGameCard(
            match: game,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LiveMatchScreen(match: game),
              ),
            ),
          ),
        ));
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: items,
    );
  }
}

// ── Encabezado de sección por deporte ────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String emoji;
  final String label;
  final int count;

  const _SectionHeader({
    required this.emoji,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            label,
            style: dmSans(14, weight: FontWeight.w700, color: kText),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF22c55e).withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF22c55e).withAlpha(50)),
            ),
            child: Text(
              count == 1 ? '1 en vivo' : '$count en vivo',
              style: dmSans(10, weight: FontWeight.w700, color: const Color(0xFF22c55e)),
            ),
          ),
          const Expanded(child: Divider(indent: 12, color: kBorder)),
        ],
      ),
    );
  }
}

// ── Tarjeta de juego en vivo ───────────────────────────────────────────────────

class _LiveGameCard extends StatelessWidget {
  final MatchModel match;
  final VoidCallback onTap;

  const _LiveGameCard({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isBaseball = match.sport == 'baseball' || match.sport == 'baseball_lvbp';
    final isBasketball = match.sport == 'basketball';
    final isAmericanFootball = match.sport == 'american_football';
    final sportIcon = isBaseball ? '⚾' : isBasketball ? '🏀' : isAmericanFootball ? '🏈' : '⚽';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF22c55e).withAlpha(60)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            // Liga + badge EN VIVO
            Row(
              children: [
                Text(sportIcon, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    match.league.name,
                    style: dmSans(12, color: kMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22c55e).withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF22c55e).withAlpha(60)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PulsingDot(size: 6),
                      const SizedBox(width: 4),
                      Text('EN VIVO', style: dmSans(10, weight: FontWeight.w700, color: const Color(0xFF22c55e))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Marcador
            Row(
              children: [
                // Visitante
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _short(match.awayTeam),
                        style: dmSans(14, weight: FontWeight.w700, color: kText),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Visitante',
                        style: dmSans(10, color: kMuted),
                      ),
                    ],
                  ),
                ),

                // Score
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22c55e).withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${match.awayScore ?? 0}  –  ${match.homeScore ?? 0}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF22c55e),
                      letterSpacing: 1,
                    ),
                  ),
                ),

                // Local
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _short(match.homeTeam),
                        style: dmSans(14, weight: FontWeight.w700, color: kText),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Local',
                        style: dmSans(10, color: kMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Ver en vivo button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: kAccent.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kAccent.withAlpha(40)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isBaseball ? Icons.sports_baseball : isBasketball ? Icons.sports_basketball : isAmericanFootball ? Icons.sports_football : Icons.sports_soccer,
                    size: 14,
                    color: kAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isBaseball ? 'Ver diamante en vivo' : isBasketball ? 'Ver cancha en vivo' : isAmericanFootball ? 'Ver campo en vivo' : 'Ver partido en vivo',
                    style: dmSans(12, weight: FontWeight.w600, color: kAccent),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios, size: 10, color: kAccent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _short(String full) {
    final parts = full.split(' ');
    return parts.length > 1 ? parts.last : full;
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎯', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('No hay partidos en vivo',
              style: dmSans(16, weight: FontWeight.w600, color: kText)),
          const SizedBox(height: 6),
          Text('⚾ MLB · ⚽ Fútbol · 🏀 NBA · 🏈 NFL',
              style: dmSans(13, color: kMuted)),
          const SizedBox(height: 24),
          Text('Se actualiza cada 30 segundos',
              style: dmSans(11, color: kMuted)),
        ],
      ),
    );
  }
}

// ── Punto pulsante animado ─────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  final double size;
  const _PulsingDot({this.size = 8});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
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
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF22c55e).withOpacity(_anim.value),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF22c55e).withOpacity(_anim.value * 0.6),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
