import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../core/flags.dart';
import '../core/theme.dart';
import '../models/match_model.dart';

class MatchCard extends StatelessWidget {
  final MatchModel match;
  final VoidCallback? onTap;

  const MatchCard({super.key, required this.match, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SportChip(match.sport),
                  const SizedBox(width: 8),
                  Text(match.league.name,
                      style: const TextStyle(color: kMuted, fontSize: 12)),
                  const Spacer(),
                  _StatusBadge(match),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _TeamColumn(
                      name: match.homeTeam,
                      sport: match.sport,
                      score: match.homeScore,
                      isWinner: match.isFinished &&
                          match.homeScore != null &&
                          match.awayScore != null &&
                          match.homeScore! > match.awayScore!,
                      crestUrl: match.homeTeamCrest,
                    ),
                  ),
                  _ScoreOrTime(match),
                  Expanded(
                    child: _TeamColumn(
                      name: match.awayTeam,
                      sport: match.sport,
                      score: match.awayScore,
                      isWinner: match.isFinished &&
                          match.homeScore != null &&
                          match.awayScore != null &&
                          match.awayScore! > match.homeScore!,
                      isRight: true,
                      crestUrl: match.awayTeamCrest,
                    ),
                  ),
                ],
              ),
              if (match.venue != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: kMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(match.venue!,
                          style:
                              const TextStyle(color: kMuted, fontSize: 11),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  final String name;
  final String sport;
  final int? score;
  final bool isWinner;
  final bool isRight;
  final String? crestUrl;

  const _TeamColumn({
    required this.name,
    this.sport = 'football',
    this.score,
    this.isWinner = false,
    this.isRight = false,
    this.crestUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isBaseball    = sport == 'baseball';
    final isNBAorNFL    = sport == 'basketball' || sport == 'american_football';
    final isTheSportsDB = sport == 'baseball_lvbp' || sport == 'football_ven';
    // Para fútbol: bandera si es selección nacional (Copa del Mundo), escudo si hay crestUrl (liga de clubes)
    final flagUrl = sport == 'football' ? footballFlagUrl(name) : null;
    final hasFootballCrest = sport == 'football' && crestUrl != null && flagUrl == null;

    return Column(
      crossAxisAlignment:
          isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Béisbol MLB: SVG oficial de mlbstatic.com
        if (isBaseball)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _MlbLogo(name: name, crestUrl: crestUrl, size: 36, isRight: isRight),
          ),
        // Fútbol internacional Copa del Mundo: bandera de país
        if (flagUrl != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Image.network(
                flagUrl,
                width: 40,
                height: 27,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, prog) =>
                    prog == null ? child : const SizedBox(width: 40, height: 27),
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        // Fútbol ligas de clubes (Premier, La Liga, Champions, etc.): escudo directo
        if (hasFootballCrest)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Image.network(
              crestUrl!,
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              loadingBuilder: (_, child, prog) =>
                  prog == null ? child : const SizedBox(width: 36, height: 36),
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        // NBA / NFL / WNBA / NCAA Basketball / NCAA Football / CFL: crest PNG desde ESPN CDN
        if (isNBAorNFL && crestUrl != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Image.network(
              crestUrl!,
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              loadingBuilder: (_, child, prog) =>
                  prog == null ? child : const SizedBox(width: 36, height: 36),
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        // LVBP / Fútbol VEN / ligas menores béisbol: logo PNG desde TheSportsDB
        if (isTheSportsDB && crestUrl != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Image.network(
              crestUrl!,
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              loadingBuilder: (_, child, prog) =>
                  prog == null ? child : const SizedBox(width: 36, height: 36),
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        Text(
          name,
          style: TextStyle(
            fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
            color: isWinner ? kText : kMuted,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: isRight ? TextAlign.right : TextAlign.left,
        ),
      ],
    );
  }
}

class _ScoreOrTime extends StatelessWidget {
  final MatchModel match;
  const _ScoreOrTime(this.match);

  @override
  Widget build(BuildContext context) {
    // Estados especiales: suspendido / cancelado / pospuesto → etiqueta clara
    // (antes caían al "else" y mostraban la hora, como si no hubieran empezado).
    final especial = match.estadoEspecial;
    if (especial != null) {
      final rojo = match.isCanceled || match.isSuspended;
      final color = rojo ? const Color(0xFFef4444) : kGold;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(28),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(90)),
        ),
        child: Text(especial,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
      );
    }
    if (match.isLive || match.isFinished) {
      final home = match.homeScore ?? 0;
      final away = match.awayScore ?? 0;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: match.isLive
              ? const Color(0xFF22c55e).withAlpha(25)
              : kSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$home - $away',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: match.isLive ? const Color(0xFF22c55e) : kText,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        DateFormat('HH:mm').format(match.kickoff),
        style: const TextStyle(
            color: kMuted, fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final MatchModel match;
  const _StatusBadge(this.match);

  @override
  Widget build(BuildContext context) {
    if (match.isLive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF22c55e),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LiveBadgeDot(),
            SizedBox(width: 4),
            Text('EN VIVO',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }
    if (match.isPostponed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.orange.withAlpha(40),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('POSPUESTO',
            style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.w600)),
      );
    }
    if (match.isFinished) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: kMuted.withAlpha(40),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('FINAL',
            style: TextStyle(color: kMuted, fontSize: 10, fontWeight: FontWeight.w600)),
      );
    }
    return const SizedBox.shrink();
  }
}

// ── Punto blanco pulsante para el badge EN VIVO ──────────────────────────────

class _LiveBadgeDot extends StatefulWidget {
  const _LiveBadgeDot();

  @override
  State<_LiveBadgeDot> createState() => _LiveBadgeDotState();
}

class _LiveBadgeDotState extends State<_LiveBadgeDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.35, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(_anim.value),
        ),
      ),
    );
  }
}

