import 'package:flutter/material.dart';

import '../data/auth_service.dart';
import '../data/cellar_services.dart';
import '../data/photo_storage.dart';
import '../errors/error_messages.dart';
import '../l10n/app_localizations.dart';
import '../models/wine.dart';
import '../state/app_settings.dart';
import '../state/cellar_controller.dart';
import '../theme/motion.dart';
import '../widgets/display_helpers.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/wine_photo.dart';
import 'add_edit_wine_screen.dart';
import 'settings_screen.dart';
import 'wine_detail_screen.dart';

class CellarListScreen extends StatefulWidget {
  const CellarListScreen({
    super.key,
    required this.services,
    required this.settings,
    this.auth,
    this.demoMode = false,
  });

  final CellarServices services;
  final AppSettings settings;
  final AuthService? auth;
  final bool demoMode;

  @override
  State<CellarListScreen> createState() => _CellarListScreenState();
}

class _CellarListScreenState extends State<CellarListScreen> {
  late final _cellar = CellarController(widget.services.wines)..load();
  final _search = TextEditingController();

  @override
  void dispose() {
    _cellar.dispose();
    _search.dispose();
    super.dispose();
  }

  void _addWine() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          AddEditWineScreen(cellar: _cellar, services: widget.services),
    ),
  );

  void _openWine(Wine wine) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => WineDetailScreen(
        cellar: _cellar,
        services: widget.services,
        wineId: wine.id!,
      ),
    ),
  );

  void _clearFilters() {
    _search.clear();
    _cellar.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _cellar,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.appTitle),
          actions: [
            IconButton(
              tooltip: l10n.settings,
              icon: const Icon(Icons.settings_outlined),
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
        // The empty cellar has its own big "Add wine" button.
        floatingActionButton: _cellar.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: _addWine,
                icon: const Icon(Icons.add),
                label: Text(l10n.addWine),
              ),
        body: Column(
          children: [
            if (widget.demoMode) _DemoBanner(text: l10n.demoMode),
            if (!_cellar.isEmpty)
              _SearchAndFilterBar(cellar: _cellar, search: _search),
            Expanded(
              child: AnimatedSwitcher(
                duration: Motion.of(context, Motion.medium),
                switchInCurve: Motion.easeOut,
                switchOutCurve: Motion.easeOut,
                child: _body(context, l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n) {
    if (_cellar.loading && _cellar.isEmpty) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      );
    }
    final error = _cellar.error;
    if (error != null) {
      return _MessageView(
        key: const ValueKey('error'),
        icon: Icons.cloud_off_outlined,
        message: errorMessage(l10n, error),
        action: OutlinedButton(
          onPressed: _cellar.load,
          child: Text(l10n.retry),
        ),
      );
    }
    if (_cellar.isEmpty) {
      return _MessageView(
        key: const ValueKey('empty'),
        icon: Icons.wine_bar_outlined,
        title: l10n.emptyCellarTitle,
        message: l10n.emptyCellar,
        action: FilledButton.icon(
          onPressed: _addWine,
          icon: const Icon(Icons.add),
          label: Text(l10n.addWine),
        ),
      );
    }

    final wines = _cellar.visibleWines;
    final theme = Theme.of(context);
    return RefreshIndicator(
      key: const ValueKey('list'),
      onRefresh: _cellar.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              '${l10n.bottleCount(_cellar.totalBottles)} · '
              '${l10n.totalValue(formatMoney(context, _cellar.totalValue))}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (wines.isEmpty)
            _MessageView(
              icon: Icons.search_off,
              message: l10n.noResults,
              action: TextButton(
                onPressed: _clearFilters,
                child: Text(l10n.clearFilters),
              ),
            ),
          for (final (index, wine) in wines.indexed)
            Padding(
              key: ValueKey(wine.id),
              padding: const EdgeInsets.only(bottom: 8),
              child: FadeSlideIn(
                index: index,
                child: _WineCard(
                  wine: wine,
                  year: _cellar.currentYear,
                  photos: widget.services.photos,
                  onTap: () => _openWine(wine),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: scheme.onTertiaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: scheme.onTertiaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A centered icon, optional title, message and button, for empty and error
/// states.
class _MessageView extends StatelessWidget {
  const _MessageView({
    super.key,
    required this.icon,
    this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String? title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: scheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

class _SearchAndFilterBar extends StatelessWidget {
  const _SearchAndFilterBar({required this.cellar, required this.search});

  final CellarController cellar;
  final TextEditingController search;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textStyle = Theme.of(context).textTheme.bodyLarge;
    Widget oneLine(String text) =>
        Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // The hint disappears while typing, so screen readers get a label.
          Semantics(
            label: l10n.searchHint,
            child: TextField(
              controller: search,
              onChanged: cellar.setQuery,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: cellar.query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l10n.clearSearch,
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          search.clear();
                          cellar.setQuery('');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<WineType?>(
                  // Rebuilt with the new value when filters are cleared.
                  key: ValueKey(cellar.typeFilter),
                  initialValue: cellar.typeFilter,
                  isExpanded: true,
                  style: textStyle,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: l10n.wineType,
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: oneLine(l10n.all)),
                    for (final type in WineType.values)
                      DropdownMenuItem(
                        value: type,
                        child: oneLine(type.displayName(l10n)),
                      ),
                  ],
                  onChanged: cellar.setTypeFilter,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<DrinkingStatus?>(
                  key: ValueKey(cellar.statusFilter),
                  initialValue: cellar.statusFilter,
                  isExpanded: true,
                  style: textStyle,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: l10n.drinkingWindow,
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: oneLine(l10n.all)),
                    for (final status in DrinkingStatus.values)
                      DropdownMenuItem(
                        value: status,
                        child: oneLine(status.displayName(l10n)),
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

class _WineCard extends StatelessWidget {
  const _WineCard({
    required this.wine,
    required this.year,
    required this.photos,
    required this.onTap,
  });

  final Wine wine;
  final int year;
  final PhotoStorage photos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = wine.drinkingStatus(year);
    final title = wine.vintage == null
        ? wine.name
        : '${wine.name} ${wine.vintage}';
    final subtitle = [
      wine.producer,
      wine.region,
      wine.country,
    ].whereType<String>().join(' · ');

    // Read out as one sentence instead of separate pieces.
    final label = [
      title,
      if (subtitle.isNotEmpty) subtitle,
      l10n.bottleCount(wine.quantity),
      status.displayName(l10n),
    ].join(', ');

    return Semantics(
      label: label,
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      child: Card(
        child: Pressable(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (wine.photoPath case final path?)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox.square(
                      dimension: 56,
                      child: WinePhoto(photos: photos, path: path),
                    ),
                  )
                else
                  WineTypeBadge(type: wine.type),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      DrinkingStatusChip(status: status),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                RollingText(
                  '× ${wine.quantity}',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
