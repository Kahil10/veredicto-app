import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/match_model.dart';
import '../providers/auth_provider.dart';

/// Vista en vivo de fútbol: marcador, minuto real, y línea de eventos
/// (goles ⚽, tarjetas 🟨🟥, cambios 🔄) en tiempo real (datos de ESPN).
/// Cancha estilizada de fondo. Datos reales — no se inventa nada.
class SoccerLiveWidget extends StatefulWidget {
  final MatchModel match;
  const SoccerLiveWidget({super.key, required this.match});

  @override
  State<SoccerLiveWidget> createState() => _SoccerLiveWidgetState();
}

class _SoccerLiveWidgetState extends State<SoccerLiveWidget> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _failed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetch();
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
          .get('/api/matches/${widget.match.id}/live-soccer');
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
    final feed = d['feed_available'] == true;
    final eventos = (d['eventos'] as List?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _marcador(d, state),
        const SizedBox(height: 14),
        if (state == 'pre')
          _preJuego()
        else if (!feed)
          _sinFeed()
        else ...[
          Text('INCIDENCIAS', style: jetMono(11, color: kMuted, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (eventos.isEmpty)
            Text('Sin incidencias todavía', style: dmSans(12, color: kMuted))
          else
            ...eventos.map((e) => _evento(e as Map<String, dynamic>)),
        ],
      ],
    );
  }

  Widget _marcador(Map<String, dynamic> d, String state) {
    final enVivo = state == 'in';
    final home = (d['home_team'] ?? '').toString();
    final away = (d['away_team'] ?? '').toString();
    final hs = d['home_score'] ?? 0;
    final as_ = d['away_score'] ?? 0;
    final label = (d['periodo_label'] ?? '').toString();
    final minuto = (d['minuto'] ?? '').toString();
    final estado = enVivo
        ? (minuto.isNotEmpty ? "$minuto'  ·  $label" : label)
        : label.toUpperCase();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Fondo estilizado de cancha (verde césped)
        gradient: const LinearGradient(
          colors: [Color(0xFF0e2b16), Color(0xFF0a1f10)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (enVivo) ...[
            Container(width: 8, height: 8, decoration: const BoxDecoration(
                shape: BoxShape.circle, color: kGreen)),
            const SizedBox(width: 6),
          ],
          Text(estado,
              style: bebasNeue(16, color: enVivo ? kGreen : kMuted, letterSpacing: 1)),
        ]),
        const SizedBox(height: 12),
        // Convención de la app: visitante a la izquierda, local a la derecha
        Row(children: [
          Expanded(child: _equipo(away, as_)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('-', style: GoogleFonts.bebasNeue(fontSize: 40, color: kMuted)),
          ),
          Expanded(child: _equipo(home, hs)),
        ]),
      ]),
    );
  }

  Widget _equipo(String nombre, dynamic score) {
    return Column(children: [
      const Text('⚽', style: TextStyle(fontSize: 22)),
      const SizedBox(height: 4),
      Text(nombre.toUpperCase(),
          style: bebasNeue(15, color: kText, letterSpacing: 0.5),
          textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2),
      Text('$score', style: GoogleFonts.bebasNeue(fontSize: 44, color: kAccent, height: 1)),
    ]);
  }

  Widget _preJuego() => Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Column(children: [
          const Text('⚽', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text('El partido aún no comienza',
              style: dmSans(13, color: kMuted), textAlign: TextAlign.center),
        ]),
      );

  Widget _sinFeed() => Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Column(children: [
          const Text('📺', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text('Incidencias en vivo no disponibles para este partido',
              style: dmSans(12, color: kMuted), textAlign: TextAlign.center),
        ]),
      );

  static const Map<String, String> _iconos = {
    'gol': '⚽', 'amarilla': '🟨', 'roja': '🟥',
    'cambio': '🔄', 'penal_fallado': '❌', 'otro': '📋',
  };

  Widget _evento(Map<String, dynamic> e) {
    final clase = (e['clase'] ?? 'otro').toString();
    final esGol = clase == 'gol';
    final icono = _iconos[clase] ?? '📋';
    final minuto = (e['minuto'] ?? '').toString();
    final texto = (e['texto'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: esGol ? kAccent.withValues(alpha: 0.10) : kSurface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: esGol ? kAccent.withValues(alpha: 0.4) : kBorder),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 40,
          child: Text(minuto.isNotEmpty ? "$minuto'" : '',
              style: jetMono(11, color: esGol ? kAccent : kMuted, weight: FontWeight.w700)),
        ),
        Text(icono, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(texto,
              style: dmSans(12.5, color: kText,
                  weight: esGol ? FontWeight.w700 : FontWeight.w400)),
        ),
      ]),
    );
  }
}
