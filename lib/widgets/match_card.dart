import 'package:flutter/material.dart';
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
    final isNBAorNFL =
        sport == 'basketball' || sport == 'american_football';
    final isTheSportsDB =
        sport == 'baseball_lvbp' || sport == 'football_ven';
    final flagUrl = sport == 'football' ? footballFlagUrl(name) : null;

    return Column(
      crossAxisAlignment:
          isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Fútbol internacional: bandera de país
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
        // NBA / NFL: crest PNG desde ESPN CDN
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
        // LVBP / Fútbol VEN: logo PNG desde TheSportsDB
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
    if (match.isPostponed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('PPD',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kMuted)),
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
            Icon(Icons.circle, size: 6, color: Colors.white),
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
