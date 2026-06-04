import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: user == null
          ? const Center(child: CircularProgressIndicator(color: kPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Avatar card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [kPurple, kPurpleDark],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                user.username[0].toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(user.username,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700)),
                          if (user.email != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(user.email!,
                                  style: const TextStyle(
                                      color: kMuted, fontSize: 13)),
                            ),
                          const SizedBox(height: 14),
                          _RoleBadge(role: user.role),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Estado según rol
                  if (user.role == 'admin')
                    _AdminCard()
                  else if (user.isPremiumActive)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFf59e0b).withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.star_rounded,
                                  color: Color(0xFFf59e0b), size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Plan Premium activo',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15)),
                                  if (user.premiumUntil != null)
                                    Text(
                                      'Vence: ${DateFormat('d MMM yyyy').format(user.premiumUntil!)}',
                                      style: const TextStyle(
                                          color: kMuted, fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    _UpgradeCard(),

                  const SizedBox(height: 12),

                  // Créditos
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22c55e).withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.toll_rounded,
                                color: Color(0xFF22c55e), size: 28),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Créditos disponibles',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              Text('${user.credits} créditos',
                                  style: const TextStyle(
                                      color: kMuted, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Cerrar sesión
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFef4444),
                        side: const BorderSide(
                            color: Color(0xFFef4444), width: .8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        await auth.logout();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesión'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isPremium = role == 'premium';
    final isAdmin = role == 'admin';
    final color = isAdmin
        ? kPurple
        : isPremium
            ? const Color(0xFFf59e0b)
            : kMuted;
    final label = isAdmin ? 'Admin' : isPremium ? 'Premium' : 'Free';
    final icon = isAdmin
        ? Icons.shield_outlined
        : isPremium
            ? Icons.star_outlined
            : Icons.person_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              kPurple.withAlpha(30),
              kPurpleDark.withAlpha(20),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star_outline, color: kPurple),
                const SizedBox(width: 10),
                const Text('Hazte Premium',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kPurple,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('\$3/mes',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _BenefitRow('Análisis ilimitados por día'),
            _BenefitRow('Pitchers, H2H y O/U en cada partido'),
            _BenefitRow('Chat Vera IA sin restricciones'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¿Cómo pagar?',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  SizedBox(height: 6),
                  Text(
                    '1. Pago Móvil o USDT\n'
                    '2. Envía el comprobante por Telegram\n'
                    '3. El admin activa tu cuenta en minutos',
                    style: TextStyle(color: kMuted, fontSize: 12, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF229ED9),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 18),
                label: const Text('Activar Premium por Telegram',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                onPressed: () => launchUrl(
                  Uri.parse(kTelegramUrl),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [kPurple.withAlpha(30), kPurpleDark.withAlpha(20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.admin_panel_settings_rounded,
                  color: kPurple, size: 22),
              const SizedBox(width: 10),
              const Text('Panel de Administración',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ]),
            const SizedBox(height: 12),
            _AdminRow(Icons.people_outline, 'Ver y gestionar usuarios'),
            _AdminRow(Icons.star_outline, 'Activar / desactivar Premium'),
            _AdminRow(Icons.toll_outlined, 'Asignar créditos a usuarios'),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPurple,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.open_in_browser_rounded,
                    color: Colors.white, size: 18),
                label: const Text('Abrir Panel Web',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                onPressed: () => launchUrl(
                  Uri.parse('${kBaseUrl.replaceAll('/api', '')}/admin/'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _AdminRow(this.icon, this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, color: kPurple, size: 15),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: kText, fontSize: 13)),
      ]),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String text;
  const _BenefitRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: kPurple, size: 16),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: kText, fontSize: 13)),
        ],
      ),
    );
  }
}
