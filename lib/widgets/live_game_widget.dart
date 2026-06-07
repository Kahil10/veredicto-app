import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/theme.dart';
import '../models/match_model.dart';

class LiveGameWidget extends StatefulWidget {
  final MatchModel match;
  final String? token;

  const LiveGameWidget({super.key, required this.match, this.token});

  @override
  State<LiveGameWidget> createState() => _LiveGameWidgetState();
}

class _LiveGameWidgetState extends State<LiveGameWidget> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    final gamePk = widget.match.externalId;
    try {
      // MLB Stats API — live feed requiere v1.1 (no v1)
      final resp = await http
          .get(Uri.parse('https://statsapi.mlb.com/api/v1.1/game/$gamePk/feed/live'))
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200 && mounted) {
        final raw = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() {
          _data = _parseMLBFeed(raw, gamePk);
          _loading = false;
          _error = null;
        });
      } else if (mounted) {
        setState(() {
          _loading = false;
          _error = 'MLB API ${resp.statusCode}';
        });
      }
    } on Exception catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Map<String, dynamic> _parseMLBFeed(Map<String, dynamic> raw, int gamePk) {
    final gameData  = raw['gameData']  as Map<String, dynamic>? ?? {};
    final liveData  = raw['liveData']  as Map<String, dynamic>? ?? {};
    final ls        = liveData['linescore'] as Map<String, dynamic>? ?? {};
    final playsRoot = liveData['plays']     as Map<String, dynamic>? ?? {};

    final state     = (gameData['status'] as Map?)?['abstractGameState'] as String? ?? 'Preview';
    final teamsGd   = gameData['teams'] as Map<String, dynamic>? ?? {};
    final homeName  = (teamsGd['home'] as Map?)?['name'] as String? ?? widget.match.homeTeam;
    final awayName  = (teamsGd['away'] as Map?)?['name'] as String? ?? widget.match.awayTeam;

    final inning    = ls['currentInning']  as int?    ?? 1;
    final half      = ls['inningHalf']     as String? ?? 'Top';
    final balls     = ls['balls']          as int?    ?? 0;
    final strikes   = ls['strikes']        as int?    ?? 0;
    final outs      = ls['outs']           as int?    ?? 0;

    final offense = ls['offense'] as Map<String, dynamic>? ?? {};
    final runners = {
      'first':  offense.containsKey('first'),
      'second': offense.containsKey('second'),
      'third':  offense.containsKey('third'),
    };

    final lsTeams   = ls['teams'] as Map<String, dynamic>? ?? {};
    final homeT     = lsTeams['home'] as Map? ?? {};
    final awayT     = lsTeams['away'] as Map? ?? {};
    final homeRuns  = homeT['runs']   as int? ?? widget.match.homeScore ?? 0;
    final awayRuns  = awayT['runs']   as int? ?? widget.match.awayScore ?? 0;
    final homeHits  = homeT['hits']   as int? ?? 0;
    final awayHits  = awayT['hits']   as int? ?? 0;
    final homeErr   = homeT['errors'] as int? ?? 0;
    final awayErr   = awayT['errors'] as int? ?? 0;

    final innings = ((ls['innings'] as List?) ?? []).map((e) {
      final i = e as Map;
      return {
        'inning': i['num'],
        'home':   (i['home'] as Map?)?['runs'],
        'away':   (i['away'] as Map?)?['runs'],
      };
    }).toList();

    final cp      = playsRoot['currentPlay'] as Map<String, dynamic>? ?? {};
    final matchup = cp['matchup'] as Map? ?? {};
    final result  = cp['result']  as Map? ?? {};
    final batter  = (matchup['batter']  as Map?)?['fullName'] as String? ?? '';
    final pitcher = (matchup['pitcher'] as Map?)?['fullName'] as String? ?? '';
    final lastEvt = result['event']       as String? ?? '';
    final lastDsc = result['description'] as String? ?? '';

    final battingTeam = half == 'Bottom' ? homeName : awayName;

    final allPlays  = (playsRoot['allPlays'] as List?) ?? [];
    final lastPlays = <Map>[];
    for (final p in allPlays.reversed) {
      final pm   = p as Map;
      final r    = pm['result']  as Map? ?? {};
      final ab   = pm['about']   as Map? ?? {};
      final mu   = pm['matchup'] as Map? ?? {};
      final desc = r['description'] as String? ?? '';
      if (desc.isEmpty) continue;
      lastPlays.add({
        'description': desc,
        'event':   r['event'] as String? ?? '',
        'inning':  ab['inning'],
        'half':    ab['halfInning'] as String? ?? '',
        'batter':  (mu['batter']  as Map?)?['fullName'] as String? ?? '',
        'pitcher': (mu['pitcher'] as Map?)?['fullName'] as String? ?? '',
      });
      if (lastPlays.length >= 8) break;
    }

    // ── Alineaciones del boxscore ─────────────────────────────────────────────
    final boxscore = liveData['boxscore'] as Map<String, dynamic>? ?? {};
    final bsTeams  = boxscore['teams']    as Map<String, dynamic>? ?? {};
    final lineups  = {
      'home': _extractLineup(bsTeams['home'] as Map?, homeName, batter),
      'away': _extractLineup(bsTeams['away'] as Map?, awayName, batter),
    };

    final feedOk = state == 'Live' || state == 'Final';

    return {
      'game_pk':        gamePk,
      'feed_available': feedOk,
      'state':          state,
      'inning':         inning,
      'inning_half':    half,
      'inning_label':   feedOk ? '${inning}a entrada' : 'Pre-juego',
      'balls':          balls,
      'strikes':        strikes,
      'outs':           outs,
      'runners':        runners,
      'home_team':      homeName,
      'away_team':      awayName,
      'home_runs':      homeRuns,
      'away_runs':      awayRuns,
      'home_hits':      homeHits,
      'away_hits':      awayHits,
      'home_errors':    homeErr,
      'away_errors':    awayErr,
      'linescore':      innings,
      'current_play': {
        'batter':       batter,
        'pitcher':      pitcher,
        'batting_team': battingTeam,
        'last_event':   lastEvt,
        'last_description': lastDsc,
      },
      'last_plays': lastPlays,
      'lineups':    lineups,
    };
  }

  static Map<String, dynamic> _extractLineup(Map? teamData, String teamName, String currentBatter) {
    if (teamData == null) return {'team': teamName, 'batting_order': <Map>[]};

    final battingOrder = (teamData['battingOrder'] as List?) ?? [];
    final players      = (teamData['players'] as Map?) ?? {};

    final lineup = <Map>[];
    for (final id in battingOrder) {
      final playerKey = 'ID$id';
      final player    = (players[playerKey] as Map?) ?? {};
      final person    = (player['person']     as Map?) ?? {};
      final position  = (player['position']   as Map?) ?? {};
      final bstats    = ((player['stats'] as Map?)?['batting'] as Map?) ?? {};
      final name      = person['fullName'] as String? ?? '';
      lineup.add({
        'name':       name,
        'position':   position['abbreviation'] as String? ?? '?',
        'jersey':     player['jerseyNumber']   as String? ?? '',
        'ab':         bstats['atBats'] as int? ?? 0,
        'hits':       bstats['hits']   as int? ?? 0,
        'rbi':        bstats['rbi']    as int? ?? 0,
        'is_current': name.isNotEmpty && name == currentBatter,
      });
    }

    return {'team': teamName, 'batting_order': lineup};
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: 220,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: kAccent, strokeWidth: 2),
            const SizedBox(height: 14),
            Text('Cargando datos en vivo…', style: dmSans(12, color: kMuted)),
          ],
        ),
      );
    }
    if (_data == null) {
      return _ErrorState(
        error: _error ?? 'Sin datos del partido',
        match: widget.match,
        onRetry: _fetch,
      );
    }

    final d          = _data!;
    final feedOk     = d['feed_available'] as bool? ?? true;
    final runners    = (d['runners']     as Map?)?.cast<String, dynamic>() ?? {};
    final cp         = (d['current_play'] as Map?)?.cast<String, dynamic>() ?? {};
    final lastPlays  = (d['last_plays']  as List?)?.cast<Map>() ?? [];
    final linescore  = (d['linescore']   as List?)?.cast<Map>() ?? [];
    final lineups    = (d['lineups']     as Map?)?.cast<String, dynamic>() ?? {};

    // Juego aún no comenzó — mostrar marcador básico con mensaje
    if (!feedOk) {
      return _PreGameState(data: d, onRefresh: _fetch);
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Linescore header ──────────────────────────────────────────────
          _LinescoreHeader(data: d, linescore: linescore),
          const SizedBox(height: 16),

          // ── Label ─────────────────────────────────────────────────────────
          Text('Partido en vivo',
              style: dmSans(16, weight: FontWeight.w700, color: kText)),
          const SizedBox(height: 10),

          // ── Diamante ──────────────────────────────────────────────────────
          _DiamondCard(
            runners: runners,
            balls:   d['balls']   as int? ?? 0,
            strikes: d['strikes'] as int? ?? 0,
            outs:    d['outs']    as int? ?? 0,
            currentPlay: cp,
          ),
          const SizedBox(height: 14),

          // ── Tabs ──────────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              children: [
                TabBar(
                  indicatorColor: kAccent,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: kAccent,
                  unselectedLabelColor: kMuted,
                  labelStyle: dmSans(12, weight: FontWeight.w700),
                  unselectedLabelStyle: dmSans(12),
                  dividerColor: kBorder,
                  tabs: const [
                    Tab(text: 'ESTADÍSTICAS'),
                    Tab(text: 'INCIDENTES'),
                    Tab(text: 'ALINEACIONES'),
                  ],
                ),
                SizedBox(
                  height: 230,
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _StatsTab(data: d),
                      _IncidentsTab(plays: lastPlays),
                      _LineupsTab(lineups: lineups),
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

// ── Linescore header ───────────────────────────────────────────────────────────

class _LinescoreHeader extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<Map> linescore;

  const _LinescoreHeader({required this.data, required this.linescore});

  @override
  Widget build(BuildContext context) {
    final inningLabel = data['inning_label'] as String? ?? '';
    final half        = data['inning_half']  as String? ?? 'Top';
    final homeTeam    = data['home_team']    as String? ?? '';
    final awayTeam    = data['away_team']    as String? ?? '';
    final homeRuns    = data['home_runs']    as int? ?? 0;
    final awayRuns    = data['away_runs']    as int? ?? 0;
    final curInning   = data['inning']       as int? ?? 1;

    // Mostrar las últimas 3 entradas + total
    final shown = linescore.length > 3
        ? linescore.sublist(linescore.length - 3)
        : linescore;

    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          // Fila cabecera: liga + inning
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF22c55e).withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF22c55e).withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22c55e),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text('EN VIVO', style: dmSans(10, weight: FontWeight.w700, color: const Color(0xFF22c55e))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(inningLabel, style: dmSans(13, weight: FontWeight.w600, color: kText)),
              const SizedBox(width: 4),
              Icon(
                half == 'Top' ? Icons.arrow_upward : Icons.arrow_downward,
                size: 13,
                color: kAccent,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tabla: equipo | entradas | R
          Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FlexColumnWidth(3),
              // columnas de entradas y R dinámicas abajo
            },
            children: [
              // Cabecera columnas
              TableRow(
                children: [
                  const SizedBox(),
                  ...shown.map((inn) => _cell('${inn['inning']}', kMuted, bold: false)),
                  _cell('R', kAccent, bold: true),
                ],
              ),
              // Away team
              TableRow(
                children: [
                  Row(children: [
                    if (half == 'Top')
                      const Icon(Icons.sports_baseball, size: 12, color: kAccent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _shortName(awayTeam),
                        style: dmSans(13, weight: FontWeight.w700, color: kText),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  ...shown.map((inn) => _cell('${inn['away'] ?? '-'}', kText)),
                  _cell('$awayRuns', kText, bold: true, large: true),
                ],
              ),
              // Home team
              TableRow(
                children: [
                  Row(children: [
                    if (half == 'Bottom')
                      const Icon(Icons.sports_baseball, size: 12, color: kAccent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _shortName(homeTeam),
                        style: dmSans(13, weight: FontWeight.w700, color: kText),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  ...shown.map((inn) => _cell('${inn['home'] ?? '-'}', kText)),
                  _cell('$homeRuns', kText, bold: true, large: true),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, Color color, {bool bold = false, bool large = false}) =>
      Center(
        child: Text(
          text,
          style: dmSans(
            large ? 16 : 12,
            color: color,
            weight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      );

  String _shortName(String full) {
    final parts = full.split(' ');
    return parts.length > 1 ? parts.last : full;
  }
}

// ── Diamante card ──────────────────────────────────────────────────────────────

class _DiamondCard extends StatelessWidget {
  final Map<String, dynamic> runners;
  final int balls, strikes, outs;
  final Map<String, dynamic> currentPlay;

  const _DiamondCard({
    required this.runners,
    required this.balls,
    required this.strikes,
    required this.outs,
    required this.currentPlay,
  });

  @override
  Widget build(BuildContext context) {
    final batter      = currentPlay['batter']      as String? ?? '';
    final pitcher     = currentPlay['pitcher']     as String? ?? '';
    final battingTeam = currentPlay['batting_team'] as String? ?? '';
    final lastEvent   = currentPlay['last_event']  as String? ?? '';

    // Altura total del card: zona diamante + BSO + narrativa
    const double cardH       = 300;
    const double diamondH    = 185;  // zona exclusiva del diamante
    const double bsoH        = 28;
    const double narrativeH  = 68;
    // diamondH + gap(8) + bsoH + gap(5) + narrativeH = 185+8+28+5+68 = 294 → ok con 300

    return Container(
      height: cardH,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // ── Fondo estadio ────────────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0d2a1a),
                    Color(0xFF081810),
                    Color(0xFF050d08),
                  ],
                ),
              ),
            ),
          ),
          // Luces del estadio (decorativas)
          Positioned(top: -30, left: -20,
            child: Container(width: 140, height: 140,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF22c55e).withAlpha(18), Colors.transparent])))),
          Positioned(top: -30, right: -20,
            child: Container(width: 140, height: 140,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF22c55e).withAlpha(18), Colors.transparent])))),

          // ── Diamante centrado (ancho completo) ────────────────────────────
          Positioned(
            top: 6,
            left: 0,
            right: 0,
            height: diamondH,
            child: CustomPaint(
              painter: _DiamondPainter(
                onFirst:  runners['first']  == true,
                onSecond: runners['second'] == true,
                onThird:  runners['third']  == true,
              ),
            ),
          ),

          // ── Badge de béisbol (esquina sup-derecha, encima del diamante) ──
          Positioned(
            right: 12,
            top: 10,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kAccent,
                boxShadow: [BoxShadow(color: kAccent.withAlpha(90), blurRadius: 10, spreadRadius: 1)],
              ),
              child: const Icon(Icons.sports_baseball, color: Colors.black, size: 24),
            ),
          ),

          // ── BSO dots — justo debajo del diamante ─────────────────────────
          Positioned(
            top: diamondH + 6,
            left: 14,
            right: 14,
            height: bsoH,
            child: _BSORow(balls: balls, strikes: strikes, outs: outs),
          ),

          // ── Narrativa jugada actual — bottom fijo ─────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: narrativeH,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kSurface.withAlpha(235),
                border: Border(top: BorderSide(color: kBorder)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a2a3a),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: kBorder),
                    ),
                    child: const Icon(Icons.person, color: kMuted, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(battingTeam,
                          style: dmSans(12, weight: FontWeight.w700, color: kText),
                          overflow: TextOverflow.ellipsis),
                        if (lastEvent.isNotEmpty)
                          Text(lastEvent,
                            style: dmSans(11, color: kAccent, weight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        if (pitcher.isNotEmpty)
                          Text(pitcher,
                            style: dmSans(10, color: kMuted),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (batter.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kAccent.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: kAccent.withAlpha(60)),
                      ),
                      child: Text(_lastName(batter),
                        style: dmSans(12, weight: FontWeight.w700, color: kAccent)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _lastName(String full) {
    final parts = full.trim().split(' ');
    return parts.length > 1 ? parts.last : full;
  }
}

// ── Dots BSO ───────────────────────────────────────────────────────────────────

class _BSORow extends StatelessWidget {
  final int balls, strikes, outs;
  const _BSORow({required this.balls, required this.strikes, required this.outs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _bsoGroup('B', balls,   4, const Color(0xFF22c55e)),
        const SizedBox(width: 14),
        _bsoGroup('S', strikes, 3, kGold),
        const SizedBox(width: 14),
        _bsoGroup('O', outs,    3, kRed),
      ],
    );
  }

  Widget _bsoGroup(String label, int count, int max, Color color) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(width: 4),
        ...List.generate(max, (i) => Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < count ? color : Colors.white.withAlpha(30),
              boxShadow: i < count ? [BoxShadow(color: color.withAlpha(120), blurRadius: 4)] : null,
            ),
          ),
        )),
      ],
    );
  }
}

