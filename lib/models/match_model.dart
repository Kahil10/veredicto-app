class LeagueSummary {
  final int id;
  final String name;
  final String? country;
  final String sport;

  const LeagueSummary({
    required this.id,
    required this.name,
    this.country,
    required this.sport,
  });

  factory LeagueSummary.fromJson(Map<String, dynamic> j) => LeagueSummary(
        id: j['id'],
        name: j['name'],
        country: j['country'],
        sport: j['sport'],
      );
}

class MatchModel {
  final int id;
  final int externalId;
  final String sport;
  final LeagueSummary league;
  final String homeTeam;
  final String awayTeam;
  final int? homeTeamId;
  final int? awayTeamId;
  final DateTime kickoff;
  final String? venue;
  final String status;
  final int? homeScore;
  final int? awayScore;
  final DateTime lastUpdated;

  const MatchModel({
    required this.id,
    required this.externalId,
    required this.sport,
    required this.league,
    required this.homeTeam,
    required this.awayTeam,
    this.homeTeamId,
    this.awayTeamId,
    required this.kickoff,
    this.venue,
    required this.status,
    this.homeScore,
    this.awayScore,
    required this.lastUpdated,
  });

  factory MatchModel.fromJson(Map<String, dynamic> j) => MatchModel(
        id: j['id'],
        externalId: j['external_id'],
        sport: j['sport'],
        league: LeagueSummary.fromJson(j['league']),
        homeTeam: j['home_team'],
        awayTeam: j['away_team'],
        homeTeamId: j['home_team_id'] as int?,
        awayTeamId: j['away_team_id'] as int?,
        kickoff: DateTime.parse(j['kickoff']).toLocal(),
        venue: j['venue'],
        status: j['status'],
        homeScore: j['home_score'],
        awayScore: j['away_score'],
        lastUpdated: DateTime.parse(j['last_updated']).toLocal(),
      );

  bool get isLive => ['1H', '2H', 'HT', 'ET', 'BT', 'P', 'LIVE'].contains(status);
  bool get isFinished => ['FT', 'AET', 'PEN', 'F', 'Final'].contains(status);
  bool get isScheduled => status == 'NS';
}
