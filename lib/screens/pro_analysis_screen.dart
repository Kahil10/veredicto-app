import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../models/prediction_model.dart';
import '../models/match_model.dart';
import '../providers/auth_provider.dart';

class ProAnalysisScreen extends StatefulWidget {
  final MatchModel match;
  final PredictionModel pred;
  const ProAnalysisScreen({super.key, required this.match, required this.pred});

  @override
  State<ProAnalysisScreen> createState() => _ProAnalysisScreenState();
}

class _ProAnalysisScreenState extends State<ProAnalysisScreen> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;
  String _loadingStep = 'Consultando MLB Stats API...';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    final steps = [
      'Consultando MLB Stats API...',
      'Obteniendo standings y pitcher stats...',
      'Consultando clima del estadio...',
      'Generando análisis con IA...',
    ];

    // Simular pasos de carga
    for (final step in steps) {
      if (mounted) setState(() => _loadingStep = step);
      await Future.delayed(const Duration(milliseconds: 600));
    }

    try {
      final r = await http.post(
        Uri.parse('$kBaseUrl/api/predictions/${widget.match.id}/pro-analysis'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (r.statusCode == 200) {
        if (mounted) setState(() { _data = jsonDecode(r.body); _loading = false; });
      } else if (r.statusCode == 403) {
        if (mounted) setState(() { _error = 'PREMIUM_REQUIRED'; _loading = false; });
      } else {
        final msg = jsonDecode(r.body)['detail'] ?? 'Error generando análisis';
        if (mounted) setState(() { _error = msg; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Error de conexión: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: kAccent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('PRO',
                style: GoogleFonts.bebasNeue(
                    fontSize: 14, color: Colors.black, letterSpacing: 2)),
          ),
          const SizedBox(width: 10),
          Text('Análisis Pro',
              style: GoogleFonts.bebasNeue(
                  fontSize: 20, color: kText, letterSpacing: 1)),
        ]),
        actions: [
          if (_data != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: kMuted),
              onPressed: () {
                setState(() { _data = null; _loading = true; });
                _load();
              },
            ),
        ],
      ),
      body: _loading
          ? _LoadingView(step: _loadingStep)
          : _error != null
              ? _ErrorView(error: _error!, match: widget.match, pred: widget.pred)
              : _AnalysisView(data: _data!, match: widget.match, pred: widget.pred),
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────

class _LoadingView extends StatefulWidget {
  final String step;
  const _LoadingView({required this.step});
  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: const [kAccent, kAccent3, kAccent],
                  transform: GradientRotation(_ctrl.value * 6.28),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: kBg),
                  child: Center(
                    child: Text('🔥',
                        style: const TextStyle(fontSize: 30)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('GENERANDO ANÁLISIS PRO',
              style: GoogleFonts.bebasNeue(
                  fontSize: 22, color: kAccent, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text(widget.step,
              style: GoogleFonts.jetBrainsMono(fontSize: 12, color: kMuted)),
          const SizedBox(height: 24),
          Text(
            'Consultando MLB Stats API · Clima · IA',
            style: GoogleFonts.dmSans(fontSize: 11, color: kMuted.withAlpha(120)),
          ),
        ]),
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final MatchModel match;
  final PredictionModel pred;
  const _ErrorView({required this.error, required this.match, required this.pred});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(error,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(color: kRed, fontSize: 14)),
      ),
    );
  }
}

// ── Análisis completo ─────────────────────────────────────────────────────────

class _AnalysisView extends StatelessWidget {
  final Map<String, dynamic> data;
  final MatchModel match;
  final PredictionModel pred;
  const _AnalysisView({required this.data, required this.match, required this.pred});

