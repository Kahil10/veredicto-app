import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../core/theme.dart';
import '../models/prediction_model.dart';

// ── Logo del equipo MLB ───────────────────────────────────────────────────────

class _TeamLogo extends StatelessWidget {
  final int? teamId;
  final String teamName;
  final double size;
  final bool isHome;

  const _TeamLogo({
    required this.teamId,
    required this.teamName,
    this.size = 56,
    this.isHome = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: kSurface2,
            shape: BoxShape.circle,
            border: Border.all(color: isHome ? kAccent.withAlpha(60) : kAccent2.withAlpha(40)),
          ),
          child: teamId != null
              ? ClipOval(
                  child: SvgPicture.network(
                    'https://www.mlbstatic.com/team-logos/$teamId.svg',
                    fit: BoxFit.contain,
                    placeholderBuilder: (_) => _initials(teamName, size),
                  ),
                )
              : _initials(teamName, size),
        ),
        if (isHome)
          Positioned(
            top: -8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: kAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('LOCAL',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 7, fontWeight: FontWeight.w700, color: Colors.black)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _initials(String name, double size) {
    final parts = name.trim().split(' ');
    final init = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'
        : name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    return Center(
      child: Text(init,
          style: GoogleFonts.bebasNeue(
              fontSize: size * 0.38, color: kText, letterSpacing: 1)),
    );
  }
}

// ── Tarjeta principal ─────────────────────────────────────────────────────────

class PredictionCard extends StatelessWidget {
  final PredictionModel pred;
  const PredictionCard({super.key, required this.pred});

  @override
  Widget build(BuildContext context) {
    final match      = pred.match;
    final isBaseball = match.sport == 'baseball';

    return Column(
      children: [
        // Hero
        _HeroSection(pred: pred),
        const SizedBox(height: 12),

        // Barra de confianza
        _ConfidenceBar(pred: pred),
        const SizedBox(height: 12),

        // Pitchers
        if (isBaseball && pred.homePitcherName != null) ...[
          _SectionCard(
            icon: '⚾',
            iconColor: const Color(0xFFe8ff3a),
            title: 'PITCHERS TITULARES',
            subtitle: 'Abridores confirmados por MLB',
            child: _PitcherGrid(pred: pred),
          ),
          const SizedBox(height: 10),
        ],

        // Head-to-Head
        if (isBaseball && (pred.h2hJuegos ?? 0) >= 2) ...[
          _SectionCard(
            icon: '📊',
            iconColor: kGold,
            title: 'HEAD-TO-HEAD',
            subtitle: 'Últimos ${pred.h2hJuegos} enfrentamientos',
            child: _H2HContent(pred: pred),
          ),
          const SizedBox(height: 10),
        ],

        // Ponches
        if (isBaseball && (pred.homeKLine != null || pred.awayKLine != null)) ...[
          _SectionCard(
            icon: '🎯',
            iconColor: kAccent3,
            title: 'PONCHES DEL PITCHER',
            subtitle: 'Prop bet — strikeouts del abridor',
            child: _PoncheContent(pred: pred),
          ),
          const SizedBox(height: 10),
        ],

        // Over/Under
        if (isBaseball && pred.ouLine != null) ...[
          _SectionCard(
            icon: '⚖️',
            iconColor: kAccent2,
            title: 'TOTALES',
            subtitle: 'Over / Under carreras',
            child: _OUContent(pred: pred),
          ),
          const SizedBox(height: 10),
        ],

        // Datos utilizados
        _DataSection(pred: pred),
      ],
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final PredictionModel pred;
  const _HeroSection({required this.pred});

  @override
  Widget build(BuildContext context) {
    final match  = pred.match;
    final home   = match.homeTeam;
    final away   = match.awayTeam;
    final homeParts = home.split(' ');
    final awayParts = away.split(' ');
    final homeCity = homeParts.length > 1 ? homeParts.sublist(0, homeParts.length - 1).join(' ') : '';
    final homeTeam = homeParts.last;
    final awayCity = awayParts.length > 1 ? awayParts.sublist(0, awayParts.length - 1).join(' ') : '';
    final awayTeam = awayParts.last;

    // Pick principal basado en probabilidades
    final homeWin  = pred.homeWinPct;
    final awayWin  = pred.awayWinPct;
    final favorite = homeWin > awayWin ? home : away;
    final favPct   = homeWin > awayWin ? homeWin : awayWin;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0f1318), Color(0xFF1a1f2e), Color(0xFF0f1318)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Stack(
        children: [
          // Watermark béisbol
          Positioned(
            right: -10,
            top: -10,
            child: Text('⚾',
                style: const TextStyle(fontSize: 110, color: Colors.white)
                    .copyWith(color: Colors.white.withAlpha(10))),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tags top
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Tag('⚾ MLB · ANÁLISIS ÉLITE', color: kAccent, textColor: Colors.black),
                    _Tag(
                      '${match.kickoff.day} ${_mes(match.kickoff.month)} · ${match.kickoff.hour}:${match.kickoff.minute.toString().padLeft(2,'0')}',
                      color: kSurface2,
                      textColor: kMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Logos + nombres
                Row(
                  children: [
                    // Local
                    Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      _TeamLogo(
                        teamId: match.homeTeamId,
                        teamName: home,
                        size: 62,
                        isHome: true,
                      ),
                      const SizedBox(height: 8),
                      Text(homeCity.toUpperCase(),
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 8, color: kMuted, letterSpacing: 1.5)),
                      Text(homeTeam.toUpperCase(),
                          style: GoogleFonts.bebasNeue(
                              fontSize: 22, color: kText, letterSpacing: 1)),
                    ]),

                    // VS
                    Expanded(
                      child: Column(children: [
                        Text('VS',
                            style: GoogleFonts.bebasNeue(
                                fontSize: 28, color: kMuted, letterSpacing: 3)),
                        Text(
                          '${pred.homeWinPct.toStringAsFixed(0)}% — ${pred.awayWinPct.toStringAsFixed(0)}%',
                          style: GoogleFonts.jetBrainsMono(fontSize: 10, color: kMuted),
                        ),
                      ]),
                    ),

                    // Visitante
                    Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      _TeamLogo(
                        teamId: match.awayTeamId,
                        teamName: away,
                        size: 62,
                        isHome: false,
                      ),
                      const SizedBox(height: 8),
                      Text(awayCity.toUpperCase(),
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 8, color: kMuted, letterSpacing: 1.5)),
                      Text(awayTeam.toUpperCase(),
                          style: GoogleFonts.bebasNeue(
                              fontSize: 22, color: kText, letterSpacing: 1)),
                    ]),
                  ],
                ),

