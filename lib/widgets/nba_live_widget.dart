import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/match_model.dart';
import '../providers/auth_provider.dart';

/// Vista en vivo de básquet (NBA/WNBA): marcador, cuarto + reloj y jugada por
/// jugada en tiempo real (datos de ESPN). Cancha estilizada de fondo.
class NbaLiveWidget extends StatefulWidget {
  final MatchModel match;
  const NbaLiveWidget({super.key, required this.match});

  @override
  State<NbaLiveWidget> createState() => _NbaLiveWidgetState();
}

class _NbaLiveWidgetState extends State<NbaLiveWidget> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _failed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetch();
    // Refrescar cada 20s mientras la pantalla esté abierta
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final token = context.read<AuthProvider>().token;
      final d = await ApiClient(token: token)
          .get('/api/matches/${widget.match.id}/live-nba');
      if (mounted) {
        setState(() {
          _data = d as Map<String, dynamic>;
          _loading = false;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _failed = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: kAccent)),
      );
    }
    if (_failed || _data == null) {
      return Padding(
        padding: const EdgeInsets.all(30),
        child: Center(child: Text('No se pudo cargar el juego en vivo',
            style: dmSans(13, color: kMuted))),
      );
    }
    final d = _data!;
    final state = d['state'] as String? ?? 'pre';
    final plays = (d['last_plays'] as List?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _marcador(d, state),
        const SizedBox(height: 14),
        if (state == 'pre')
          _preJuego()
        else ...[
          Text('JUGADA POR JUGADA', style: jetMono(11, color: kMuted, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (plays.isEmpty)
            Text('Sin jugadas todavía', style: dmSans(12, color: kMuted))
          else
            ...plays.map((p) => _jugada(p as Map<String, dynamic>, d)),
        ],
      ],
    );
  }

  Widget _marcador(Map<String, dynamic> d, String state) {
    final enVivo = state == 'in';
    final home = (d['home_team'] ?? '').toString().split(' ').last;
    final away = (d['away_team'] ?? '').toString().split(' ').last;
    final hs = d['home_score'] ?? 0;
    final as_ = d['away_score'] ?? 0;
    final label = d['periodo_label'] ?? '';
    final reloj = (d['reloj'] ?? '').toString();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Fondo estilizado de cancha (líneas decorativas)
        gradient: const LinearGradient(
          colors: [Color(0xFF1a1410), Color(0xFF14110a)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(children: [
        // Estado / reloj
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (enVivo) ...[
            Container(width: 8, height: 8, decoration: const BoxDecoration(
                shape: BoxShape.circle, color: kGreen)),
            const SizedBox(width: 6),
          ],
          Text(
            enVivo ? '$label  ·  $reloj' : (label.toString().toUpperCase()),
            style: bebasNeue(16, color: enVivo ? kGreen : kMuted, letterSpacing: 1),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _equipo('🏀', away, as_)),
          Text('VS', style: bebasNeue(16, color: kMuted)),
          Expanded(child: _equipo('🏀', home, hs)),
        ]),
      ]),
    );
  }

  Widget _equipo(String emoji, String nombre, dynamic score) {
    return Column(children: [
      Text(nombre.toUpperCase(),
          style: bebasNeue(16, color: kText, letterSpacing: 0.5),
          textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 4),
      Text('$score', style: GoogleFonts.bebasNeue(fontSize: 46, color: kAccent, height: 1)),
    ]);
  }

  Widget _preJuego() => Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Column(children: [
          const Text('🏀', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text('El juego aún no comienza',
              style: dmSans(13, color: kMuted), textAlign: TextAlign.center),
        ]),
      );

  Widget _jugada(Map<String, dynamic> p, Map<String, dynamic> d) {
    final anota = p['anota'] == true;
    final texto = (p['texto'] ?? '').toString();
    final per = p['periodo'];
    final reloj = (p['reloj'] ?? '').toString();
    final hs = p['home_score'];
    final as_ = p['away_score'];
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: anota ? kAccent.withValues(alpha: 0.10) : kSurface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: anota ? kAccent.withValues(alpha: 0.4) : kBorder),
      ),
      child: Row(children: [
        SizedBox(
          width: 46,
          child: Text(per != null ? '${per}Q $reloj' : reloj,
              style: jetMono(9, color: kMuted)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(texto,
              style: dmSans(12, color: kText,
                  weight: anota ? FontWeight.w700 : FontWeight.w400)),
        ),
        if (hs != null && as_ != null) ...[
          const SizedBox(width: 8),
          Text('$as_-$hs', style: jetMono(11, color: anota ? kAccent : kMuted, weight: FontWeight.w700)),
        ],
      ]),
    );
  }
}