  @override
  Widget build(BuildContext context) {
    final narrative = (data['narrative'] as Map?) ?? {};
    final motor     = (data['motor'] as Map?) ?? {};
    final homeRec   = (data['home_record'] as Map?) ?? {};
    final awayRec   = (data['away_record'] as Map?) ?? {};
    final hpStats   = (data['home_pitcher_stats'] as Map?) ?? {};
    final apStats   = (data['away_pitcher_stats'] as Map?) ?? {};
    final hpLog     = (data['home_pitcher_log'] as List?) ?? [];
    final apLog     = (data['away_pitcher_log'] as List?) ?? [];
    final weather   = (data['weather'] as Map?) ?? {};
    final picks     = (narrative['picks'] as List?) ?? [];
    final factors   = (narrative['tabla_factores'] as List?) ?? [];
    final fuentes   = (data['fuentes'] as List?) ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
      children: [
        // Hero del análisis
        _ProHero(match: match, motor: motor),
        const SizedBox(height: 12),

        // Contexto de la serie
        if ((narrative['contexto'] as String?)?.isNotEmpty == true)
          _ProSection(
            icon: '📊',
            color: kAccent,
            title: 'CONTEXTO DE LA SERIE',
            child: _NarrativeText(narrative['contexto']),
          ),
        const SizedBox(height: 10),

        // Records de los equipos
        _ProSection(
          icon: '🏆',
          color: kGold,
          title: 'RECORDS 2026',
          child: _RecordsGrid(
            homeName: match.homeTeam,
            awayName: match.awayTeam,
            homeRecord: homeRec,
            awayRecord: awayRec,
          ),
        ),
        const SizedBox(height: 10),

        // Pitchers detalle
        if (hpStats.isNotEmpty || apStats.isNotEmpty)
          _ProSection(
            icon: '⚾',
            color: kAccent3,
            title: 'PITCHERS — STATS 2026',
            child: _PitcherDetail(
              homeName: motor['home_pitcher_name'] ?? match.homeTeam.split(' ').last,
              awayName: motor['away_pitcher_name'] ?? match.awayTeam.split(' ').last,
              homeStats: hpStats,
              awayStats: apStats,
              homeLog: hpLog,
              awayLog: apLog,
            ),
          ),
        if (hpStats.isNotEmpty || apStats.isNotEmpty) const SizedBox(height: 10),

        // Análisis de pitchers
        if ((narrative['pitchers'] as String?)?.isNotEmpty == true)
          _ProSection(
            icon: '🎯',
            color: kAccent2,
            title: 'ANÁLISIS DEL MATCHUP',
            child: _NarrativeText(narrative['pitchers']),
          ),
        const SizedBox(height: 10),

        // Clima
        if (weather.isNotEmpty)
          _ProSection(
            icon: '🌡️',
            color: kAccent3,
            title: 'CLIMA DEL ESTADIO',
            child: _WeatherCard(weather: weather, narrative: narrative['clima']),
          ),
        if (weather.isNotEmpty) const SizedBox(height: 10),

        // Tabla de factores
        if (factors.isNotEmpty)
          _ProSection(
            icon: '⚖️',
            color: kGold,
            title: 'TABLA DE FACTORES',
            child: _FactorsTable(
              factors: factors,
              homeName: match.homeTeam.split(' ').last,
              awayName: match.awayTeam.split(' ').last,
            ),
          ),
        if (factors.isNotEmpty) const SizedBox(height: 10),

        // Picks
        if (picks.isNotEmpty)
          _ProSection(
            icon: '💎',
            color: kAccent,
            title: 'PICKS DEL ANÁLISIS',
            child: _PicksSection(picks: picks),
          ),
        const SizedBox(height: 10),

        // Ángulo diferenciador
        if ((narrative['angulo'] as String?)?.isNotEmpty == true)
          _AnguloCard(angulo: narrative['angulo']),
        const SizedBox(height: 16),

        // Disclaimer + fuentes
        _DisclaimerSection(fuentes: fuentes),
      ],
    );
  }
}

// ── Secciones ─────────────────────────────────────────────────────────────────

class _ProHero extends StatelessWidget {
  final MatchModel match;
  final Map motor;
  const _ProHero({required this.match, required this.motor});

  @override
  Widget build(BuildContext context) {
    final home    = match.homeTeam.split(' ').last;
    final away    = match.awayTeam.split(' ').last;
    final homePct = motor['home_win_pct'];
    final awayPct = motor['away_win_pct'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF0f1318), Color(0xFF1a1f2e), Color(0xFF0f1318)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kAccent.withAlpha(50)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(4)),
            child: Text('🔥 ANÁLISIS PRO',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 9, fontWeight: FontWeight.w700, color: Colors.black, letterSpacing: 1.5)),
          ),
          const Spacer(),
          Text(match.league.name,
              style: GoogleFonts.jetBrainsMono(fontSize: 9, color: kMuted)),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Column(children: [
            Text(home.toUpperCase(),
                style: GoogleFonts.bebasNeue(fontSize: 28, color: kText, letterSpacing: 2)),
            if (homePct != null)
              Text('${homePct}%',
                  style: GoogleFonts.jetBrainsMono(fontSize: 13,
                      color: homePct > awayPct ? kAccent : kMuted,
                      fontWeight: FontWeight.w700)),
          ]),
          Text('VS',
              style: GoogleFonts.bebasNeue(fontSize: 18, color: kMuted, letterSpacing: 3)),
          Column(children: [
            Text(away.toUpperCase(),
                style: GoogleFonts.bebasNeue(fontSize: 28, color: kText, letterSpacing: 2)),
            if (awayPct != null)
              Text('${awayPct}%',
                  style: GoogleFonts.jetBrainsMono(fontSize: 13,
                      color: awayPct > homePct ? kAccent2 : kMuted,
                      fontWeight: FontWeight.w700)),
          ]),
        ]),
      ]),
    );
  }
}