                // Metadata (estadio/fecha)
                if (match.venue != null) ...[
                  const SizedBox(height: 16),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: kMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(match.venue!,
                          style: GoogleFonts.dmSans(fontSize: 12, color: kMuted),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ],

                // Verdict strip
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      kAccent.withAlpha(30),
                      Colors.transparent,
                    ]),
                    border: const Border(left: BorderSide(color: kAccent, width: 3)),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    '🏆  PICK: $favorite  ·  ${favPct.toStringAsFixed(0)}% probabilidad',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w600, color: kText),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _mes(int m) => ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'][m];
}

// ── Barra de confianza ────────────────────────────────────────────────────────

class _ConfidenceBar extends StatefulWidget {
  final PredictionModel pred;
  const _ConfidenceBar({required this.pred});
  @override
  State<_ConfidenceBar> createState() => _ConfidenceBarState();
}

class _ConfidenceBarState extends State<_ConfidenceBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.forward());
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pct = widget.pred.confidence / 100.0;
    final label = widget.pred.confidenceLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('NIVEL DE CONFIANZA',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 10, color: kMuted, letterSpacing: 2)),
          _Tag(label.toUpperCase(),
              color: pct >= 0.75
                  ? kGreen.withAlpha(40)
                  : pct >= 0.45
                      ? kGold.withAlpha(40)
                      : kRed.withAlpha(40),
              textColor: pct >= 0.75 ? kGreen : pct >= 0.45 ? kGold : kRed),
        ]),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => LinearPercentIndicator(
            percent: pct * _anim.value,
            lineHeight: 10,
            backgroundColor: Colors.white.withAlpha(15),
            linearGradient: const LinearGradient(
                colors: [kAccent3, kAccent]),
            barRadius: const Radius.circular(99),
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Text(
            '${(widget.pred.confidence * _anim.value).toStringAsFixed(0)}%',
            style: GoogleFonts.bebasNeue(
                fontSize: 46, color: kAccent, letterSpacing: 1),
          ),
        ),
        Text('Motor Monte Carlo 10k · Bayesiano',
            style: GoogleFonts.jetBrainsMono(fontSize: 10, color: kMuted)),
      ]),
    );
  }
}

