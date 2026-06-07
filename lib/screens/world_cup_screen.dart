import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../core/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modelos ligeros
// ─────────────────────────────────────────────────────────────────────────────

class _Standing {
  final String team;
  final int played, won, drawn, lost, gf, ga, gd, pts;

  const _Standing({
    required this.team,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.gf,
    required this.ga,
    required this.gd,
    required this.pts,
  });

  factory _Standing.fromJson(Map<String, dynamic> j) => _Standing(
        team: j['team'] as String? ?? '',
        played: (j['played'] as num?)?.toInt() ?? 0,
        won: (j['won'] as num?)?.toInt() ?? 0,
        drawn: (j['drawn'] as num?)?.toInt() ?? 0,
        lost: (j['lost'] as num?)?.toInt() ?? 0,
        gf: (j['gf'] as num?)?.toInt() ?? 0,
        ga: (j['ga'] as num?)?.toInt() ?? 0,
        gd: (j['gd'] as num?)?.toInt() ?? 0,
        pts: (j['pts'] as num?)?.toInt() ?? 0,
      );
}

class _Match {
  final int id;
  final String home, away, kickoff, status;
  final int? homeScore, awayScore;

  const _Match({
    required this.id,
    required this.home,
    required this.away,
    required this.kickoff,
    required this.status,
    this.homeScore,
    this.awayScore,
  });

  factory _Match.fromJson(Map<String, dynamic> j) => _Match(
        id: (j['id'] as num?)?.toInt() ?? 0,
        home: j['home'] as String? ?? '',
        away: j['away'] as String? ?? '',
        kickoff: j['kickoff'] as String? ?? '',
        status: j['status'] as String? ?? 'NS',
        homeScore: (j['home_score'] as num?)?.toInt(),
        awayScore: (j['away_score'] as num?)?.toInt(),
      );
}

class _GroupData {
  final List<_Standing> standings;
  final List<_Match> matches;

  const _GroupData({required this.standings, required this.matches});
}

// ─────────────────────────────────────────────────────────────────────────────
// Pantalla principal
// ─────────────────────────────────────────────────────────────────────────────

class WorldCupScreen extends StatefulWidget {
  const WorldCupScreen({super.key});

  @override
  State<WorldCupScreen> createState() => _WorldCupScreenState();
}