class _ProSection extends StatelessWidget {
  final String icon, title;
  final Color color;
  final Widget child;
  const _ProSection({required this.icon, required this.title, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(7)),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 15))),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: GoogleFonts.bebasNeue(
                    fontSize: 16, color: kText, letterSpacing: 1.5)),
          ]),
        ),
        Container(height: 1, color: kBorder),
        Padding(padding: const EdgeInsets.all(14), child: child),
      ]),
    );
  }
}

class _NarrativeText extends StatelessWidget {
  final String? text;
  const _NarrativeText(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text ?? '—',
        style: GoogleFonts.dmSans(fontSize: 13, color: kText, height: 1.6));
  }
}

class _RecordsGrid extends StatelessWidget {
  final String homeName, awayName;
  final Map homeRecord, awayRecord;
  const _RecordsGrid({required this.homeName, required this.awayName,
      required this.homeRecord, required this.awayRecord});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _RecordCard(
        name: homeName.split(' ').last,
        record: homeRecord,
        isHome: true,
      )),
      const SizedBox(width: 10),
      Expanded(child: _RecordCard(
        name: awayName.split(' ').last,
        record: awayRecord,
        isHome: false,
      )),
    ]);
  }
}

class _RecordCard extends StatelessWidget {
  final String name;
  final Map record;
  final bool isHome;
  const _RecordCard({required this.name, required this.record, required this.isHome});

  @override
  Widget build(BuildContext context) {
    final w = record['wins'] ?? '?';
    final l = record['losses'] ?? '?';
    final pct = record['pct'] ?? '.000';
    final div = record['division'] ?? '?';
    final streak = record['streak'] ?? '';
    final barColor = isHome ? kAccent : kAccent2;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(10),
        border: Border(top: BorderSide(color: barColor, width: 3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name.toUpperCase(),
            style: GoogleFonts.bebasNeue(fontSize: 18, color: kText, letterSpacing: 1)),
        Text(div, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: kMuted)),
        const SizedBox(height: 8),
        Text('$w-$l',
            style: GoogleFonts.bebasNeue(fontSize: 32, color: barColor)),
        Text(pct,
            style: GoogleFonts.jetBrainsMono(fontSize: 11, color: kMuted)),
        if (streak.isNotEmpty)
          Text('Racha: $streak',
              style: GoogleFonts.jetBrainsMono(fontSize: 10, color: kMuted)),
      ]),
    );
  }
}

class _PitcherDetail extends StatelessWidget {
  final String homeName, awayName;
  final Map homeStats, awayStats;
  final List homeLog, awayLog;
  const _PitcherDetail({
    required this.homeName, required this.awayName,
    required this.homeStats, required this.awayStats,
    required this.homeLog, required this.awayLog,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _PitcherStatColumn(name: homeName, stats: homeStats, isHome: true)),
        const SizedBox(width: 10),
        Expanded(child: _PitcherStatColumn(name: awayName, stats: awayStats, isHome: false)),
      ]),
      if (homeLog.isNotEmpty || awayLog.isNotEmpty) ...[
        const SizedBox(height: 12),
        _GameLog(homeName: homeName, awayName: awayName, homeLog: homeLog, awayLog: awayLog),
      ],
    ]);
  }
}

class _PitcherStatColumn extends StatelessWidget {
  final String name;
  final Map stats;
  final bool isHome;
  const _PitcherStatColumn({required this.name, required this.stats, required this.isHome});

  @override
  Widget build(BuildContext context) {
    final barColor = isHome ? kAccent : kAccent2;
    if (stats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: kSurface2, borderRadius: BorderRadius.circular(8),
            border: Border(top: BorderSide(color: barColor, width: 2))),
        child: Text('Sin datos', style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
      );
    }