// ── Contenedor de sección ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text(icon, style: const TextStyle(fontSize: 17))),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: GoogleFonts.bebasNeue(
                        fontSize: 18, color: kText, letterSpacing: 1.5)),
                Text(subtitle,
                    style: GoogleFonts.dmSans(fontSize: 10, color: kMuted)),
              ]),
            ]),
          ),
          Container(height: 1, color: kBorder),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── Pitchers ──────────────────────────────────────────────────────────────────

class _PitcherGrid extends StatelessWidget {
  final PredictionModel pred;
  const _PitcherGrid({required this.pred});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (pred.homePitcherName != null)
          Expanded(child: _PitcherCard(
            name: pred.homePitcherName!,
            team: pred.match.homeTeam.split(' ').last,
            era: pred.homePitcherEra,
            k9: pred.homePitcherK9,
            isHome: true,
          )),
        if (pred.homePitcherName != null && pred.awayPitcherName != null)
          const SizedBox(width: 10),
        if (pred.awayPitcherName != null)
          Expanded(child: _PitcherCard(
            name: pred.awayPitcherName!,
            team: pred.match.awayTeam.split(' ').last,
            era: pred.awayPitcherEra,
            k9: pred.awayPitcherK9,
            isHome: false,
          )),
      ],
    );
  }
}

class _PitcherCard extends StatelessWidget {
  final String name;
  final String team;
  final double? era;
  final double? k9;
  final bool isHome;

  const _PitcherCard({
    required this.name,
    required this.team,
    this.era,
    this.k9,
    required this.isHome,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = isHome ? kAccent : kAccent2;
    // Clasificar ERA
    Color eraColor = kMuted;
    if (era != null) {
      eraColor = era! <= 3.00 ? kGreen : era! <= 4.50 ? kGold : kRed;
    }

    return Container(
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Franja de color top
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.split(' ').last.toUpperCase(),
                    style: GoogleFonts.bebasNeue(
                        fontSize: 20, color: kText, letterSpacing: 1)),
                Text(name.split(' ').first, // primer nombre más pequeño
                    style: GoogleFonts.dmSans(fontSize: 11, color: kMuted)),
                Text(team.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 9, color: kMuted, letterSpacing: 1)),
                const SizedBox(height: 10),
                // Stats grid 2 columnas
                Row(children: [
                  Expanded(child: _PStat(
                    val: era?.toStringAsFixed(2) ?? '—',
                    lbl: 'ERA',
                    color: eraColor,
                  )),
                  const SizedBox(width: 6),
                  Expanded(child: _PStat(
                    val: k9?.toStringAsFixed(1) ?? '—',
                    lbl: 'K/JGO',
                    color: kAccent3,
                  )),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PStat extends StatelessWidget {
  final String val;
  final String lbl;
  final Color color;
  const _PStat({required this.val, required this.lbl, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(children: [
        Text(val,
            style: GoogleFonts.jetBrainsMono(
                fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(lbl,
            style: GoogleFonts.jetBrainsMono(
                fontSize: 8, color: kMuted, letterSpacing: 1)),
      ]),
    );
  }
}

// ── H2H ───────────────────────────────────────────────────────────────────────

class _H2HContent extends StatelessWidget {
  final PredictionModel pred;
  const _H2HContent({required this.pred});

  @override
  Widget build(BuildContext context) {
    final n     = pred.h2hJuegos!;
    final wHome = pred.h2hVictoriasLocal ?? 0;
    final wAway = pred.h2hVictoriasVisit ?? 0;
    final rHome = pred.h2hRunsLocalAvg ?? 0;
    final rAway = pred.h2hRunsVisitAvg ?? 0;
    final home  = pred.match.homeTeam.split(' ').last;
    final away  = pred.match.awayTeam.split(' ').last;
    final homeWinPct = n > 0 ? wHome / n : 0.5;

    return Column(children: [
      // Marcador grande
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(children: [
            Text(home.toUpperCase(),
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 9, color: kMuted, letterSpacing: 1)),
            Text('$wHome',
                style: GoogleFonts.bebasNeue(
                    fontSize: 48,
                    color: homeWinPct > 0.5 ? kAccent : kMuted)),
            Text('${rHome.toStringAsFixed(1)} C/jgo',
                style: GoogleFonts.jetBrainsMono(fontSize: 10, color: kMuted)),
          ]),
          Column(children: [
            Text('VS',
                style: GoogleFonts.bebasNeue(
                    fontSize: 16, color: kMuted, letterSpacing: 3)),
            Text('$n JGS',
                style: GoogleFonts.jetBrainsMono(fontSize: 9, color: kMuted)),
          ]),
          Column(children: [
            Text(away.toUpperCase(),
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 9, color: kMuted, letterSpacing: 1)),
            Text('$wAway',
                style: GoogleFonts.bebasNeue(
                    fontSize: 48,
                    color: homeWinPct < 0.5 ? kAccent2 : kMuted)),
            Text('${rAway.toStringAsFixed(1)} C/jgo',
                style: GoogleFonts.jetBrainsMono(fontSize: 10, color: kMuted)),
          ]),
        ],
      ),
    ]);
  }
}

// ── Ponches ───────────────────────────────────────────────────────────────────

class _PoncheContent extends StatelessWidget {
  final PredictionModel pred;
  const _PoncheContent({required this.pred});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (pred.homeKLine != null)
        _PropRow(
          player: pred.homePitcherName ?? pred.match.homeTeam.split(' ').last,
          team: pred.match.homeTeam.split(' ').last,
          line: pred.homeKLine!,
          overPct: pred.homeKOverPct!,
          underPct: pred.homeKUnderPct!,
          mu: pred.homeKMu!,
          isHome: true,
        ),
      if (pred.homeKLine != null && pred.awayKLine != null)
        const SizedBox(height: 8),
      if (pred.awayKLine != null)
        _PropRow(
          player: pred.awayPitcherName ?? pred.match.awayTeam.split(' ').last,
          team: pred.match.awayTeam.split(' ').last,
          line: pred.awayKLine!,
          overPct: pred.awayKOverPct!,
          underPct: pred.awayKUnderPct!,
          mu: pred.awayKMu!,
          isHome: false,
        ),
    ]);
  }
}

