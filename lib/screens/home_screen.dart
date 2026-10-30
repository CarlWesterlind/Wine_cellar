import 'package:flutter/material.dart';

import '../data/auth_service.dart';
import '../data/cellar_services.dart';
import '../l10n/app_localizations.dart';
import '../state/app_settings.dart';
import '../state/cellar_controller.dart';
import 'cellar_list_screen.dart';
import 'cellar_map_screen.dart';
import 'history_screen.dart';
import 'stats_screen.dart';

/// The four main views behind a bottom navigation bar. They share one
/// [CellarController], so drinking a bottle in the list updates the map,
/// statistics and history at once.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.services,
    required this.settings,
    this.auth,
  });

  final CellarServices services;
  final AppSettings settings;
  final AuthService? auth;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final _cellar = CellarController(
    widget.services.wines,
    widget.services.photos,
  )..load();
  var _tab = 0;

  @override
  void dispose() {
    _cellar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      // Keeps each view, with its scroll position, while another is shown.
      body: IndexedStack(
        index: _tab,
        children: [
          CellarListScreen(
            cellar: _cellar,
            services: widget.services,
            settings: widget.settings,
            auth: widget.auth,
          ),
          CellarMapScreen(cellar: _cellar, services: widget.services),
          StatsScreen(cellar: _cellar, services: widget.services),
          HistoryScreen(cellar: _cellar, services: widget.services),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (tab) => setState(() => _tab = tab),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.wine_bar_outlined),
            selectedIcon: const Icon(Icons.wine_bar),
            label: l10n.navCellar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view),
            label: l10n.navMap,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: l10n.navStats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: l10n.navHistory,
          ),
        ],
      ),
    );
  }
}
