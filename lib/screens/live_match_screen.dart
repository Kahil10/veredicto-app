import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/match_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/live_game_widget.dart';

class LiveMatchScreen extends StatelessWidget {
  final MatchModel match;
  const LiveMatchScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final token = context.read<AuthProvider>().token;
    final away  = _short(match.awayTeam);
    final home  = _short(match.homeTeam);

    return Scaffold(
      appBar: AppBar(
        title: Text('$away vs $home'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF22c55e).withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF22c55e).withAlpha(70)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF22c55e),
                  ),
                ),
                const SizedBox(width: 5),
                Text('EN VIVO',
                    style: dmSans(10, weight: FontWeight.w700,
                        color: const Color(0xFF22c55e))),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: LiveGameWidget(match: match, token: token),
      ),
    );
  }

  String _short(String full) {
    final parts = full.split(' ');
    return parts.length > 1 ? parts.last : full;
  }
}