class _PropRow extends StatelessWidget {
  final String player;
  final String team;
  final double line;
  final double overPct;
  final double underPct;
  final double mu;
  final bool isHome;

  const _PropRow({
    required this.player,
    required this.team,
    required this.line,
    required this.overPct,
    required this.underPct,
    required this.mu,
    required this.isHome,
  });

  @override
  Widget build(BuildContext context) {
    final isOver  = overPct >= underPct;
    final favColor = isOver ? kGreen : kAccent3;
    final favLabel = isOver ? 'OVER ${line.toStringAsFixed(1)}' : 'UNDER ${line.toStringAsFixed(1)}';
    final favPct   = isOver ? overPct : underPct;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorder),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(player.split(' ').last.toUpperCase(),
              style: GoogleFonts.bebasNeue(fontSize: 16, color: kText, letterSpacing: 1)),
          Text(team.toUpperCase(),
              style: GoogleFonts.jetBrainsMono(fontSize: 9, color: kMuted, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text('Prom. histórico: ${mu.toStringAsFixed(1)} K/jgo',
              style: GoogleFonts.dmSans(fontSize: 10, color: kMuted)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: favColor.withAlpha(35),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: favColor.withAlpha(80)),
            ),
            child: Text(favLabel,
                style: GoogleFonts.bebasNeue(
                    fontSize: 14, color: favColor, letterSpacing: 1)),
          ),
          const SizedBox(height: 4),
          Text('${favPct.toStringAsFixed(1)}%',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 13, fontWeight: FontWeight.w700, color: favColor)),
        ]),
      ]),
    );
  }
}

// ── Over / Under ──────────────────────────────────────────────────────────────

class _OUContent extends StatelessWidget {
  final PredictionModel pred;
  const _OUContent({required this.pred});

