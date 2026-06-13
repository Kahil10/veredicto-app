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

  // Bullpen (relevistas)
  final double? homeBullpenEra;
  final String? homeBullpenLabel;
  final double? awayBullpenEra;
  final String? awayBullpenLabel;

  // Baloncesto — ratings, ritmo, descanso, H2H
  final double? bballHomeOrtg;
  final double? bballHomeDrtg;
  final double? bballAwayOrtg;
  final double? bballAwayDrtg;
  final double? bballGamePace;
  final int?    bballHomeRest;
  final int?    bballAwayRest;
  final bool?   bballHomeB2b;
  final bool?   bballAwayB2b;
  final int?    bballHomeGames;
  final int?    bballAwayGames;
  final int?    bballH2hJuegos;
  final int?    bballH2hLocal;
  final int?    bballH2hVisit;
  final double? bballInjuryHome;
  final double? bballInjuryAway;
  final List<Map<String, dynamic>>? bballPropsHome;
  final List<Map<String, dynamic>>? bballPropsAway;
  // Forma reciente
  final int?    bballHomeFormN;
  final int?    bballHomeFormW;
  final int?    bballHomeFormL;
  final String? bballHomeStreak;
  final double? bballHomeOffRecent;
  final double? bballHomeDefRecent;
  final int?    bballAwayFormN;
  final int?    bballAwayFormW;
  final int?    bballAwayFormL;
  final String? bballAwayStreak;
  final double? bballAwayOffRecent;
  final double? bballAwayDefRecent;

  // Ponches del pitcher
  final double? homeKMu;
  final double? homeKLine;
  final double? homeKOverPct;
  final double? homeKUnderPct;
  final double? awayKMu;
  final double? awayKLine;
  final double? awayKOverPct;
  final double? awayKUnderPct;

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
    this.homeBullpenEra,
    this.homeBullpenLabel,
    this.awayBullpenEra,
    this.awayBullpenLabel,
    this.bballHomeOrtg,
    this.bballHomeDrtg,
    this.bballAwayOrtg,
    this.bballAwayDrtg,
    this.bballGamePace,
    this.bballHomeRest,
    this.bballAwayRest,
    this.bballHomeB2b,
    this.bballAwayB2b,
    this.bballHomeGames,
    this.bballAwayGames,
    this.bballH2hJuegos,
    this.bballH2hLocal,
    this.bballH2hVisit,
    this.bballInjuryHome,
    this.bballInjuryAway,
    this.bballPropsHome,
    this.bballPropsAway,
    this.bballHomeFormN,
    this.bballHomeFormW,
    this.bballHomeFormL,
    this.bballHomeStreak,
    this.bballHomeOffRecent,
    this.bballHomeDefRecent,
    this.bballAwayFormN,
    this.bballAwayFormW,
    this.bballAwayFormL,
    this.bballAwayStreak,
    this.bballAwayOffRecent,
    this.bballAwayDefRecent,
    this.homeKMu,
    this.homeKLine,
    this.homeKOverPct,
    this.homeKUnderPct,
    this.awayKMu,
    this.awayKLine,
    this.awayKOverPct,
    this.awayKUnderPct,
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
        homeBullpenEra:   (j['home_bullpen_era'] as num?)?.toDouble(),
        homeBullpenLabel: j['home_bullpen_label'] as String?,
        awayBullpenEra:   (j['away_bullpen_era'] as num?)?.toDouble(),
        awayBullpenLabel: j['away_bullpen_label'] as String?,
        bballHomeOrtg: (j['bball_home_ortg'] as num?)?.toDouble(),
        bballHomeDrtg: (j['bball_home_drtg'] as num?)?.toDouble(),
        bballAwayOrtg: (j['bball_away_ortg'] as num?)?.toDouble(),
        bballAwayDrtg: (j['bball_away_drtg'] as num?)?.toDouble(),
        bballGamePace: (j['bball_game_pace'] as num?)?.toDouble(),
        bballHomeRest: (j['bball_home_rest'] as num?)?.toInt(),
        bballAwayRest: (j['bball_away_rest'] as num?)?.toInt(),
        bballHomeB2b:  j['bball_home_b2b'] as bool?,
        bballAwayB2b:  j['bball_away_b2b'] as bool?,
        bballHomeGames: (j['bball_home_games'] as num?)?.toInt(),
        bballAwayGames: (j['bball_away_games'] as num?)?.toInt(),
        bballH2hJuegos: (j['bball_h2h_juegos'] as num?)?.toInt(),
        bballH2hLocal:  (j['bball_h2h_local'] as num?)?.toInt(),
        bballH2hVisit:  (j['bball_h2h_visit'] as num?)?.toInt(),
        bballInjuryHome: (j['bball_injury_home'] as num?)?.toDouble(),
        bballInjuryAway: (j['bball_injury_away'] as num?)?.toDouble(),
        bballPropsHome: (j['bball_props_home'] as List?)
            ?.map((e) => (e as Map).cast<String, dynamic>())
            .toList(),
        bballPropsAway: (j['bball_props_away'] as List?)
            ?.map((e) => (e as Map).cast<String, dynamic>())
            .toList(),
        bballHomeFormN: (j['bball_home_form_n'] as num?)?.toInt(),
        bballHomeFormW: (j['bball_home_form_w'] as num?)?.toInt(),
        bballHomeFormL: (j['bball_home_form_l'] as num?)?.toInt(),
        bballHomeStreak: j['bball_home_streak'] as String?,
        bballHomeOffRecent: (j['bball_home_off_recent'] as num?)?.toDouble(),
        bballHomeDefRecent: (j['bball_home_def_recent'] as num?)?.toDouble(),
        bballAwayFormN: (j['bball_away_form_n'] as num?)?.toInt(),
        bballAwayFormW: (j['bball_away_form_w'] as num?)?.toInt(),
        bballAwayFormL: (j['bball_away_form_l'] as num?)?.toInt(),
        bballAwayStreak: j['bball_away_streak'] as String?,
        bballAwayOffRecent: (j['bball_away_off_recent'] as num?)?.toDouble(),
        bballAwayDefRecent: (j['bball_away_def_recent'] as num?)?.toDouble(),
        homeKMu:        (j['home_k_mu']        as num?)?.toDouble(),
        homeKLine:      (j['home_k_line']       as num?)?.toDouble(),
        homeKOverPct:   (j['home_k_over_pct']   as num?)?.toDouble(),
        homeKUnderPct:  (j['home_k_under_pct']  as num?)?.toDouble(),
        awayKMu:        (j['away_k_mu']         as num?)?.toDouble(),
        awayKLine:      (j['away_k_line']        as num?)?.toDouble(),
        awayKOverPct:   (j['away_k_over_pct']    as num?)?.toDouble(),
        awayKUnderPct:  (j['away_k_under_pct']   as num?)?.toDouble(),
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
