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

      // Béisbol y fútbol en paralelo
      final results = await Future.wait([
        http.get(Uri.parse('$kBaseUrl/api/matches?sport=baseball&match_date=$today'), headers: headers)
            .timeout(const Duration(seconds: 10)),
        http.get(Uri.parse('$kBaseUrl/api/matches?sport=football&match_date=$today'), headers: headers)
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
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _liveGames.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _LiveGameCard(
                      match: _liveGames[i],
                      onTap: () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => LiveMatchScreen(match: _liveGames[i]),
                        ),
                      ),
                    ),
                  ),
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
    final isBaseball = match.sport == 'baseball';
    final sportIcon  = isBaseball ? '⚾' : '⚽';

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
                color: isBaseball ? kAccent.withAlpha(15) : kSurface2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kAccent.withAlpha(40)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isBaseball ? Icons.sports_baseball : Icons.sports_soccer,
                    size: 14,
                    color: kAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isBaseball ? 'Ver diamante en vivo' : 'Ver partido en vivo',
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
          const Text('⚾', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('No hay partidos en vivo ahora',
              style: dmSans(16, weight: FontWeight.w600, color: kText)),
          const SizedBox(height: 6),
          Text('Los juegos MLB empiezan ~5pm Venezuela',
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
