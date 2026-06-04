class UserModel {
  final int id;
  final String username;
  final String? email;
  final String role;
  final DateTime? premiumUntil;
  final int credits;
  final bool isPremiumActive;
  final int dailyPredCount;

  const UserModel({
    required this.id,
    required this.username,
    this.email,
    required this.role,
    this.premiumUntil,
    required this.credits,
    required this.isPremiumActive,
    this.dailyPredCount = 0,
  });

  bool get isFree => role == 'free' && !isPremiumActive;
  int get analysesLeft => (2 - dailyPredCount).clamp(0, 2);

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'],
        username: j['username'],
        email: j['email'],
        role: j['role'],
        premiumUntil: j['premium_until'] != null
            ? DateTime.parse(j['premium_until']).toLocal()
            : null,
        credits: j['credits'],
        isPremiumActive: j['is_premium_active'] ?? false,
        dailyPredCount: j['daily_pred_count'] ?? 0,
      );
}
