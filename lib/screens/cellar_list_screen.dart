import 'package:flutter/material.dart';

import '../data/auth_service.dart';
import '../data/wine_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/wine.dart';
import '../state/cellar_controller.dart';
import '../state/language_settings.dart';
import '../widgets/display_helpers.dart';
import 'add_edit_wine_screen.dart';
import 'settings_screen.dart';
import 'wine_detail_screen.dart';

class CellarListScreen extends StatefulWidget {
  const CellarListScreen({
    super.key,
    required this.repository,
    required this.settings,
    this.auth,
    this.demoMode = false,
  });

  final WineRepository repository;
  final LanguageSettings settings;
  final AuthService? auth;
  final bool demoMode;

  @override
  State<CellarListScreen> createState() => _CellarListScreenState();
}

class _CellarListScreenState extends State<CellarListScreen> {
  late final _cellar = CellarController(widget.repository)..load();

  @override
  void dispose() {
    _cellar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SettingsScreen(
                  settings: widget.settings,
                  auth: widget.auth,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AddEditWineScreen(cellar: _cellar),
          ),
        ),
        icon: const Icon(Icons.add),
        label: Text(l10n.addWine),
      ),
      body: ListenableBuilder(
        listenable: _cellar,
        builder: (context, _) => Column(
          children: [
            if (widget.demoMode)
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.tertiaryContainer,
                padding: const EdgeInsets.all(8),
                child: Text(l10n.demoMode, textAlign: TextAlign.center),
              ),
            _SearchAndFilterBar(cellar: _cellar),
            Expanded(child: _body(context, l10n)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n) {
    if (_cellar.loading && _cellar.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = _cellar.error;
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.errorGeneric('$error'), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _cellar.load, child: Text(l10n.retry)),
          ],
        ),
      );
    }
    if (_cellar.isEmpty) {
      return Center(child: Text(l10n.emptyCellar));
    }

    final wines = _cellar.visibleWines;
    return RefreshIndicator(
      onRefresh: _cellar.load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              '${l10n.bottleCount(_cellar.totalBottles)} · '
              '${l10n.totalValue(formatMoney(context, _cellar.totalValue))}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          if (wines.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(l10n.noResults, textAlign: TextAlign.center),
            ),
          for (final wine in wines)
            _WineListTile(
              wine: wine,
              year: _cellar.currentYear,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      WineDetailScreen(cellar: _cellar, wineId: wine.id!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchAndFilterBar extends StatelessWidget {
  const _SearchAndFilterBar({required this.cellar});

  final CellarController cellar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          SearchBar(
            hintText: l10n.searchHint,
            leading: const Icon(Icons.search),
            onChanged: cellar.setQuery,
            elevation: const WidgetStatePropertyAll(0),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<WineType?>(
                  initialValue: cellar.typeFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(isDense: true),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.allTypes)),
                    for (final type in WineType.values)
                      DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName(l10n)),
                      ),
                  ],
                  onChanged: cellar.setTypeFilter,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<DrinkingStatus?>(
                  initialValue: cellar.statusFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(isDense: true),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.allStatuses),
                    ),
                    for (final status in DrinkingStatus.values)
                      DropdownMenuItem(
                        value: status,
                        child: Text(status.displayName(l10n)),
                      ),
                  ],
                  onChanged: cellar.setStatusFilter,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WineListTile extends StatelessWidget {
  const _WineListTile({
    required this.wine,
    required this.year,
    required this.onTap,
  });

  final Wine wine;
  final int year;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      wine.producer,
      wine.region,
      wine.country,
    ].whereType<String>().join(' · ');
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: wine.type.color,
        child: const Icon(Icons.wine_bar, color: Colors.white),
      ),
      title: Text(
        wine.vintage == null ? wine.name : '${wine.name} ${wine.vintage}',
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle.isNotEmpty) Text(subtitle),
          const SizedBox(height: 4),
          DrinkingStatusChip(status: wine.drinkingStatus(year)),
        ],
      ),
      trailing: Text(
        '× ${wine.quantity}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