    Color eraColor(String? era) {
      if (era == null) return kMuted;
      final v = double.tryParse(era) ?? 99;
      return v <= 3.0 ? kGreen : v <= 4.5 ? kGold : kRed;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(8),
        border: Border(top: BorderSide(color: barColor, width: 2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name.toUpperCase(),
            style: GoogleFonts.bebasNeue(fontSize: 16, color: kText, letterSpacing: 1)),
        const SizedBox(height: 8),
        _StatRow('ERA', stats['era'] ?? '—', eraColor(stats['era']?.toString())),
        _StatRow('WHIP', stats['whip'] ?? '—', kAccent3),
        _StatRow('K/9', stats['strikeoutsPer9Inn'] ?? '—', kAccent),
        _StatRow('IP', stats['inningsPitched'] ?? '—', kMuted),
        _StatRow('W-L', '${stats['wins'] ?? 0}-${stats['losses'] ?? 0}', kText),
        _StatRow('Ks', stats['strikeOuts']?.toString() ?? '—', kAccent3),
      ]),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String lbl, val;
  final Color color;
  const _StatRow(this.lbl, this.val, this.color);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(lbl, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: kMuted, letterSpacing: 1)),
        Text(val.toString(),
            style: GoogleFonts.jetBrainsMono(fontSize: 13, color: color, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _GameLog extends StatelessWidget {
  final String homeName, awayName;
  final List homeLog, awayLog;
  const _GameLog({required this.homeName, required this.awayName,
      required this.homeLog, required this.awayLog});

  @override
  Widget build(BuildContext context) {
    final logs = [
      if (homeLog.isNotEmpty) ...[
        Text('Últimas salidas — $homeName',
            style: GoogleFonts.jetBrainsMono(fontSize: 9, color: kMuted, letterSpacing: 1)),
        const SizedBox(height: 6),
        ...homeLog.take(4).map((g) => _LogRow(g as Map)),
        const SizedBox(height: 10),
      ],
      if (awayLog.isNotEmpty) ...[
        Text('Últimas salidas — $awayName',
            style: GoogleFonts.jetBrainsMono(fontSize: 9, color: kMuted, letterSpacing: 1)),
        const SizedBox(height: 6),
        ...awayLog.take(4).map((g) => _LogRow(g as Map)),
      ],
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: logs);
  }
}

class _LogRow extends StatelessWidget {
  final Map g;
  const _LogRow(this.g);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Text(g['date']?.toString().substring(5) ?? '?',
            style: GoogleFonts.jetBrainsMono(fontSize: 10, color: kMuted)),
        const SizedBox(width: 8),
        Expanded(child: Text('vs ${g['opponent'] ?? '?'}',
            style: GoogleFonts.dmSans(fontSize: 11, color: kText))),
        Text('${g['inningsPitched'] ?? '?'} IP · ${g['strikeOuts'] ?? 0} Ks · ERA ${g['era'] ?? '?'}',
            style: GoogleFonts.jetBrainsMono(fontSize: 10, color: kMuted)),
      ]),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  final Map weather;
  final String? narrative;
  const _WeatherCard({required this.weather, this.narrative});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('🌡️', '${weather['temp_f']}°F', 'TEMP'),
      ('💧', '${weather['humidity']}%', 'HUMEDAD'),
      ('💨', '${weather['wind_mph']} mph', 'VIENTO'),
      ('🧭', '${weather['wind_dir']}', 'DIRECCIÓN'),
    ];

    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) => _WeatherItem(
          emoji: item.$1, val: item.$2, lbl: item.$3)).toList()),
      if (weather['sky'] != null) ...[
        const SizedBox(height: 10),
        Text(weather['sky'].toString(),
            style: GoogleFonts.dmSans(fontSize: 12, color: kMuted)),
      ],
      if (narrative != null && narrative!.isNotEmpty) ...[
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kGold.withAlpha(15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kGold.withAlpha(40)),
          ),
          child: Text(narrative!,
              style: GoogleFonts.dmSans(fontSize: 12, color: kText, height: 1.5)),
        ),
      ],
    ]);
  }
}

class _WeatherItem extends StatelessWidget {
  final String emoji, val, lbl;
  const _WeatherItem({required this.emoji, required this.val, required this.lbl});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(height: 4),
      Text(val,
          style: GoogleFonts.bebasNeue(fontSize: 18, color: kText)),
      Text(lbl,
          style: GoogleFonts.jetBrainsMono(fontSize: 8, color: kMuted, letterSpacing: 1)),
    ]);
  }
}

