import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../core/theme.dart';
import '../models/prediction_model.dart';

class PredictionCard extends StatelessWidget {
  final PredictionModel pred;

  const PredictionCard({super.key, required this.pred});

  @override
  Widget build(BuildContext context) {
    final match = pred.match;
    final isBaseball = match.sport == 'baseball';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPurple.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.analytics_outlined,
                      color: kPurple, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Análisis Estadístico',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      Text('Bayesiano + Monte Carlo 10k',
                          style: TextStyle(color: kMuted, fontSize: 10)),
                    ],
                  ),
                ),
                _ConfidenceBadge(confidence: pred.confidence),
              ],
            ),
            const SizedBox(height: 20),

            // Probabilidades — favorito siempre primero
            Builder(builder: (_) {
              double home = pred.homeWinPct;
              double draw = isBaseball ? 0 : pred.drawPct;
              double away = pred.awayWinPct;
              if (isBaseball && (home + away) < 99) {
                final total = home + away;
                if (total > 0) {
                  home = home / total * 100;
                  away = away / total * 100;
                }
              }
              final homeFirst = home >= away;
              final favoriteLabel  = homeFirst ? match.homeTeam : match.awayTeam;
              final underdogLabel  = homeFirst ? match.awayTeam : match.homeTeam;
              final favoritePct    = homeFirst ? home : away;
              final underdogPct    = homeFirst ? away : home;
              final favoriteColor  = homeFirst ? kPurple : const Color(0xFF0ea5e9);
              final underdogColor  = homeFirst ? const Color(0xFF0ea5e9) : kPurple;
              return Column(
                children: [
                  _ProbBar(label: favoriteLabel, pct: favoritePct, color: favoriteColor),
                  if (!isBaseball) ...[
                    const SizedBox(height: 10),
                    _ProbBar(
                        label: 'Empate',
                        pct: draw,
                        color: const Color(0xFF64748b)),
                  ],
                  const SizedBox(height: 10),
                  _ProbBar(label: underdogLabel, pct: underdogPct, color: underdogColor),
                ],
              );
            }),

            const SizedBox(height: 18),
            const Divider(color: Color(0xFF2d2d4e)),
            const SizedBox(height: 14),

            // xG / xC
            Row(
              children: [
                const Icon(Icons.sports_score_outlined,
                    color: kMuted, size: 16),
                const SizedBox(width: 6),
                Text(
                  isBaseball ? 'xC esperadas (carreras):' : 'xG esperados:',
                  style: const TextStyle(color: kMuted, fontSize: 13),
                ),
                const Spacer(),
                _XgChip(
                    team: match.homeTeam, xg: pred.homeXg, color: kPurple),
                const SizedBox(width: 8),
                _XgChip(
                    team: match.awayTeam,
                    xg: pred.awayXg,
                    color: const Color(0xFF0ea5e9)),
              ],
            ),

            // Pitchers titulares (solo béisbol)
            if (isBaseball && (pred.homePitcherName != null || pred.awayPitcherName != null)) ...[
              const SizedBox(height: 18),
              const Divider(color: Color(0xFF2d2d4e)),
              const SizedBox(height: 14),
              _PitcherSection(pred: pred),
            ],

            // Head-to-Head (solo béisbol)
            if (isBaseball && pred.h2hJuegos != null && pred.h2hJuegos! >= 2) ...[
              const SizedBox(height: 18),
              const Divider(color: Color(0xFF2d2d4e)),
              const SizedBox(height: 14),
              _H2HSection(pred: pred),
            ],

            // Over/Under (solo béisbol)
            if (isBaseball && pred.ouLine != null) ...[
              const SizedBox(height: 18),
              const Divider(color: Color(0xFF2d2d4e)),
              const SizedBox(height: 14),
              _OUSection(pred: pred),
            ],

            // Variables usadas
            if (pred.variablesUsadas.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF22c55e).withAlpha(12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF22c55e).withAlpha(50)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            color: Color(0xFF22c55e), size: 14),
                        SizedBox(width: 6),
                        Text('Datos utilizados',
                            style: TextStyle(
                                color: Color(0xFF22c55e),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...pred.variablesUsadas.map(
                      (v) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(
                                    color: Color(0xFF22c55e), fontSize: 11)),
                            Expanded(
                              child: Text(v,
                                  style: const TextStyle(
                                      color: kMuted, fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Variables faltantes — separadas por tipo
            Builder(builder: (_) {
              final histGaps = pred.variablesFaltantes
                  .where((v) => v.contains('insuficiente') || v.contains('< 3'))
                  .toList();
              final apiLimits = pred.variablesFaltantes
                  .where((v) => !v.contains('insuficiente') && !v.contains('< 3'))
                  .toList();

              return Column(
                children: [
                  // Gaps de historial reales
                  if (histGaps.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFf59e0b).withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFf59e0b).withAlpha(60)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Color(0xFFf59e0b), size: 14),
                            SizedBox(width: 6),
                            Text('Historial limitado',
                                style: TextStyle(
                                    color: Color(0xFFf59e0b),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ]),
                          const SizedBox(height: 6),
                          ...histGaps.map((v) => Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ',
                                        style: TextStyle(
                                            color: Color(0xFFf59e0b), fontSize: 11)),
                                    Expanded(
                                        child: Text(v,
                                            style: const TextStyle(
                                                color: kMuted, fontSize: 11))),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],

                  // Limitaciones de herramientas (APIs)
                  if (apiLimits.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3b82f6).withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF3b82f6).withAlpha(50)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(children: [
                            Icon(Icons.rocket_launch_outlined,
                                color: Color(0xFF3b82f6), size: 14),
                            SizedBox(width: 6),
                            Text('En desarrollo',
                                style: TextStyle(
                                    color: Color(0xFF3b82f6),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ]),
                          const SizedBox(height: 6),
                          ...apiLimits.map((v) {
                            final label = v
                                .replaceAll(' (requiere plan pago)', '')
                                .replaceAll(' (no disponible en plan gratuito)', '');
                            return Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ',
                                      style: TextStyle(
                                          color: Color(0xFF3b82f6), fontSize: 11)),
                                  Expanded(
                                      child: Text(label,
                                          style: const TextStyle(
                                              color: kMuted, fontSize: 11))),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          const Text(
                            'Estamos expandiendo nuestras herramientas de análisis. '
                            'A medida que crezca la base de suscriptores, '
                            'invertiremos en más datos para mejorar las predicciones.',
                            style: TextStyle(
                                color: Color(0xFF3b82f6),
                                fontSize: 10,
                                height: 1.4,
                                fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ProbBar extends StatelessWidget {
  final String label;
  final double pct;
  final Color color;

  const _ProbBar(
      {required this.label, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: kText),
              overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          child: LinearPercentIndicator(
            lineHeight: 10,
            percent: (pct / 100).clamp(0.0, 1.0),
            progressColor: color,
            backgroundColor: color.withAlpha(30),
            barRadius: const Radius.circular(6),
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 42,
          child: Text('${pct.toStringAsFixed(1)}%',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color),
              textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final int confidence;
  const _ConfidenceBadge({required this.confidence});

  Color get _color {
    if (confidence >= 75) return const Color(0xFF22c55e);
    if (confidence >= 45) return const Color(0xFFf59e0b);
    return const Color(0xFFef4444);
  }

  String get _label {
    if (confidence >= 75) return 'Alta';
    if (confidence >= 45) return 'Media';
    return 'Baja';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, color: _color, size: 13),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Confianza',
                  style: TextStyle(
                      color: _color,
                      fontSize: 9,
                      fontWeight: FontWeight.w500)),
              Text(_label,
                  style: TextStyle(
                      color: _color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _XgChip extends StatelessWidget {
  final String team;
  final double xg;
  final Color color;
  const _XgChip({required this.team, required this.xg, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(xg.toStringAsFixed(2),
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          Text(team.split(' ').first,
              style: const TextStyle(color: kMuted, fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Pitchers titulares ────────────────────────────────────────────────────────

class _PitcherSection extends StatelessWidget {
  final PredictionModel pred;
  const _PitcherSection({required this.pred});

  static const _green  = Color(0xFF22c55e);
  static const _red    = Color(0xFFef4444);
  static const _yellow = Color(0xFFf59e0b);

  Color _eraColor(double? era) {
    if (era == null) return kMuted;
    if (era < 3.50) return _green;
    if (era < 4.50) return _yellow;
    return _red;
  }

  @override
  Widget build(BuildContext context) {
    final match = pred.match;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabecera
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPurple.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.sports_baseball, color: kPurple, size: 20),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pitchers titulares',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Text('Abridores confirmados por MLB',
                  style: TextStyle(color: kMuted, fontSize: 10)),
            ],
          ),
        ]),
        const SizedBox(height: 16),
        // Cards de los dos pitchers
        Row(children: [
          Expanded(child: _PitcherCard(
            teamName: match.homeTeam,
            name: pred.homePitcherName,
            era: pred.homePitcherEra,
            k9: pred.homePitcherK9,
            eraColor: _eraColor(pred.homePitcherEra),
          )),
          const SizedBox(width: 10),
          Expanded(child: _PitcherCard(
            teamName: match.awayTeam,
            name: pred.awayPitcherName,
            era: pred.awayPitcherEra,
            k9: pred.awayPitcherK9,
            eraColor: _eraColor(pred.awayPitcherEra),
          )),
        ]),
      ],
    );
  }
}

class _PitcherCard extends StatelessWidget {
  final String teamName;
  final String? name;
  final double? era;
  final double? k9;
  final Color eraColor;

  const _PitcherCard({
    required this.teamName,
    required this.name,
    required this.era,
    required this.k9,
    required this.eraColor,
  });

  // Apellido del pitcher para que quepa en la tarjeta
  String get _shortName {
    if (name == null) return 'Por confirmar';
    final parts = name!.split(' ');
    return parts.length > 1 ? parts.last : name!;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: eraColor.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: eraColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            teamName.split(' ').last,
            style: const TextStyle(color: kMuted, fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _shortName,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14, color: kText),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (era != null) ...[
            Row(children: [
              Text('ERA ', style: const TextStyle(color: kMuted, fontSize: 11)),
              Text(era!.toStringAsFixed(2),
                  style: TextStyle(
                      color: eraColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ]),
            if (k9 != null)
              Text('${k9!.toStringAsFixed(1)} K/jgo',
                  style: const TextStyle(color: kMuted, fontSize: 11)),
          ] else
            Text('Sin stats aún',
                style: const TextStyle(color: kMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Head-to-Head ─────────────────────────────────────────────────────────────

class _H2HSection extends StatelessWidget {
  final PredictionModel pred;
  const _H2HSection({required this.pred});

  @override
  Widget build(BuildContext context) {
    final n     = pred.h2hJuegos!;
    final wHome = pred.h2hVictoriasLocal ?? 0;
    final wAway = pred.h2hVictoriasVisit ?? 0;
    final rHome = pred.h2hRunsLocalAvg ?? 0;
    final rAway = pred.h2hRunsVisitAvg ?? 0;
    final home  = pred.match.homeTeam;
    final away  = pred.match.awayTeam;

    // Color del favorito histórico
    final homeWinPct = n > 0 ? wHome / n : 0.5;
    final Color homeColor = homeWinPct > 0.5
        ? kPurple
        : homeWinPct < 0.5
            ? const Color(0xFF0ea5e9)
            : kMuted;
    final Color awayColor = homeWinPct < 0.5
        ? const Color(0xFF0ea5e9)
        : homeWinPct > 0.5
            ? kPurple
            : kMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabecera
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFf59e0b).withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.history, color: Color(0xFFf59e0b), size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Head-to-Head',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Text('Últimos $n enfrentamientos directos',
                  style: const TextStyle(color: kMuted, fontSize: 10)),
            ],
          ),
        ]),
        const SizedBox(height: 16),

        // Marcador H2H
        Row(children: [
          // Local
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Text(home.split(' ').last,
                  style: const TextStyle(color: kMuted, fontSize: 11)),
              const SizedBox(height: 4),
              Text('$wHome', style: TextStyle(
                  color: homeColor, fontSize: 32, fontWeight: FontWeight.w900)),
              Text('${rHome.toStringAsFixed(1)} C/jgo',
                  style: const TextStyle(color: kMuted, fontSize: 11)),
            ]),
          ),
          // VS
          Column(children: [
            const Text('VS', style: TextStyle(
                color: kMuted, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('$n juegos', style: const TextStyle(color: kMuted, fontSize: 10)),
          ]),
          // Visitante
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Text(away.split(' ').last,
                  style: const TextStyle(color: kMuted, fontSize: 11)),
              const SizedBox(height: 4),
              Text('$wAway', style: TextStyle(
                  color: awayColor, fontSize: 32, fontWeight: FontWeight.w900)),
              Text('${rAway.toStringAsFixed(1)} C/jgo',
                  style: const TextStyle(color: kMuted, fontSize: 11)),
            ]),
          ),
        ]),
      ],
    );
  }
}

// ── Over / Under ─────────────────────────────────────────────────────────────

class _OUSection extends StatelessWidget {
  final PredictionModel pred;
  const _OUSection({required this.pred});

  static const _orange = Color(0xFFf97316);
  static const _blue   = Color(0xFF0ea5e9);
  static const _yellow = Color(0xFFf59e0b);

  @override
  Widget build(BuildContext context) {
    final over  = pred.overPct!;
    final under = pred.underPct!;
    final line  = pred.ouLine!;
    final total = pred.projectedTotal;

    final bool isAltas  = over  > 55;
    final bool isBajas  = under > 55;
    final Color accent  = isAltas ? _orange : isBajas ? _blue : _yellow;
    final String verdict = isAltas ? 'ALTAS' : isBajas ? 'BAJAS' : 'PAREJO';
    final IconData icon  = isAltas
        ? Icons.local_fire_department
        : isBajas
            ? Icons.ac_unit
            : Icons.balance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabecera
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Totales',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text('Over / Under carreras',
                      style: TextStyle(color: kMuted, fontSize: 10)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withAlpha(80)),
              ),
              child: Text(
                verdict,
                style: TextStyle(
                    color: accent, fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),
        Center(
          child: Text(
            'Línea: ${line.toStringAsFixed(1)} carreras',
            style: const TextStyle(color: kMuted, fontSize: 12),
          ),
        ),
        const SizedBox(height: 10),

        _ProbBar(
          label: 'ALTAS (>${line.toStringAsFixed(1)})',
          pct: over,
          color: _orange,
        ),
        const SizedBox(height: 8),
        _ProbBar(
          label: 'BAJAS (<${line.toStringAsFixed(1)})',
          pct: under,
          color: _blue,
        ),

        if (total != null) ...[
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Proyectado: ${total.toStringAsFixed(1)} carreras totales',
              style: const TextStyle(
                  color: kMuted, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ],
    );
  }
}
