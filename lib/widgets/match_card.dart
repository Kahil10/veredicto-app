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
  final int? score;
  final bool isWinner;
  final bool isRight;
  final String? crestUrl;

  const _TeamColumn({
    required this.name,
    this.score,
    this.isWinner = false,
    this.isRight = false,
    this.crestUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (footballFlagUrl(name) != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Image.network(
                footballFlagUrl(name)!,
                width: 40,
                height: 27,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, prog) =>
                    prog == null ? child : const SizedBox(width: 40, height: 27),
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
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
    final isBaseball = sport == 'baseball';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: (isBaseball ? const Color(0xFF0ea5e9) : kPurple).withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isBaseball ? '⚾' : '⚽',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