class _FactorsTable extends StatelessWidget {
  final List factors;
  final String homeName, awayName;
  const _FactorsTable({required this.factors, required this.homeName, required this.awayName});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Header
      Row(children: [
        Expanded(flex: 3,
            child: Text('FACTOR',
                style: GoogleFonts.jetBrainsMono(fontSize: 9, color: kMuted, letterSpacing: 1))),
        Expanded(flex: 2,
            child: Text(homeName.toUpperCase(),
                style: GoogleFonts.jetBrainsMono(fontSize: 9, color: kAccent, letterSpacing: 1))),
        Expanded(flex: 2,
            child: Text(awayName.toUpperCase(),
                style: GoogleFonts.jetBrainsMono(fontSize: 9, color: kAccent2, letterSpacing: 1))),
        const SizedBox(width: 50),
      ]),
      Container(height: 1, color: kBorder, margin: const EdgeInsets.symmetric(vertical: 6)),
      ...factors.map((f) {
        final fm = f as Map;
        final ventaja = fm['ventaja']?.toString().toUpperCase() ?? '';
        Color badgeColor;
        String badgeText;
        if (ventaja == 'LOCAL') {
          badgeColor = kAccent;
          badgeText = '🔥';
        } else if (ventaja == 'VISITANTE') {
          badgeColor = kAccent2;
          badgeText = '✅';
        } else {
          badgeColor = kMuted;
          badgeText = '—';
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Expanded(flex: 3,
                child: Text(fm['factor']?.toString() ?? '?',
                    style: GoogleFonts.dmSans(fontSize: 12, color: kText))),
            Expanded(flex: 2,
                child: Text(fm['local']?.toString() ?? '—',
                    style: GoogleFonts.dmSans(fontSize: 11, color: kMuted))),
            Expanded(flex: 2,
                child: Text(fm['visitante']?.toString() ?? '—',
                    style: GoogleFonts.dmSans(fontSize: 11, color: kMuted))),
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                  color: badgeColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(6)),
              child: Center(
                child: Text(badgeText,
                    style: TextStyle(color: badgeColor, fontSize: 13)),
              ),
            ),
          ]),
        );
      }),
    ]);
  }
}

class _PicksSection extends StatelessWidget {
  final List picks;
  const _PicksSection({required this.picks});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: picks.asMap().entries.map((e) {
        final p = e.value as Map;
        final isMain = e.key == 0;
        final conf = p['confianza']?.toString().toUpperCase() ?? '';
        final confColor = conf == 'ALTA' ? kGreen : conf == 'MEDIA' ? kGold : kMuted;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kSurface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isMain ? kAccent.withAlpha(60) : kBorder,
            ),
            gradient: isMain
                ? LinearGradient(colors: [
                    kAccent.withAlpha(15),
                    Colors.transparent,
                  ])
                : null,
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['tipo']?.toString().toUpperCase() ?? 'PICK',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 9, color: isMain ? kAccent : kMuted, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text(p['pick']?.toString() ?? '—',
                  style: GoogleFonts.bebasNeue(fontSize: 17, color: kText, letterSpacing: 1)),
              if ((p['razon'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(p['razon'].toString(),
                    style: GoogleFonts.dmSans(fontSize: 11, color: kMuted, height: 1.4)),
              ],
            ])),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: confColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: confColor.withAlpha(80))),
              child: Text(conf,
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 10, color: confColor, fontWeight: FontWeight.w700)),
            ),
          ]),
        );
      }).toList(),
    );
  }
}

class _AnguloCard extends StatelessWidget {
  final String angulo;
  const _AnguloCard({required this.angulo});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          kAccent.withAlpha(15),
          kAccent3.withAlpha(10),
        ]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kAccent.withAlpha(50)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('💡', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Text('ÁNGULO DIFERENCIADOR',
              style: GoogleFonts.bebasNeue(
                  fontSize: 17, color: kAccent, letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 10),
        Text(angulo,
            style: GoogleFonts.dmSans(
                fontSize: 13, color: kText, height: 1.65)),
      ]),
    );
  }
}

class _DisclaimerSection extends StatelessWidget {
  final List fuentes;
  const _DisclaimerSection({required this.fuentes});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: kSurface2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('FUENTES',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 9, color: kMuted, letterSpacing: 1.5)),
          const SizedBox(height: 6),
          ...fuentes.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text('· ${f.toString()}',
                style: GoogleFonts.dmSans(fontSize: 11, color: kMuted)),
          )),
        ]),
      ),
      const SizedBox(height: 12),
      Text(
        '⚠️ ANÁLISIS IA · VERIFICA ANTES DE APOSTAR',
        style: GoogleFonts.jetBrainsMono(
            fontSize: 9, color: kMuted.withAlpha(150), letterSpacing: 1.5),
      ),
    ]);
  }
}
