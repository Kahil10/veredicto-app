import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/flags.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
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
  final ScreenshotController _screenshotController = ScreenshotController();
  Map<String, dynamic>? _lineup;
  bool _lineupLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      context
          .read<MatchesProvider>()
          .loadPrediction(widget.match.id, token: token);
      if (widget.match.sport == 'baseball' &&
          (widget.match.isScheduled || widget.match.isPostponed)) {
        _fetchLineup();
      }
    });
  }

  Future<void> _fetchLineup() async {
    if (!mounted) return;
    setState(() => _lineupLoading = true);
    try {
      final token = context.read<AuthProvider>().token;
      final headers = token != null
          ? {'Authorization': 'Bearer $token'}
          : <String, String>{};
      final resp = await http.get(
        Uri.parse('$kBaseUrl/api/matches/${widget.match.id}/lineup'),
        headers: headers,
      );
      if (resp.statusCode == 200) {
        if (mounted) setState(() => _lineup = jsonDecode(resp.body));
      }
    } catch (_) {}
    if (mounted) setState(() => _lineupLoading = false);
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
          if (pred != null)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Compartir predicción',
              onPressed: () async {
                final isFootball = match.sport == 'football';
                final emoji = isFootball ? '⚽' : '⚾';
                try {
                  final image = await _screenshotController.captureFromWidget(
                    _ShareCard(match: match, pred: pred!),
                    context: context,
                    pixelRatio: 3.0,
                    targetSize: const Size(400, 460),
                  );
                  final dir = await getTemporaryDirectory();
                  final file = File('${dir.path}/veredicto_share.png');
                  await file.writeAsBytes(image);
                  await Share.shareXFiles(
                    [XFile(file.path)],
                    text: '$emoji Predicción Veredicto',
                  );
                } catch (_) {
                  final homePct = pred!.homeWinPct.toStringAsFixed(1);
                  final awayPct = pred!.awayWinPct.toStringAsFixed(1);
                  Share.share('$emoji ${match.homeTeam} $homePct% vs ${match.awayTeam} $awayPct% · Motor Veredicto 🔮');
                }
              },
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
            else if (pred != null) ...[
              PredictionCard(pred: pred),
              if (widget.match.sport == 'baseball' &&
                  (widget.match.isScheduled || widget.match.isPostponed))
                _LineupSection(lineup: _lineup, loading: _lineupLoading),
            ] else
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
                  child: Column(
                    children: [
                      if (footballFlagUrl(match.homeTeam) != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              footballFlagUrl(match.homeTeam)!,
                              width: 56, height: 37, fit: BoxFit.cover,
                              loadingBuilder: (_, child, prog) =>
                                  prog == null ? child : const SizedBox(width: 56, height: 37),
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      Text(
                        match.homeTeam,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ],
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
                  child: Column(
                    children: [
                      if (footballFlagUrl(match.awayTeam) != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              footballFlagUrl(match.awayTeam)!,
                              width: 56, height: 37, fit: BoxFit.cover,
                              loadingBuilder: (_, child, prog) =>
                                  prog == null ? child : const SizedBox(width: 56, height: 37),
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      Text(
                        match.awayTeam,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ],
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

// ── Tarjeta compacta para compartir ──────────────────────────────────────────

class _ShareCard extends StatelessWidget {
  final MatchModel match;
  final PredictionModel pred;
  const _ShareCard({required this.match, required this.pred});

  @override
  Widget build(BuildContext context) {
    final isFootball = match.sport == 'football';
    final homeWin = pred.homeWinPct.toStringAsFixed(1);
    final awayWin = pred.awayWinPct.toStringAsFixed(1);
    final drawPct = pred.drawPct.toStringAsFixed(1);
    final homeName = isFootball ? match.homeTeam : match.homeTeam.split(' ').last;
    final awayName = isFootball ? match.awayTeam : match.awayTeam.split(' ').last;

    final homeLeads = pred.homeWinPct >= pred.awayWinPct;
    final pick = homeLeads ? homeName : awayName;
    final pickPct = homeLeads ? homeWin : awayWin;
    // pickPct is a String (e.g. "51.3")

    final footerText = isFootball
        ? 'Rankings FIFA 2026 · Motor Bayesiano · 10,000 simulaciones'
        : 'MLB Stats · Motor Bayesiano · 10,000 simulaciones';

    return Container(
      width: 400,
      color: const Color(0xFF0a0e13),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: const Color(0xFF111827),
            child: Row(children: [
              Text(isFootball ? '⚽' : '⚾', style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text('VEREDICTO',
                  style: GoogleFonts.bebasNeue(
                      fontSize: 22, color: kAccent, letterSpacing: 3)),
              const Spacer(),
              Text(match.league.name,
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 9, color: kMuted, letterSpacing: 0.5)),
            ]),
          ),

          // Teams + %
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Local
                Expanded(
                  child: Column(children: [
                    Text(homeName.toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: GoogleFonts.bebasNeue(
                            fontSize: 18, color: kText, letterSpacing: 1, height: 1.1)),
                    const SizedBox(height: 6),
                    Text('$homeWin%',
                        style: GoogleFonts.bebasNeue(
                            fontSize: 44,
                            color: homeLeads ? kAccent : kMuted,
                            height: 1)),
                    Text('LOCAL',
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 8, color: kMuted, letterSpacing: 1.5)),
                  ]),
                ),

                // VS + empate
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('VS',
                        style: GoogleFonts.bebasNeue(
                            fontSize: 22, color: kMuted.withAlpha(120))),
                    if (isFootball && pred.drawPct > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: kMuted.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: kMuted.withAlpha(40)),
                        ),
                        child: Column(children: [
                          Text('$drawPct%',
                              style: GoogleFonts.bebasNeue(
                                  fontSize: 16, color: kMuted)),
                          Text('EMPATE',
                              style: GoogleFonts.jetBrainsMono(
                                  fontSize: 7, color: kMuted, letterSpacing: 1)),
                        ]),
                      ),
                    ],
                  ]),
                ),

                // Visitante
                Expanded(
                  child: Column(children: [
                    Text(awayName.toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: GoogleFonts.bebasNeue(
                            fontSize: 18, color: kText, letterSpacing: 1, height: 1.1)),
                    const SizedBox(height: 6),
                    Text('$awayWin%',
                        style: GoogleFonts.bebasNeue(
                            fontSize: 44,
                            color: !homeLeads ? kAccent2 : kMuted,
                            height: 1)),
                    Text('VISITANTE',
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 8, color: kMuted, letterSpacing: 1.5)),
                  ]),
                ),
              ],
            ),
          ),

          // Divider
          Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 20), color: kBorder),

          // Pick
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: kAccent.withAlpha(18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kAccent.withAlpha(60)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('🏆  PICK: ',
                    style: GoogleFonts.jetBrainsMono(fontSize: 11, color: kMuted)),
                Text(pick.toUpperCase(),
                    style: GoogleFonts.bebasNeue(
                        fontSize: 20, color: kAccent, letterSpacing: 1)),
                Text('  ·  ${pred.confidence}% confianza',
                    style: GoogleFonts.jetBrainsMono(fontSize: 10, color: kMuted)),
              ]),
            ),
          ),

          // Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            color: const Color(0xFF111827),
            child: Column(children: [
              if (isFootball)
                Text('Los % representan: local gana / empate / visitante gana',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jetBrainsMono(fontSize: 8, color: kMuted.withAlpha(100))),
              if (isFootball) const SizedBox(height: 4),
              Text(footerText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 8, color: kMuted.withAlpha(140), letterSpacing: 0.3)),
              const SizedBox(height: 4),
              Text('veredicto.app',
                  style: GoogleFonts.bebasNeue(
                      fontSize: 14, color: kMuted.withAlpha(180), letterSpacing: 2)),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Alineaciones MLB ──────────────────────────────────────────────────────────

class _LineupSection extends StatelessWidget {
  final Map<String, dynamic>? lineup;
  final bool loading;
  const _LineupSection({this.lineup, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
            child: CircularProgressIndicator(color: kPurple, strokeWidth: 2)),
      );
    }

    final homeList =
        (lineup?['home_lineup'] as List?)?.cast<Map>() ?? [];
    final awayList =
        (lineup?['away_lineup'] as List?)?.cast<Map>() ?? [];
    final published = lineup?['lineup_publicada'] == true;
    final homeName = lineup?['home_team'] ?? '';
    final awayName = lineup?['away_team'] ?? '';

    if (!published || (homeList.isEmpty && awayList.isEmpty)) {
      return Card(
        margin: const EdgeInsets.only(top: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.people_outline, color: kMuted, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Alineaciones pendientes — se publican 1-3h antes del primer out',
                  style: TextStyle(color: kMuted, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: kAccent, size: 18),
                const SizedBox(width: 8),
                Text('ALINEACIONES TITULARES',
                    style: TextStyle(
                        color: kAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: _LineupTeam(
                        teamName: homeName,
                        players: homeList,
                        isHome: true)),
                const SizedBox(width: 12),
                Expanded(
                    child: _LineupTeam(
                        teamName: awayName,
                        players: awayList,
                        isHome: false)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LineupTeam extends StatelessWidget {
  final String teamName;
  final List<Map> players;
  final bool isHome;
  const _LineupTeam(
      {required this.teamName,
      required this.players,
      required this.isHome});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(teamName.split(' ').last,
            style: const TextStyle(
                color: kText, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        ...players.map((p) {
          final pos = p['posicion'] ?? '?';
          final name =
              (p['nombre'] as String? ?? '').split(' ').last;
          return Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Text('${p['orden']}.',
                      style:
                          const TextStyle(color: kMuted, fontSize: 11)),
                ),
                Container(
                  width: 26,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(pos,
                      style: const TextStyle(
                          color: kMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(name,
                      style:
                          const TextStyle(color: kText, fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