// ── Logo SVG para equipos MLB ─────────────────────────────────────────────────

class _MlbLogo extends StatelessWidget {
  final String name;
  final String? crestUrl;
  final double size;
  final bool isRight;

  const _MlbLogo({
    required this.name,
    this.crestUrl,
    this.size = 36,
    this.isRight = false,
  });

  @override
  Widget build(BuildContext context) {
    // Si hay crestUrl directa (URL de mlbstatic ya incluida en el modelo), usarla
    if (crestUrl != null) {
      if (crestUrl!.endsWith('.svg')) {
        return SvgPicture.network(
          crestUrl!,
          width: size,
          height: size,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => _initials(),
        );
      }
      return Image.network(
        crestUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        loadingBuilder: (_, child, prog) =>
            prog == null ? child : SizedBox(width: size, height: size),
        errorBuilder: (_, __, ___) => _initials(),
      );
    }
    return _initials();
  }

  Widget _initials() {
    final parts = name.trim().split(' ');
    final init = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'
        : name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          init,
          style: TextStyle(
            fontSize: size * 0.36,
            color: kMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SportChip extends StatelessWidget {
  final String sport;
  const _SportChip(this.sport);

  @override
  Widget build(BuildContext context) {
    final String emoji;
    final Color chipColor;
    switch (sport) {
      case 'baseball':
        emoji = '⚾';
        chipColor = const Color(0xFF0ea5e9);
        break;
      case 'baseball_lvbp':
        emoji = '⚾';
        chipColor = const Color(0xFFFFAA00);
        break;
      case 'basketball':
        emoji = '🏀';
        chipColor = const Color(0xFFf97316);
        break;
      case 'american_football':
        emoji = '🏈';
        chipColor = const Color(0xFF8b5cf6);
        break;
      case 'football_ven':
        emoji = '🇻🇪';
        chipColor = const Color(0xFF0066CC);
        break;
      default:
        emoji = '⚽';
        chipColor = kPurple;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 12)),
    );
  }
}
