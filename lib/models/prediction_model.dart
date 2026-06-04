import 'package:flutter/material.dart';
import 'match_model.dart';

class PredictionModel {
  final int id;
  final int matchId;
  final MatchModel match;
  final DateTime generatedAt;

  final double homeWinPct;
  final double drawPct;
  final double awayWinPct;
  final double homeXg;
  final double awayXg;

  final int confidence;

  final double? projectedTotal;
  final double? ouLine;
  final double? overPct;
  final double? underPct;

  final String? homePitcherName;
  final double? homePitcherEra;
  final double? homePitcherK9;
  final String? awayPitcherName;
  final double? awayPitcherEra;
  final double? awayPitcherK9;

  final int?    h2hJuegos;
  final int?    h2hVictoriasLocal;
  final int?    h2hVictoriasVisit;
  final double? h2hRunsLocalAvg;
  final double? h2hRunsVisitAvg;

  final List<String> variablesUsadas;
  final List<String> variablesFaltantes;

  const PredictionModel({
    required this.id,
    required this.matchId,
    required this.match,
    required this.generatedAt,
    required this.homeWinPct,
    required this.drawPct,
    required this.awayWinPct,
    required this.homeXg,
    required this.awayXg,
    required this.confidence,
    this.projectedTotal,
    this.ouLine,
    this.overPct,
    this.underPct,
    this.homePitcherName,
    this.homePitcherEra,
    this.homePitcherK9,
    this.awayPitcherName,
    this.awayPitcherEra,
    this.awayPitcherK9,
    this.h2hJuegos,
    this.h2hVictoriasLocal,
    this.h2hVictoriasVisit,
    this.h2hRunsLocalAvg,
    this.h2hRunsVisitAvg,
    required this.variablesUsadas,
    required this.variablesFaltantes,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> j) => PredictionModel(
        id: j['id'],
        matchId: j['match_id'],
        match: MatchModel.fromJson(j['match']),
        generatedAt: DateTime.parse(j['generated_at']),
        homeWinPct: (j['home_win_pct'] as num).toDouble(),
        drawPct: (j['draw_pct'] as num).toDouble(),
        awayWinPct: (j['away_win_pct'] as num).toDouble(),
        homeXg: (j['home_xg'] as num).toDouble(),
        awayXg: (j['away_xg'] as num).toDouble(),
        confidence: j['confidence'],
        projectedTotal: (j['projected_total'] as num?)?.toDouble(),
        ouLine: (j['ou_line'] as num?)?.toDouble(),
        overPct: (j['over_pct'] as num?)?.toDouble(),
        underPct: (j['under_pct'] as num?)?.toDouble(),
        homePitcherName: j['home_pitcher_name'] as String?,
        homePitcherEra: (j['home_pitcher_era'] as num?)?.toDouble(),
        homePitcherK9: (j['home_pitcher_k9'] as num?)?.toDouble(),
        awayPitcherName: j['away_pitcher_name'] as String?,
        awayPitcherEra: (j['away_pitcher_era'] as num?)?.toDouble(),
        awayPitcherK9: (j['away_pitcher_k9'] as num?)?.toDouble(),
        h2hJuegos:          j['h2h_juegos'] as int?,
        h2hVictoriasLocal:  j['h2h_victorias_local'] as int?,
        h2hVictoriasVisit:  j['h2h_victorias_visit'] as int?,
        h2hRunsLocalAvg:    (j['h2h_runs_local_avg'] as num?)?.toDouble(),
        h2hRunsVisitAvg:    (j['h2h_runs_visit_avg'] as num?)?.toDouble(),
        variablesUsadas: List<String>.from(j['variables_usadas'] ?? []),
        variablesFaltantes: List<String>.from(j['variables_faltantes'] ?? []),
      );

  String get confidenceLabel {
    if (confidence >= 75) return 'Alta';
    if (confidence >= 45) return 'Media';
    return 'Baja';
  }

  Color get confidenceColor {
    if (confidence >= 75) return const Color(0xFF22c55e);
    if (confidence >= 45) return const Color(0xFFf59e0b);
    return const Color(0xFFef4444);
  }
}
