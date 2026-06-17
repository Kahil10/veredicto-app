import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/picks_model.dart';
import '../providers/auth_provider.dart';
import 'guia_screen.dart';

class PicksScreen extends StatefulWidget {
  const PicksScreen({super.key});

  @override
  State<PicksScreen> createState() => _PicksScreenState();
}

class _PicksScreenState extends State<PicksScreen> {
  PicksDelDia? _data;
  Map<String, dynamic>? _record;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _abrirGuia() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const GuiaScreen(),
      fullscreenDialog: true,
    ));
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final token = context.read<AuthProvider>().token;
      final api = ApiClient(token: token);
      final data = await api.get('/api/picks/today');
      Map<String, dynamic>? rec;
      try {
        rec = await api.get('/api/picks/record') as Map<String, dynamic>;
      } catch (_) {}
      if (mounted) {
        setState(() {
          _data = PicksDelDia.fromJson(data as Map<String, dynamic>);
          _record = rec;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Cómo usar',
            onPressed: _abrirGuia,
          ),
        ],
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

        // Track record (credibilidad)
        if (_record != null) ...[
          _recordCard(_record!),
          const SizedBox(height: 14),
        ],

        // ── CASO 1: no quedan juegos hoy ────────────────────────────────────
        if (d.esSinJuegos)
          _mensajeFin('🕐', 'No hay juegos por jugar hoy', d.mensajeHorario)

        // ── CASO 2: pocos juegos (1-4) → analiza a tu criterio ──────────────
        else if (d.esPocos) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kAccent3.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kAccent3.withValues(alpha: 0.4)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.search_rounded, color: kAccent3, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('POCOS JUEGOS DISPONIBLES',
                    style: bebasNeue(14, color: kAccent3, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(d.mensajeHorario ?? '', style: dmSans(12, color: kText)),
              ])),
            ]),
          ),
          const SizedBox(height: 14),
          ...d.juegosRestantes.map((j) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _juegoRestante(j),
              )),
        ]

        // ── CASO 3: pick normal (completo o parcial) ────────────────────────
        else ...[
          if (d.esParcial) ...[
            _banner(kGold, Icons.access_time_rounded, 'PICK PARCIAL', d.mensajeHorario),
            const SizedBox(height: 14),
          ] else ...[
            _banner(kGreen, Icons.verified_rounded, 'PICK DEL DÍA COMPLETO',
                'La jornada fuerte está activa — este es nuestro mejor pronóstico.'),
            const SizedBox(height: 14),
          ],
          if (d.veredicto.patas.isNotEmpty) ...[
            // ── "El Veredicto del Día" (estructura nueva) ──────────────────
            if (d.seguro != null) ...[
              _seguroCard(d.seguro!),
              const SizedBox(height: 12),
            ],
            _nivelCard('EL VEREDICTO', '🎯', kAccent, d.veredicto,
                'Tu pick estrella — a ganar, con refuerzos opcionales',
                mostrarOpcionales: true),
            if (d.atrevido.patas.length > d.veredicto.patas.length) ...[
              const SizedBox(height: 12),
              _nivelCard('EL ATREVIDO', '🚀', kGreen, d.atrevido,
                  'Parley grande — alto premio, mezcla deportes',
                  mostrarOpcionales: false),
            ],
          ] else if (!hayPicks)
            _mensajeFin('🤔', 'No hay jugadas de alta confianza ahora', d.mensajeHorario)
          else ...[
            // Fallback: estructura anterior (por compatibilidad)
            if (d.fija.completo)
              _tierCard('LA FIJA', '⭐', kGold, d.fija,
                  'La jugada más segura del día'),
            if (d.tripleta.completo) ...[
              const SizedBox(height: 12),
              _tierCard('TRIPLETA', '🔥', kAccent, d.tripleta,
                  'Las 3 más fuertes combinadas'),
            ],
            if (d.pickMaxN >= 4) ...[
              const SizedBox(height: 12),
              _tierCard(
                  d.pickMaxN >= 7 ? 'PICK DE 7' : 'COMBINADA DE ${d.pickMaxN}',
                  '💰', kGreen, d.pick7,
                  'Alto premio — la grande del día'),
            ],
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

  // Tarjeta de historial de aciertos (track record) — credibilidad
  Widget _recordCard(Map<String, dynamic> rec) {
    final fija = (rec['fija'] ?? {}) as Map<String, dynamic>;
    final general = (rec['general'] ?? {}) as Map<String, dynamic>;
    final fijaTotal = (fija['total'] as num?)?.toInt() ?? 0;
    final genTotal = (general['total'] as num?)?.toInt() ?? 0;
    final ultimas = (rec['ultimas_fijas'] as List?) ?? [];

    // Si aún no hay nada evaluado, mostrar mensaje de "construyéndose"
    if (fijaTotal == 0 && genTotal == 0) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Row(children: [
          const Icon(Icons.insights_rounded, color: kAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(
            'Historial de aciertos en construcción — se actualiza al terminar '
            'los juegos de cada día.',
            style: dmSans(11, color: kMuted),
          )),
        ]),
      );
    }

    Widget stat(String label, Map<String, dynamic> a, Color color) {
      final ac = (a['aciertos'] as num?)?.toInt() ?? 0;
      final tot = (a['total'] as num?)?.toInt() ?? 0;
      final pct = (a['pct'] as num?)?.toDouble() ?? 0;
      return Column(children: [
        Text(label, style: jetMono(9, color: kMuted, weight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('${pct.toStringAsFixed(0)}%', style: bebasNeue(26, color: color)),
        Text('$ac de $tot', style: dmSans(10, color: kMuted)),
      ]);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGreen.withValues(alpha: 0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.military_tech_rounded, color: kGreen, size: 18),
          const SizedBox(width: 8),
          Text('HISTORIAL DE ACIERTOS', style: bebasNeue(15, color: kGreen, letterSpacing: 1)),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          stat('LA FIJA', fija, kGold),
          Container(width: 1, height: 44, color: kBorder),
          stat('GENERAL', general, kAccent),
        ]),
        if (ultimas.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('ÚLTIMAS FIJAS', style: jetMono(8, color: kMuted, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(spacing: 5, runSpacing: 5, children: ultimas.take(10).map<Widget>((u) {
            final ok = u['resultado'] == 'acierto';
            return Container(
              width: 22, height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (ok ? kGreen : kRed).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: (ok ? kGreen : kRed).withValues(alpha: 0.5)),
              ),
              child: Text(ok ? '✓' : '✗',
                  style: TextStyle(color: ok ? kGreen : kRed, fontSize: 12, fontWeight: FontWeight.w800)),
            );
          }).toList()),
        ],
      ]),
    );
  }

  Widget _mensajeFin(String emoji, String titulo, String? cuerpo) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          Text(titulo, style: bebasNeue(18, color: kText), textAlign: TextAlign.center),
          if (cuerpo != null) ...[
            const SizedBox(height: 6),
            Text(cuerpo, style: dmSans(12, color: kMuted), textAlign: TextAlign.center),
          ],
        ]),
      );

  Widget _banner(Color color, IconData icon, String titulo, String? texto) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: bebasNeue(14, color: color, letterSpacing: 1)),
            if (texto != null) ...[
              const SizedBox(height: 2),
              Text(texto, style: dmSans(12, color: kText)),
            ],
          ])),
        ]),
      );

  // Tarjeta simple de un juego restante (modo "pocos juegos", a criterio del usuario)
  Widget _juegoRestante(PickLeg j) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBorder),
        ),
        child: Row(children: [
          Text(j.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(j.seleccion, style: dmSans(13, color: kText, weight: FontWeight.w600)),
              Text('${j.enfrentamiento}  ·  ${j.liga}', style: dmSans(10, color: kMuted)),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: kMuted.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('${j.probabilidad.toStringAsFixed(0)}%',
                style: jetMono(12, color: kMuted, weight: FontWeight.w700)),
          ),
        ]),
      );

  // 🔒 El Seguro: la jugada más fija del día, destacada con su razón.
  Widget _seguroCard(PickLeg s) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kGold.withValues(alpha: 0.18), kSurface],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kGold.withValues(alpha: 0.5)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('🔒', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('EL SEGURO', style: bebasNeue(20, color: kGold, letterSpacing: 1.5)),
            const Spacer(),
            Text('${s.probabilidad.toStringAsFixed(0)}%', style: bebasNeue(28, color: kGold)),
          ]),
          const SizedBox(height: 2),
          Text('La jugada más fija del día', style: dmSans(10, color: kMuted)),
          const SizedBox(height: 10),
          Row(children: [
            Text(s.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(child: Text(s.seleccion,
                style: dmSans(15, color: kText, weight: FontWeight.w700))),
          ]),
          const SizedBox(height: 3),
          Text('${s.enfrentamiento}  ·  ${s.liga}', style: dmSans(11, color: kMuted)),
          if (s.razon != null && s.razon!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lightbulb_outline_rounded, size: 13, color: kGold),
              const SizedBox(width: 5),
              Expanded(child: Text(s.razon!,
                  style: dmSans(11.5, color: kGold, weight: FontWeight.w500))),
            ]),
          ],
        ]),
      );

  // Nivel (El Veredicto / El Atrevido): header con combinada + lista de núcleos.
  Widget _nivelCard(String titulo, String emoji, Color color,
      VeredictoNivel nivel, String sub, {required bool mostrarOpcionales}) {
    if (nivel.patas.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.18), Colors.transparent],
              begin: Alignment.centerLeft, end: Alignment.centerRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titulo, style: bebasNeue(20, color: color, letterSpacing: 1)),
              Text(sub, style: dmSans(10, color: kMuted)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${nivel.probabilidadCombinada.toStringAsFixed(0)}%',
                  style: bebasNeue(24, color: color)),
              Text('combinada', style: jetMono(8, color: kMuted, weight: FontWeight.w700)),
            ]),
          ]),
        ),
        Container(height: 1, color: kBorder),
        ...nivel.patas.asMap().entries.map((e) =>
            _nucleoTile(e.value, color, last: e.key == nivel.patas.length - 1,
                mostrarOpcionales: mostrarOpcionales)),
      ]),
    );
  }

  // Una pata-núcleo: selección + enfrentamiento + lectura + refuerzos opcionales.
  Widget _nucleoTile(PickLeg n, Color color,
      {required bool last, required bool mostrarOpcionales}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(n.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(n.seleccion, style: dmSans(13.5, color: kText, weight: FontWeight.w700)),
            Text('${n.enfrentamiento}  ·  ${n.liga}', style: dmSans(10, color: kMuted)),
          ])),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: kGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('${n.probabilidad.toStringAsFixed(0)}%',
                style: jetMono(12, color: kGreen, weight: FontWeight.w700)),
          ),
        ]),
        if (n.razon != null && n.razon!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(width: 26),
            const Icon(Icons.lightbulb_outline_rounded, size: 12, color: kMuted),
            const SizedBox(width: 5),
            Expanded(child: Text(n.razon!,
                style: dmSans(11, color: kMuted, weight: FontWeight.w500))),
          ]),
        ],
        if (mostrarOpcionales && n.opcionales.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: 26),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('REFUERZOS OPCIONALES', style: jetMono(8, color: color, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              ...n.opcionales.map((o) => Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(children: [
                      const Text('➕ ', style: TextStyle(fontSize: 11)),
                      Expanded(child: Text(o.seleccion,
                          style: dmSans(11.5, color: kText))),
                      const SizedBox(width: 6),
                      Text('${o.probabilidad.toStringAsFixed(0)}%',
                          style: jetMono(10, color: kMuted, weight: FontWeight.w700)),
                    ]),
                  )),
            ]),
          ),
        ],
      ]),
    );
  }

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