// ── CustomPainter del diamante ─────────────────────────────────────────────────

class _DiamondPainter extends CustomPainter {
  final bool onFirst, onSecond, onThird;
  const _DiamondPainter({
    required this.onFirst,
    required this.onSecond,
    required this.onThird,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    // Centrar verticalmente con ligero desplazamiento hacia arriba
    // para que el home plate quede en el tercio inferior del área, no en el borde
    final cy = size.height * 0.52;
    final r  = size.height * 0.36;   // relativo a la altura → se adapta al área

    // Posiciones de las bases (vista superior, como el campo real)
    final home   = Offset(cx,         cy + r);
    final first  = Offset(cx + r,     cy);
    final second = Offset(cx,         cy - r);
    final third  = Offset(cx - r,     cy);

    // Líneas del infield
    final fieldPaint = Paint()
      ..color = Colors.white.withAlpha(18)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final fieldPath = Path()
      ..moveTo(home.dx,   home.dy)
      ..lineTo(first.dx,  first.dy)
      ..lineTo(second.dx, second.dy)
      ..lineTo(third.dx,  third.dy)
      ..close();
    canvas.drawPath(fieldPath, fieldPaint);

    // Relleno del infield (muy sutil)
    canvas.drawPath(fieldPath, Paint()..color = Colors.white.withAlpha(5));

    // Líneas de base (baseline)
    _drawBaseLine(canvas, home,  first,  Colors.white.withAlpha(25));
    _drawBaseLine(canvas, first, second, Colors.white.withAlpha(25));
    _drawBaseLine(canvas, second, third, Colors.white.withAlpha(25));
    _drawBaseLine(canvas, third,  home,  Colors.white.withAlpha(25));

    // Bases
    const s = 13.0; // half-size del rombo
    _drawBase(canvas, second, s, onSecond);
    _drawBase(canvas, third,  s, onThird);
    _drawBase(canvas, first,  s, onFirst);
    _drawHomePlate(canvas, home, s * 0.9);
  }

  void _drawBaseLine(Canvas canvas, Offset a, Offset b, Color color) {
    canvas.drawLine(a, b, Paint()..color = color..strokeWidth = 1);
  }

  void _drawBase(Canvas canvas, Offset center, double s, bool occupied) {
    final path = Path()
      ..moveTo(center.dx,     center.dy - s)
      ..lineTo(center.dx + s, center.dy)
      ..lineTo(center.dx,     center.dy + s)
      ..lineTo(center.dx - s, center.dy)
      ..close();

    if (occupied) {
      // Base ocupada: blanco brillante con glow
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withAlpha(220)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawPath(path, Paint()..color = Colors.white);
    } else {
      // Base vacía: gris oscuro con borde
      canvas.drawPath(path, Paint()..color = const Color(0xFF3a4a5a));
      canvas.drawPath(path, Paint()
        ..color = Colors.white.withAlpha(50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
    }
  }

  void _drawHomePlate(Canvas canvas, Offset center, double s) {
    // Home plate tiene forma de pentágono en béisbol real; usamos rombo pequeño
    final path = Path()
      ..moveTo(center.dx,     center.dy - s)
      ..lineTo(center.dx + s, center.dy)
      ..lineTo(center.dx,     center.dy + s)
      ..lineTo(center.dx - s, center.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF2a3a4a));
    canvas.drawPath(path, Paint()
      ..color = Colors.white.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(_DiamondPainter old) =>
      old.onFirst != onFirst || old.onSecond != onSecond || old.onThird != onThird;
}

// ── Tab: Estadísticas ──────────────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _StatsTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final homeTeam = data['home_team']  as String? ?? '';
    final awayTeam = data['away_team']  as String? ?? '';
    final homeR    = data['home_runs']  as int? ?? 0;
    final awayR    = data['away_runs']  as int? ?? 0;
    final homeH    = data['home_hits']  as int? ?? 0;
    final awayH    = data['away_hits']  as int? ?? 0;
    final homeE    = data['home_errors'] as int? ?? 0;
    final awayE    = data['away_errors'] as int? ?? 0;

    final shortHome = _short(homeTeam);
    final shortAway = _short(awayTeam);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Cabecera
          Row(children: [
            const Expanded(flex: 3, child: SizedBox()),
            Expanded(flex: 2, child: Text(shortAway, textAlign: TextAlign.center,
                style: dmSans(12, weight: FontWeight.w700, color: kMuted))),
            Expanded(flex: 2, child: Text(shortHome, textAlign: TextAlign.center,
                style: dmSans(12, weight: FontWeight.w700, color: kMuted))),
          ]),
          const SizedBox(height: 8),
          _statRow('Carreras', awayR, homeR),
          _statRow('Hits',     awayH, homeH),
          _statRow('Errores',  awayE, homeE, lowerIsBetter: true),
        ],
      ),
    );
  }

  Widget _statRow(String label, int away, int home, {bool lowerIsBetter = false}) {
    Color _color(int v, int other) {
      if (v == other) return kText;
      final better = lowerIsBetter ? v < other : v > other;
      return better ? kAccent : kMuted;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(flex: 3, child: Text(label, style: dmSans(13, color: kMuted))),
        Expanded(flex: 2, child: Text('$away', textAlign: TextAlign.center,
            style: dmSans(15, weight: FontWeight.w700, color: _color(away, home)))),
        Expanded(flex: 2, child: Text('$home', textAlign: TextAlign.center,
            style: dmSans(15, weight: FontWeight.w700, color: _color(home, away)))),
      ]),
    );
  }

  String _short(String full) {
    final parts = full.split(' ');
    return parts.length > 1 ? parts.last : full;
  }
}

