import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../models/match_model.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../models/prediction_model.dart';
import '../providers/matches_provider.dart';
import '../widgets/prediction_card.dart';
import 'chat_screen.dart';

class MatchDetailScreen extends StatefulWidget {
  final MatchModel match;
  const MatchDetailScreen({super.key, required this.match});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      context
          .read<MatchesProvider>()
          .loadPrediction(widget.match.id, token: token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final match    = widget.match;
    final provider = context.watch<MatchesProvider>();
    final auth     = context.watch<AuthProvider>();
    final pred     = provider.prediction(match.id);
    final isPredLoading  = provider.isPredictionLoading(match.id);
    final isPaywalled    = provider.isPaywalled(match.id);
    final user           = auth.user;
    final showCounter    = user != null && user.isFree && !isPaywalled;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${match.homeTeam} vs ${match.awayTeam}',
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: kSurface,
        actions: [
          // Contador de análisis para usuarios FREE
          if (showCounter)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.analysesLeft == 0
                        ? const Color(0xFFef4444).withAlpha(30)
                        : const Color(0xFFf59e0b).withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: user.analysesLeft == 0
                          ? const Color(0xFFef4444).withAlpha(80)
                          : const Color(0xFFf59e0b).withAlpha(80),
                    ),
                  ),
                  child: Text(
                    '${user.analysesLeft}/2 hoy',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: user.analysesLeft == 0
                          ? const Color(0xFFef4444)
                          : const Color(0xFFf59e0b),
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recalcular',
            onPressed: isPredLoading
                ? null
                : () async {
                    final token = context.read<AuthProvider>().token;
                    await context
                        .read<MatchesProvider>()
                        .refreshPrediction(match.id, token: token);
                  },
          ),
        ],
      ),
      floatingActionButton: isPaywalled ? null : FloatingActionButton.extended(
        backgroundColor: kPurpleDark,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text('Vera IA',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: () {
          final pred = provider.prediction(match.id);
          final ctx = _buildVeraContext(match, pred);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider(
                create: (_) => ChatProvider(),
                child: ChatScreen(matchContext: ctx, autoAnalyze: true),
              ),
            ),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _MatchHeader(match),
            const SizedBox(height: 16),
            if (isPaywalled)
              const _PaywallCard()
            else if (isPredLoading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: kPurple),
                        SizedBox(height: 16),
                        Text('Calculando análisis...',
                            style: TextStyle(color: kMuted)),
                      ],
                    ),
                  ),
                ),
              )
            else if (pred != null)
              PredictionCard(pred: pred)
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.analytics_outlined,
                          color: kMuted, size: 40),
                      const SizedBox(height: 12),
                      const Text('Análisis no disponible',
                          style: TextStyle(color: kMuted)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          final token =
                              context.read<AuthProvider>().token;
                          context
                              .read<MatchesProvider>()
                              .loadPrediction(match.id, token: token);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MatchHeader extends StatelessWidget {
  final MatchModel match;
  const _MatchHeader(this.match);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(match.league.name,
                style: const TextStyle(color: kMuted, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              DateFormat('d MMM yyyy, HH:mm').format(match.kickoff),
              style: const TextStyle(color: kMuted, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    match.homeTeam,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                if (match.isLive || match.isFinished)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: match.isLive
                          ? const Color(0xFF22c55e).withAlpha(20)
                          : kSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${match.homeScore ?? 0}  –  ${match.awayScore ?? 0}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: match.isLive
                            ? const Color(0xFF22c55e)
                            : kText,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: const Text('VS',
                        style: TextStyle(
                            color: kMuted,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ),
                Expanded(
                  child: Text(
                    match.awayTeam,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ],
            ),
            if (match.isLive) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF22c55e),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('EN VIVO',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Paywall ───────────────────────────────────────────────────────────────────

class _PaywallCard extends StatefulWidget {
  const _PaywallCard();
  @override
  State<_PaywallCard> createState() => _PaywallCardState();
}

class _PaywallCardState extends State<_PaywallCard> {
  double? _bsMonthly;
  double? _bcvRate;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPrices();
  }

  Future<void> _fetchPrices() async {
    try {
      final resp = await http.get(Uri.parse('$kBaseUrl/api/payments/info'));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (mounted) {
          setState(() {
            _bsMonthly = (data['precio_mensual_bs'] as num?)?.toDouble();
            _bcvRate   = (data['tasa_bcv'] as num?)?.toDouble();
            _loading   = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'es');
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [kPurple.withAlpha(25), kPurpleDark.withAlpha(15)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFf59e0b).withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: Color(0xFFf59e0b), size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Límite diario alcanzado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kText)),
            const SizedBox(height: 8),
            const Text(
              'Ya usaste tus 2 análisis gratuitos de hoy.\nActualiza a Premium para acceso ilimitado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            _BenefitRow(Icons.all_inclusive, 'Análisis ilimitados por día'),
            _BenefitRow(Icons.bolt, 'Pitchers, H2H y O/U en cada partido'),
            _BenefitRow(Icons.auto_awesome, 'Chat Vera IA sin restricciones'),
            const SizedBox(height: 20),

            // Precio con tasa BCV
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kPurple.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kPurple.withAlpha(60)),
              ),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('\$3',
                      style: TextStyle(color: kPurple, fontSize: 28, fontWeight: FontWeight.w800)),
                  const Text(' USD/mes  ·  ',
                      style: TextStyle(color: kMuted, fontSize: 13)),
                  const Text('\$25',
                      style: TextStyle(color: kPurple, fontSize: 20, fontWeight: FontWeight.w700)),
                  const Text(' USD/año',
                      style: TextStyle(color: kMuted, fontSize: 13)),
                ]),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: SizedBox(height: 14, width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else if (_bsMonthly != null && _bcvRate != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Bs. ${fmt.format(_bsMonthly!.round())} / mes',
                    style: const TextStyle(
                        color: Color(0xFF22c55e),
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Tasa BCV del día: Bs. ${fmt.format(_bcvRate!.round())} / \$',
                    style: const TextStyle(color: kMuted, fontSize: 10),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 16),

            // Botón Telegram
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF229ED9),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                label: const Text('Suscribirse por Telegram',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                onPressed: () => launchUrl(
                    Uri.parse(kTelegramUrl),
                    mode: LaunchMode.externalApplication),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Mañana se restablecen tus 2 análisis gratuitos',
                style: TextStyle(color: kMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BenefitRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: kPurple, size: 16),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: kText, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Contexto rico para Vera IA ────────────────────────────────────────────────

String _buildVeraContext(MatchModel match, PredictionModel? pred) {
  final buf = StringBuffer();
  final isFootball = match.sport == 'football';

  // Cabecera del partido
  final status = match.isLive
      ? 'EN VIVO ${match.homeScore ?? 0}-${match.awayScore ?? 0}'
      : match.isFinished
          ? 'Finalizado ${match.homeScore ?? 0}-${match.awayScore ?? 0}'
          : 'Sin comenzar';

  buf.writeln('=== DATOS DEL MOTOR VEREDICTO ===');
  buf.writeln('Partido: ${match.homeTeam} vs ${match.awayTeam}');
  buf.writeln('Liga: ${match.league.name} | Deporte: ${match.sport}');
  buf.writeln('Estado: $status');
  if (match.venue != null) buf.writeln('Estadio: ${match.venue}');
  buf.writeln();

  if (pred == null) {
    buf.writeln('(Predicción no generada aún)');
    return buf.toString();
  }

  // Probabilidades
  buf.writeln('--- PROBABILIDADES ---');
  buf.writeln('${match.homeTeam}: ${pred.homeWinPct.toStringAsFixed(1)}%');
  if (pred.drawPct > 0) buf.writeln('Empate: ${pred.drawPct.toStringAsFixed(1)}%');
  buf.writeln('${match.awayTeam}: ${pred.awayWinPct.toStringAsFixed(1)}%');
  if (isFootball) {
    buf.writeln('xG local: ${pred.homeXg.toStringAsFixed(2)} goles esperados');
    buf.writeln('xG visitante: ${pred.awayXg.toStringAsFixed(2)} goles esperados');
  } else {
    buf.writeln('xC local: ${pred.homeXg.toStringAsFixed(2)} carreras esperadas');
    buf.writeln('xC visitante: ${pred.awayXg.toStringAsFixed(2)} carreras esperadas');
  }
  buf.writeln('Confianza del motor: ${pred.confidence}% (${pred.confidenceLabel})');
  buf.writeln();

  // Pitchers (solo béisbol)
  if (!isFootball && (pred.homePitcherName != null || pred.awayPitcherName != null)) {
    buf.writeln('--- PITCHERS TITULARES ---');
    if (pred.homePitcherName != null) {
      buf.write('Local — ${pred.homePitcherName}');
      if (pred.homePitcherEra != null) buf.write(' | ERA: ${pred.homePitcherEra!.toStringAsFixed(2)}');
      if (pred.homePitcherK9 != null) buf.write(' | K/jgo: ${pred.homePitcherK9!.toStringAsFixed(1)}');
      buf.writeln();
    }
    if (pred.awayPitcherName != null) {
      buf.write('Visitante — ${pred.awayPitcherName}');
      if (pred.awayPitcherEra != null) buf.write(' | ERA: ${pred.awayPitcherEra!.toStringAsFixed(2)}');
      if (pred.awayPitcherK9 != null) buf.write(' | K/jgo: ${pred.awayPitcherK9!.toStringAsFixed(1)}');
      buf.writeln();
    }
    buf.writeln();
  }

  // Rankings FIFA (solo fútbol)
  if (isFootball) {
    final rankingData = pred.variablesUsadas
        .where((v) => v.contains('Ranking FIFA'))
        .toList();
    if (rankingData.isNotEmpty) {
      buf.writeln('--- RANKINGS FIFA 2026 ---');
      for (final r in rankingData) {
        buf.writeln('· $r');
      }
      buf.writeln();
    }
  }

  // H2H
  if ((pred.h2hJuegos ?? 0) >= 2) {
    final avgLabel = isFootball ? 'G/pdo' : 'C/jgo';
    buf.writeln('--- CARA A CARA (últimos ${pred.h2hJuegos} enfrentamientos) ---');
    buf.writeln('${match.homeTeam}: ${pred.h2hVictoriasLocal ?? 0} victorias | ${(pred.h2hRunsLocalAvg ?? 0).toStringAsFixed(1)} $avgLabel promedio');
    buf.writeln('${match.awayTeam}: ${pred.h2hVictoriasVisit ?? 0} victorias | ${(pred.h2hRunsVisitAvg ?? 0).toStringAsFixed(1)} $avgLabel promedio');
    buf.writeln();
  }

  // O/U
  if (pred.ouLine != null) {
    final unitLabel = isFootball ? 'goles totales' : 'carreras totales';
    final projLabel = isFootball ? 'goles' : 'carreras';
    buf.writeln('--- MÁS/MENOS ---');
    buf.writeln('Línea: ${pred.ouLine} $unitLabel');
    buf.writeln('MÁS: ${pred.overPct?.toStringAsFixed(1) ?? "—"}%');
    buf.writeln('MENOS: ${pred.underPct?.toStringAsFixed(1) ?? "—"}%');
    if (pred.projectedTotal != null) {
      buf.writeln('Proyectado por el motor: ${pred.projectedTotal!.toStringAsFixed(1)} $projLabel');
    }
    buf.writeln();
  }

  // Ponches (solo béisbol)
  if (!isFootball && (pred.homeKLine != null || pred.awayKLine != null)) {
    buf.writeln('--- PONCHES DEL PITCHER (prop bet) ---');
    if (pred.homeKLine != null) {
      buf.writeln('${pred.homePitcherName ?? match.homeTeam}: línea ${pred.homeKLine} Ks | OVER ${pred.homeKOverPct?.toStringAsFixed(1)}% | UNDER ${pred.homeKUnderPct?.toStringAsFixed(1)}% | prom. ${pred.homeKMu} K/jgo');
    }
    if (pred.awayKLine != null) {
      buf.writeln('${pred.awayPitcherName ?? match.awayTeam}: línea ${pred.awayKLine} Ks | OVER ${pred.awayKOverPct?.toStringAsFixed(1)}% | UNDER ${pred.awayKUnderPct?.toStringAsFixed(1)}% | prom. ${pred.awayKMu} K/jgo');
    }
    buf.writeln();
  }

  // Datos usados
  if (pred.variablesUsadas.isNotEmpty) {
    buf.writeln('--- DATOS UTILIZADOS POR EL MOTOR ---');
    for (final v in pred.variablesUsadas) {
      buf.writeln('· $v');
    }
  }

  buf.writeln('=================================');
  return buf.toString();
}
