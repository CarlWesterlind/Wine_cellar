import 'package:flutter/material.dart';

import '../data/auth_service.dart';
import '../data/cellar_services.dart';
import '../data/photo_storage.dart';
import '../errors/error_messages.dart';
import '../l10n/app_localizations.dart';
import '../models/wine.dart';
import '../state/app_settings.dart';
import '../state/cellar_controller.dart';
import '../widgets/common.dart';
import '../widgets/display_helpers.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/wine_photo.dart';
import 'add_edit_wine_screen.dart';
import 'export_cellar.dart';
import 'settings_screen.dart';
import 'wine_detail_screen.dart';

/// The wines as a searchable list of cards.
class CellarListScreen extends StatefulWidget {
  const CellarListScreen({
    super.key,
    required this.cellar,
    required this.services,
    required this.settings,
    this.auth,
  });

  final CellarController cellar;
  final CellarServices services;
  final AppSettings settings;
  final AuthService? auth;

  @override
  State<CellarListScreen> createState() => _CellarListScreenState();
}

class _CellarListScreenState extends State<CellarListScreen> {
  final _search = TextEditingController();

  CellarController get _cellar => widget.cellar;

  @override
  void dispose() {
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
            if (!_cellar.isEmpty)
              Builder(
                // Its own context, so the share sheet can point at it.
                builder: (context) => IconButton(
                  tooltip: l10n.exportCsv,
                  icon: const Icon(Icons.ios_share),
                  onPressed: () =>
                      exportCellar(context, _cellar, widget.services),
                ),
              ),
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
            if (widget.services.isDemo)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: NoticeBanner(
                  icon: Icons.info_outline,
                  text: l10n.demoMode,
                ),
              ),
            if (!_cellar.isEmpty)
              _SearchAndFilterBar(cellar: _cellar, search: _search),
            Expanded(child: FadeSwitcher(child: _body(context, l10n))),
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
      return MessageView(
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
      return MessageView(
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
            MessageView(
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
    // The search field is rounded at the ends, unlike other fields.
    final pill = OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide.none,
    );
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
                border: pill,
                enabledBorder: pill,
                focusedBorder: pill.copyWith(
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
                      child: WinePhoto(
                        photos: photos,
                        path: path,
                        thumbnailSize: 56,
                      ),
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
