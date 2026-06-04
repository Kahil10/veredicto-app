import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/matches_provider.dart';
import '../widgets/match_card.dart';
import 'chat_screen.dart';
import 'match_detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      context.read<MatchesProvider>().loadMatches(token: token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [_MatchesTab(), ChatScreen(), ProfileScreen()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.sports_baseball_outlined),
              activeIcon: Icon(Icons.sports_baseball),
              label: 'Partidos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              activeIcon: Icon(Icons.auto_awesome),
              label: 'Vera'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil'),
        ],
      ),
    );
  }
}

class _MatchesTab extends StatelessWidget {
  const _MatchesTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MatchesProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt, color: kPurple, size: 22),
            SizedBox(width: 6),
            Text('Veredicto'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () =>
                provider.loadMatches(token: auth.token, syncLive: true),
            tooltip: 'Actualizar scores en vivo',
          ),
        ],
      ),
      body: Column(
        children: [
          // Sport selector + date picker
          _ControlBar(provider: provider, token: auth.token),
          // Match list
          Expanded(child: _MatchList(provider: provider, token: auth.token)),
        ],
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  final MatchesProvider provider;
  final String? token;
  const _ControlBar({required this.provider, this.token});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kSurface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Sport tabs
          Row(
            children: [
              _SportTab(
                label: '⚾ Béisbol',
                active: provider.sport == 'baseball',
                onTap: () => provider.setSport('baseball', token: token),
              ),
              const SizedBox(width: 8),
              _SportTab(
                label: '⚽ Fútbol',
                active: provider.sport == 'football',
                onTap: () => provider.setSport('football', token: token),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Date picker row
          _DateRow(provider: provider, token: token),
        ],
      ),
    );
  }
}

class _SportTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SportTab(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? kPurple : kCard,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(
              color: active ? Colors.white : kMuted,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            )),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final MatchesProvider provider;
  final String? token;
  const _DateRow({required this.provider, this.token});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dates = List.generate(
        16, (i) => today.subtract(Duration(days: 2)).add(Duration(days: i)));

    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = dates[i];
          final isSelected = DateFormat('yyyy-MM-dd').format(d) ==
              DateFormat('yyyy-MM-dd').format(provider.selectedDate);
          final isToday = DateFormat('yyyy-MM-dd').format(d) ==
              DateFormat('yyyy-MM-dd').format(today);
          return GestureDetector(
            onTap: () => provider.setDate(d, token: token),
            child: Container(
              width: 52,
              decoration: BoxDecoration(
                color: isSelected ? kPurple : kCard,
                borderRadius: BorderRadius.circular(10),
                border: isToday && !isSelected
                    ? Border.all(color: kPurple.withAlpha(120))
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(d).toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white70 : kMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    d.day.toString(),
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: isSelected ? Colors.white : kText),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MatchList extends StatelessWidget {
  final MatchesProvider provider;
  final String? token;
  const _MatchList({required this.provider, this.token});

  @override
  Widget build(BuildContext context) {
    if (provider.loading) {
      return const Center(
          child: CircularProgressIndicator(color: kPurple));
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_outlined, color: kMuted, size: 48),
              const SizedBox(height: 16),
              Text(provider.error!,
                  style: const TextStyle(color: kMuted),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => provider.loadMatches(token: token),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(provider.sport == 'baseball' ? '⚾' : '⚽',
                style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('Sin partidos este día',
                style: TextStyle(color: kMuted, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: kPurple,
      onRefresh: () => provider.loadMatches(token: token),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.matches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final match = provider.matches[i];
          return MatchCard(
            match: match,
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: provider,
                  child: MatchDetailScreen(match: match),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