  @override
  Widget build(BuildContext context) {
    final line  = pred.ouLine!;
    final over  = pred.overPct ?? 50;
    final under = pred.underPct ?? 50;
    final proj  = pred.projectedTotal;
    final isOver = over > under;
    final pickColor = isOver ? kGreen : kAccent2;
    final pickLabel = isOver ? '🔥  ALTAS  >$line' : '❄️  BAJAS  <$line';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Pick destacado
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: pickColor.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: pickColor.withAlpha(60)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(pickLabel,
              style: GoogleFonts.bebasNeue(
                  fontSize: 18, color: pickColor, letterSpacing: 1.5)),
          Text('${(isOver ? over : under).toStringAsFixed(1)}%',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 16, fontWeight: FontWeight.w700, color: pickColor)),
        ]),
      ),
      const SizedBox(height: 12),

      // Línea + proyectado
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('LÍNEA', style: GoogleFonts.jetBrainsMono(fontSize: 9, color: kMuted, letterSpacing: 1)),
          Text('$line', style: GoogleFonts.bebasNeue(fontSize: 28, color: kText)),
        ]),
        if (proj != null)
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('PROYECTADO', style: GoogleFonts.jetBrainsMono(fontSize: 9, color: kMuted, letterSpacing: 1)),
            Text(proj.toStringAsFixed(1),
                style: GoogleFonts.bebasNeue(fontSize: 28, color: kAccent3)),
          ]),
      ]),
      const SizedBox(height: 10),

      // Barras over/under
      _OUBar(label: 'OVER  >$line', pct: over, color: kGreen),
      const SizedBox(height: 6),
      _OUBar(label: 'UNDER <$line', pct: under, color: kAccent2),
    ]);
  }
}

class _OUBar extends StatelessWidget {
  final String label;
  final double pct;
  final Color color;
  const _OUBar({required this.label, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(
        width: 80,
        child: Text(label,
            style: GoogleFonts.jetBrainsMono(fontSize: 10, color: kMuted, letterSpacing: .5)),
      ),
      Expanded(
        child: LinearPercentIndicator(
          percent: pct / 100,
          lineHeight: 8,
          backgroundColor: Colors.white.withAlpha(15),
          progressColor: color,
          barRadius: const Radius.circular(99),
          padding: EdgeInsets.zero,
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 42,
        child: Text('${pct.toStringAsFixed(1)}%',
            textAlign: TextAlign.right,
            style: GoogleFonts.jetBrainsMono(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ),
    ]);
  }
}

// ── Datos utilizados ──────────────────────────────────────────────────────────

class _DataSection extends StatelessWidget {
  final PredictionModel pred;
  const _DataSection({required this.pred});

  @override
  Widget build(BuildContext context) {
    final usadas   = pred.variablesUsadas;
    final faltantes = pred.variablesFaltantes
        .where((v) => !v.contains('insuficiente') && !v.contains('< 3'))
        .toList();
    final gaps = pred.variablesFaltantes
        .where((v) => v.contains('insuficiente') || v.contains('< 3'))
        .toList();

    return Column(children: [
      if (usadas.isNotEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kGreen.withAlpha(12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kGreen.withAlpha(50)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.check_circle_outline, color: kGreen, size: 14),
              const SizedBox(width: 6),
              Text('DATOS UTILIZADOS',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 10, color: kGreen, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 8),
            ...usadas.map((v) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('· ', style: GoogleFonts.dmSans(color: kGreen, fontSize: 11)),
                Expanded(child: Text(v,
                    style: GoogleFonts.dmSans(color: kMuted, fontSize: 11))),
              ]),
            )),
          ]),
        ),

      if (gaps.isNotEmpty) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kGold.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kGold.withAlpha(50)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.warning_amber_rounded, color: kGold, size: 13),
              const SizedBox(width: 6),
              Text('HISTORIAL LIMITADO',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 9, color: kGold, letterSpacing: 1.5)),
            ]),
            const SizedBox(height: 6),
            ...gaps.map((v) => Text('· $v',
                style: GoogleFonts.dmSans(fontSize: 11, color: kMuted))),
          ]),
        ),
      ],

      if (faltantes.isNotEmpty) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kAccent3.withAlpha(12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kAccent3.withAlpha(40)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.rocket_launch_outlined, color: kAccent3, size: 13),
              const SizedBox(width: 6),
              Text('EN DESARROLLO',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 9, color: kAccent3, letterSpacing: 1.5)),
            ]),
            const SizedBox(height: 6),
            ...faltantes.map((v) => Text('· $v',
                style: GoogleFonts.dmSans(fontSize: 11, color: kMuted))),
          ]),
        ),
      ],

      const SizedBox(height: 10),
      Text('ANÁLISIS IA · VERIFICA ANTES DE APOSTAR',
          style: GoogleFonts.jetBrainsMono(
              fontSize: 9, color: kMuted.withAlpha(120), letterSpacing: 1.5)),
    ]);
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;

  const _Tag(this.text, {required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: color == kSurface2
            ? Border.all(color: kBorder)
            : null,
      ),
      child: Text(text,
          style: GoogleFonts.jetBrainsMono(
              fontSize: 9, fontWeight: FontWeight.w700,
              color: textColor, letterSpacing: 1.5)),
    );
  }
}