// ── Tab: Incidentes ────────────────────────────────────────────────────────────

class _IncidentsTab extends StatelessWidget {
  final List<Map> plays;
  const _IncidentsTab({required this.plays});

  @override
  Widget build(BuildContext context) {
    if (plays.isEmpty) {
      return Center(
        child: Text('Sin incidentes aún', style: dmSans(13, color: kMuted)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: plays.length,
      separatorBuilder: (_, __) => Divider(color: kBorder, height: 1),
      itemBuilder: (_, i) {
        final p    = plays[i];
        final desc = p['description'] as String? ?? '';
        final inn  = p['inning']  as int?;
        final half = p['half']    as String? ?? '';
        final halfIcon = half == 'bottom' ? '↓' : '↑';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  inn != null ? '$halfIcon$inn' : '',
                  style: dmSans(11, color: kAccent, weight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(desc, style: dmSans(12, color: kText)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Tab: Alineaciones ─────────────────────────────────────────────────────────

class _LineupsTab extends StatefulWidget {
  final Map<String, dynamic> lineups;
  const _LineupsTab({required this.lineups});

  @override
  State<_LineupsTab> createState() => _LineupsTabState();
}

class _LineupsTabState extends State<_LineupsTab> {
  bool _showHome = false; // false = visitante, true = local

  @override
  Widget build(BuildContext context) {
    final homeData = (widget.lineups['home'] as Map?)?.cast<String, dynamic>() ?? {};
    final awayData = (widget.lineups['away'] as Map?)?.cast<String, dynamic>() ?? {};
    final homeOrder = (homeData['batting_order'] as List?)?.cast<Map>() ?? [];
    final awayOrder = (awayData['batting_order'] as List?)?.cast<Map>() ?? [];
    final homeName  = homeData['team'] as String? ?? 'Local';
    final awayName  = awayData['team'] as String? ?? 'Visitante';

    if (homeOrder.isEmpty && awayOrder.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups_outlined, color: kMuted, size: 32),
            const SizedBox(height: 8),
            Text('Alineaciones no disponibles aún', style: dmSans(12, color: kMuted)),
            Text('Disponible ~1h antes del partido', style: dmSans(10, color: kMuted)),
          ],
        ),
      );
    }

    final shown = _showHome ? homeOrder : awayOrder;
    final shownName = _showHome ? homeName : awayName;

    return Column(
      children: [
        // Toggle home/away
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showHome = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: !_showHome ? kAccent.withAlpha(30) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: !_showHome ? kAccent.withAlpha(80) : kBorder),
                  ),
                  child: Text(
                    _shortTeam(awayName),
                    textAlign: TextAlign.center,
                    style: dmSans(11, weight: !_showHome ? FontWeight.w700 : FontWeight.w400,
                        color: !_showHome ? kAccent : kMuted),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showHome = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: _showHome ? kAccent.withAlpha(30) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _showHome ? kAccent.withAlpha(80) : kBorder),
                  ),
                  child: Text(
                    _shortTeam(homeName),
                    textAlign: TextAlign.center,
                    style: dmSans(11, weight: _showHome ? FontWeight.w700 : FontWeight.w400,
                        color: _showHome ? kAccent : kMuted),
                  ),
                ),
              ),
            ),
          ]),
        ),
        // Lista de bateadores
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: shown.length,
            itemBuilder: (_, i) {
              final p          = shown[i];
              final name       = p['name']       as String? ?? '';
              final pos        = p['position']   as String? ?? '';
              final ab         = p['ab']         as int? ?? 0;
              final hits       = p['hits']       as int? ?? 0;
              final rbi        = p['rbi']        as int? ?? 0;
              final isCurrent  = p['is_current'] as bool? ?? false;
              final lastName   = name.split(' ').last;

              return Container(
                margin: const EdgeInsets.only(bottom: 3),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: isCurrent ? kAccent.withAlpha(18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCurrent ? kAccent.withAlpha(60) : Colors.transparent,
                  ),
                ),
                child: Row(children: [
                  // Número de orden
                  SizedBox(
                    width: 18,
                    child: Text('${i + 1}',
                        style: dmSans(10, color: isCurrent ? kAccent : kMuted)),
                  ),
                  // Posición
                  Container(
                    width: 28,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: kSurface2,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(pos,
                        style: dmSans(9, weight: FontWeight.w700,
                            color: isCurrent ? kAccent : kMuted)),
                  ),
                  const SizedBox(width: 6),
                  // Nombre
                  Expanded(
                    child: Row(children: [
                      if (isCurrent) ...[
                        const Icon(Icons.sports_baseball, size: 10, color: kAccent),
                        const SizedBox(width: 3),
                      ],
                      Expanded(
                        child: Text(lastName,
                            style: dmSans(12,
                                weight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                color: isCurrent ? kAccent : kText),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ),
                  // Stats
                  Row(children: [
                    _Stat('${hits}/${ab}', 'H/AB'),
                    const SizedBox(width: 8),
                    _Stat('$rbi', 'RBI'),
                  ]),
                ]),
              );
            },
          ),
        ),
      ],
    );
  }

  String _shortTeam(String full) {
    final parts = full.split(' ');
    return parts.length > 1 ? parts.last : full;
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: dmSans(11, weight: FontWeight.w700, color: kText)),
      Text(label, style: dmSans(8, color: kMuted)),
    ]);
  }
}