class _WorldCupScreenState extends State<WorldCupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // Estado de carga
  bool _loading = true;
  String? _error;
  Map<String, _GroupData> _groups = {};

  // Orden de grupos fijo — se filtra con los que vengan del API
  static const _groupLetters = [
    'A', 'B', 'C', 'D', 'E', 'F',
    'G', 'H', 'I', 'J', 'K', 'L',
  ];

  List<String> get _availableGroups =>
      _groupLetters.where((g) => _groups.containsKey(g)).toList();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _groupLetters.length, vsync: this);
    _fetchGroups();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _fetchGroups() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('$kBaseUrl/api/copa-mundial/groups');
      final resp = await http.get(uri).timeout(const Duration(seconds: 15));

      if (resp.statusCode != 200) {
        throw Exception('Error ${resp.statusCode}');
      }

      final decoded = json.decode(resp.body) as Map<String, dynamic>;
      final raw = decoded['groups'] as Map<String, dynamic>;

      final parsed = <String, _GroupData>{};
      raw.forEach((letter, data) {
        final d = data as Map<String, dynamic>;
        parsed[letter] = _GroupData(
          standings: (d['standings'] as List<dynamic>? ?? [])
              .map((s) => _Standing.fromJson(s as Map<String, dynamic>))
              .toList(),
          matches: (d['matches'] as List<dynamic>? ?? [])
              .map((m) => _Match.fromJson(m as Map<String, dynamic>))
              .toList(),
        );
      });

      setState(() {
        _groups = parsed;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo cargar la información.\n$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚽', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              'COPA DEL MUNDO 2026',
              style: bebasNeue(20, color: kText, letterSpacing: 1.5),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: kAccent,
          indicatorWeight: 2.5,
          labelColor: kAccent,
          unselectedLabelColor: kMuted,
          labelStyle: jetMono(11, color: kAccent, weight: FontWeight.w700),
          unselectedLabelStyle: jetMono(11, color: kMuted),
          tabs: _groupLetters
              .map((g) => Tab(text: 'GRP $g'))
              .toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAccent))
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _fetchGroups)
              : TabBarView(
                  controller: _tabs,
                  children: _groupLetters.map((letter) {
                    final data = _groups[letter];
                    if (data == null) {
                      return _EmptyGroup(letter: letter);
                    }
                    return _GroupTab(letter: letter, data: data);
                  }).toList(),
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab de un grupo
// ─────────────────────────────────────────────────────────────────────────────

class _GroupTab extends StatelessWidget {
  final String letter;
  final _GroupData data;

  const _GroupTab({required this.letter, required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // ── Encabezado del grupo ─────────────────────────────────────────────
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kAccent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                letter,
                style: bebasNeue(16, color: Colors.black),
              ),
            ),
            const SizedBox(width: 10),
            Text('GRUPO $letter', style: bebasNeue(18, color: kText)),
          ],
        ),
        const SizedBox(height: 12),

        // ── Tabla de posiciones ──────────────────────────────────────────────
        _StandingsTable(standings: data.standings),

        const SizedBox(height: 20),

        // ── Partidos del grupo ───────────────────────────────────────────────
        if (data.matches.isNotEmpty) ...[
          Text('PARTIDOS', style: bebasNeue(14, color: kMuted, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          ...data.matches.map((m) => _MatchRow(match: m)),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tabla de posiciones
// ─────────────────────────────────────────────────────────────────────────────

class _StandingsTable extends StatelessWidget {
  final List<_Standing> standings;

  const _StandingsTable({required this.standings});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          // Cabecera
          _TableHeader(),
          const Divider(height: 1, color: kBorder),
          // Filas
          ...standings.asMap().entries.map((e) {
            final pos = e.key + 1;
            final s = e.value;
            return Column(
              children: [
                _StandingRow(pos: pos, standing: s),
                if (pos < standings.length)
                  const Divider(height: 1, color: kBorder),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Pos + Equipo
          const SizedBox(width: 24), // pos number space
          Expanded(
            child: Text('EQUIPO',
                style: jetMono(10, color: kMuted, weight: FontWeight.w700)),
          ),
          _HeaderCell('J'),
          _HeaderCell('G'),
          _HeaderCell('E'),
          _HeaderCell('P'),
          _HeaderCell('GF'),
          _HeaderCell('GA'),
          _HeaderCell('PTS'),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: jetMono(10, color: kMuted, weight: FontWeight.w700),
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  final int pos;
  final _Standing standing;

  const _StandingRow({required this.pos, required this.standing});

  Color get _posColor {
    if (pos <= 2) return kGreen;
    return kMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$pos',
              style: jetMono(12, color: _posColor, weight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              standing.team,
              style: dmSans(13, color: kText, weight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _DataCell(standing.played.toString()),
          _DataCell(standing.won.toString()),
          _DataCell(standing.drawn.toString()),
          _DataCell(standing.lost.toString()),
          _DataCell(standing.gf.toString()),
          _DataCell(standing.ga.toString()),
          _DataCell(
            standing.pts.toString(),
            bold: true,
            color: standing.pts > 0 ? kAccent : kText,
          ),
        ],
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String value;
  final bool bold;
  final Color? color;

  const _DataCell(this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: jetMono(
          12,
          color: color ?? kText,
          weight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fila de partido
// ─────────────────────────────────────────────────────────────────────────────

class _MatchRow extends StatelessWidget {
  final _Match match;

  const _MatchRow({required this.match});

  DateTime get _localTime {
    try {
      return DateTime.parse(match.kickoff).toUtc().toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  String get _timeLabel {
    final dt = _localTime;
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _dateLabel {
    final dt = _localTime;
    const months = [
      '', 'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'
    ];
    return '${dt.day} ${months[dt.month]}';
  }

  String get _statusLabel {
    switch (match.status) {
      case 'FT':
        return 'FIN';
      case 'NS':
        return _timeLabel;
      case 'LIVE':
      case '1H':
      case '2H':
      case 'ET':
        return 'EN VIVO';
      default:
        return match.status;
    }
  }

  Color get _statusColor {
    switch (match.status) {
      case 'FT':
        return kMuted;
      case 'LIVE':
      case '1H':
      case '2H':
      case 'ET':
        return kGreen;
      default:
        return kAccent;
    }
  }

  bool get _hasScore =>
      match.homeScore != null && match.awayScore != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          // Fecha
          SizedBox(
            width: 42,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_dateLabel,
                    style: jetMono(10, color: kMuted)),
                const SizedBox(height: 2),
                Text(
                  _statusLabel,
                  style: jetMono(11, color: _statusColor,
                      weight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Equipo local
          Expanded(
            child: Text(
              match.home,
              style: dmSans(13, color: kText, weight: FontWeight.w600),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          // Marcador o separador
          _hasScore
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${match.homeScore}',
                      style: jetMono(15, color: kText, weight: FontWeight.w700),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Text('–',
                          style: jetMono(13, color: kMuted)),
                    ),
                    Text(
                      '${match.awayScore}',
                      style: jetMono(15, color: kText, weight: FontWeight.w700),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('vs',
                      style: jetMono(11, color: kMuted)),
                ),
          const SizedBox(width: 10),
          // Equipo visitante
          Expanded(
            child: Text(
              match.away,
              style: dmSans(13, color: kText, weight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estados vacío y error
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyGroup extends StatelessWidget {
  final String letter;
  const _EmptyGroup({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚽', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text('GRUPO $letter', style: bebasNeue(18, color: kMuted)),
          const SizedBox(height: 6),
          Text('Sin datos disponibles',
              style: dmSans(14, color: kMuted)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined, color: kMuted, size: 52),
            const SizedBox(height: 16),
            Text(
              message,
              style: dmSans(14, color: kMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
