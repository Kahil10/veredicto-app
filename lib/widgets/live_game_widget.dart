import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/config.dart';
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
    try {
      final headers = <String, String>{};
      if (widget.token != null) headers['Authorization'] = 'Bearer ${widget.token}';
      final resp = await http
          .get(Uri.parse('$kBaseUrl/api/matches/${widget.match.id}/live'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200 && mounted) {
        setState(() {
          _data = jsonDecode(resp.body) as Map<String, dynamic>;
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: kAccent, strokeWidth: 2)),
      );
    }
    if (_data == null) return const SizedBox();

    final d          = _data!;
    final runners    = (d['runners']     as Map?)?.cast<String, dynamic>() ?? {};
    final cp         = (d['current_play'] as Map?)?.cast<String, dynamic>() ?? {};
    final lastPlays  = (d['last_plays']  as List?)?.cast<Map>() ?? [];
    final linescore  = (d['linescore']   as List?)?.cast<Map>() ?? [];

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
                      _LineupsTab(),
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

    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // ── Fondo estadio (gradiente + overlay) ──────────────────────────
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
          // Círculos decorativos para simular las luces del estadio
          Positioned(
            top: -30,
            left: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF22c55e).withAlpha(15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF22c55e).withAlpha(15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Diamante ────────────────────────────────────────────────────
          Positioned(
            top: 10,
            left: 0,
            right: 60,
            height: 175,
            child: CustomPaint(
              painter: _DiamondPainter(
                onFirst:  runners['first']  == true,
                onSecond: runners['second'] == true,
                onThird:  runners['third']  == true,
              ),
            ),
          ),

          // ── Avatar bateador/pitcher (círculo amarillo) ───────────────────
          Positioned(
            right: 14,
            top: 30,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kAccent,
                boxShadow: [
                  BoxShadow(
                    color: kAccent.withAlpha(80),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.sports_baseball, color: Colors.black, size: 28),
            ),
          ),

          // ── BSO dots ───────────────────────────────────────────────────
          Positioned(
            left: 12,
            bottom: 78,
            right: 0,
            child: _BSORow(balls: balls, strikes: strikes, outs: outs),
          ),

          // ── Narrativa jugada actual ────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: kSurface.withAlpha(230),
                border: Border(top: BorderSide(color: kBorder)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a2a3a),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kBorder),
                    ),
                    child: const Icon(Icons.person, color: kMuted, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          battingTeam,
                          style: dmSans(12, weight: FontWeight.w700, color: kText),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (lastEvent.isNotEmpty)
                          Text(
                            lastEvent,
                            style: dmSans(11, color: kAccent, weight: FontWeight.w600),
                          ),
                        if (pitcher.isNotEmpty)
                          Text(
                            pitcher,
                            style: dmSans(11, color: kMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
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
                      child: Text(
                        _lastName(batter),
                        style: dmSans(11, weight: FontWeight.w700, color: kAccent),
                      ),
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
    final cy = size.height / 2 + 10;
    final r  = math.min(size.width, size.height) * 0.36;

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

class _LineupsTab extends StatelessWidget {
  const _LineupsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.groups_outlined, color: kMuted, size: 36),
          const SizedBox(height: 10),
          Text('Alineaciones próximamente', style: dmSans(13, color: kMuted)),
          const SizedBox(height: 4),
          Text('Disponible ~1h antes del primer out',
              style: dmSans(11, color: kMuted)),
        ],
      ),
    );
  }
}