// ── Pre-game: juego no ha comenzado ───────────────────────────────────────────

class _PreGameState extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onRefresh;
  const _PreGameState({required this.data, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final home = data['home_team'] as String? ?? '';
    final away = data['away_team'] as String? ?? '';
    final homeRuns = data['home_runs'] as int? ?? 0;
    final awayRuns = data['away_runs'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: kAccent.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kAccent.withAlpha(60)),
                ),
                child: Text('⚾ Calentamiento / Pre-juego',
                    style: dmSans(12, weight: FontWeight.w600, color: kAccent)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: Text(away, style: dmSans(15, weight: FontWeight.w700, color: kText), textAlign: TextAlign.center, maxLines: 2)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '$awayRuns  –  $homeRuns',
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFF22c55e)),
                    ),
                  ),
                  Expanded(child: Text(home, style: dmSans(15, weight: FontWeight.w700, color: kText), textAlign: TextAlign.center, maxLines: 2)),
                ],
              ),
              const SizedBox(height: 20),
              Text('El feed en vivo estará disponible cuando el partido comience',
                  style: dmSans(12, color: kMuted), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Actualizar'),
                style: OutlinedButton.styleFrom(foregroundColor: kAccent, side: BorderSide(color: kAccent.withAlpha(80))),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Estado de error con datos básicos ─────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String error;
  final dynamic match;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.match, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final away = match.awayTeam as String? ?? '';
    final home = match.homeTeam as String? ?? '';
    final awayScore = match.awayScore as int?;
    final homeScore = match.homeScore as int?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Marcador básico del partido
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: Text(away, style: dmSans(15, weight: FontWeight.w700, color: kText), textAlign: TextAlign.center)),
                  Text(
                    '${awayScore ?? '-'}  –  ${homeScore ?? '-'}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF22c55e)),
                  ),
                  Expanded(child: Text(home, style: dmSans(15, weight: FontWeight.w700, color: kText), textAlign: TextAlign.center)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Mensaje de error
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            children: [
              const Icon(Icons.wifi_off_outlined, color: kMuted, size: 36),
              const SizedBox(height: 10),
              Text('No se pudo cargar el feed en vivo',
                  style: dmSans(14, weight: FontWeight.w600, color: kText),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(
                error,
                style: dmSans(11, color: kMuted),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccent,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
