import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/picks_model.dart';
import '../providers/auth_provider.dart';

class PicksScreen extends StatefulWidget {
  const PicksScreen({super.key});

  @override
  State<PicksScreen> createState() => _PicksScreenState();
}

class _PicksScreenState extends State<PicksScreen> {
  PicksDelDia? _data;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final token = context.read<AuthProvider>().token;
      final data = await ApiClient(token: token).get('/api/picks/today');
      if (mounted) {
        setState(() {
          _data = PicksDelDia.fromJson(data as Map<String, dynamic>);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _failed = true; });
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
            const Text('🎯', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text('PICKS DEL DÍA', style: bebasNeue(20, letterSpacing: 1.5)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAccent))
          : _failed
              ? _errorState()
              : RefreshIndicator(
                  color: kAccent,
                  onRefresh: _fetch,
                  child: _content(),
                ),
    );
  }

  Widget _errorState() => ListView(children: [
        const SizedBox(height: 120),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 48),
        const SizedBox(height: 12),
        Center(child: Text('No se pudieron cargar los picks', style: dmSans(14, color: kMuted))),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: _fetch,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reintentar'),
          ),
        ),
      ]);

  Widget _content() {
    final d = _data!;
    final hayPicks = d.fija.jugadas.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
      children: [
        // Resumen
        Text('${d.juegosAnalizados} juegos analizados hoy',
            style: dmSans(12, color: kMuted)),
        const SizedBox(height: 10),

        // Estado del día (completo / parcial con su explicación)
        if (d.esParcial && d.mensajeHorario != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kGold.withValues(alpha: 0.4)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.access_time_rounded, color: kGold, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('PICK PARCIAL', style: bebasNeue(14, color: kGold, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(d.mensajeHorario!, style: dmSans(12, color: kText)),
              ])),
            ]),
          ),
          const SizedBox(height: 14),
        ] else if (!d.esParcial) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kGreen.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.verified_rounded, color: kGreen, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('Pick del Día completo — la jornada fuerte está activa',
                  style: dmSans(12, color: kText))),
            ]),
          ),
          const SizedBox(height: 14),
        ],

        if (!hayPicks)
          _sinPicks()
        else ...[
          // Cada nivel solo aparece si tiene sus patas COMPLETAS.
          // 1 juego → solo La Fija. 2 → +Dupleta. 3 → +Tripleta. 4+ → +Combinada.
          if (d.fija.completo)
            _tierCard('LA FIJA', '⭐', kGold, d.fija,
                'La jugada más segura del día'),
          if (d.dupleta.completo) ...[
            const SizedBox(height: 12),
            _tierCard('DUPLETA', '🔗', kAccent3, d.dupleta,
                'Las 2 más fuertes combinadas'),
          ],
          if (d.tripleta.completo) ...[
            const SizedBox(height: 12),
            _tierCard('TRIPLETA', '🔥', kAccent, d.tripleta,
                'Las 3 más fuertes combinadas'),
          ],
          // La combinada grande solo si aporta sobre la tripleta (4+ juegos).
          if (d.pickMaxN >= 4) ...[
            const SizedBox(height: 12),
            _tierCard(
                d.pickMaxN >= 7 ? 'PICK DE 7' : 'COMBINADA DE ${d.pickMaxN}',
                '💰', kGreen, d.pick7,
                d.pickMaxN >= 7
                    ? 'Alto premio — la grande del día'
                    : 'Combinada con los juegos disponibles ahora'),
          ],
        ],

        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kBorder),
          ),
          child: Text(
            'Ninguna jugada es 100% segura. Estos picks son los de mayor '
            'probabilidad según el análisis — verifica siempre antes de apostar. '
            'Cuantas más patas tenga la combinada, mayor el premio pero menor la '
            'probabilidad de acertar todas.',
            style: dmSans(11, color: kMuted),
          ),
        ),
      ],
    );
  }

  Widget _sinPicks() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Column(children: [
          const Text('🕐', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          Text('Sin picks disponibles ahora',
              style: bebasNeue(18, color: kText), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            'Los juegos del día ya comenzaron o aún no hay suficientes partidos '
            'programados. Vuelve más tarde para el pick de la próxima jornada.',
            style: dmSans(12, color: kMuted),
            textAlign: TextAlign.center,
          ),
        ]),
      );

  Widget _tierCard(String titulo, String emoji, Color color, PickTier tier, String sub) {
    if (tier.jugadas.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.18), Colors.transparent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(titulo, style: bebasNeue(20, color: color, letterSpacing: 1)),
                  Text(sub, style: dmSans(10, color: kMuted)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${tier.probabilidadCombinada.toStringAsFixed(0)}%',
                    style: bebasNeue(24, color: color)),
                Text('probabilidad', style: jetMono(8, color: kMuted, weight: FontWeight.w700)),
              ]),
            ]),
          ),
          Container(height: 1, color: kBorder),
          // Legs
          ...tier.jugadas.asMap().entries.map((e) {
            final last = e.key == tier.jugadas.length - 1;
            final j = e.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                border: last ? null : const Border(bottom: BorderSide(color: kBorder)),
              ),
              child: Row(children: [
                Text(j.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(j.seleccion,
                        style: dmSans(13, color: kText, weight: FontWeight.w600)),
                    Text('${j.enfrentamiento}  ·  ${j.liga}',
                        style: dmSans(10, color: kMuted)),
                  ]),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${j.probabilidad.toStringAsFixed(0)}%',
                      style: jetMono(12, color: kGreen, weight: FontWeight.w700)),
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }
}
