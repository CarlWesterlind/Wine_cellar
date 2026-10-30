import 'package:flutter/material.dart';

import '../data/cellar_services.dart';
import '../l10n/app_localizations.dart';
import '../models/cellar_stats.dart';
import '../models/wine.dart';
import '../state/cellar_controller.dart';
import '../theme/motion.dart';
import '../widgets/common.dart';
import '../widgets/display_helpers.dart';
import 'wine_detail_screen.dart';

/// Overview, drinking windows and what the cellar is made of.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.cellar, required this.services});

  final CellarController cellar;
  final CellarServices services;

  /// Bars shown for countries and grapes; the rest are summed as "Other".
  static const _topCount = 5;

  void _openWine(BuildContext context, Wine wine) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => WineDetailScreen(
        cellar: cellar,
        services: services,
        wineId: wine.id!,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navStats)),
      body: ListenableBuilder(
        listenable: cellar,
        builder: (context, _) {
          final stats = cellar.stats;
          if (stats.bottles == 0) {
            return MessageView(
              icon: Icons.bar_chart,
              title: l10n.statsEmptyTitle,
              message: l10n.statsEmpty,
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _Overview(stats: stats),
              const SizedBox(height: 16),
              _DrinkingWindowCard(
                stats: stats,
                onOpen: (wine) => _openWine(context, wine),
              ),
              const SizedBox(height: 16),
              _BarCard(
                title: l10n.byType,
                bars: [
                  for (final entry in stats.byType.sorted)
                    (entry.key.displayName(l10n), entry.value),
                ],
              ),
              if (!stats.byCountry.isEmpty) ...[
                const SizedBox(height: 16),
                _BarCard(
                  title: l10n.byCountry,
                  bars: _withOther(l10n, stats.byCountry),
                ),
              ],
              if (!stats.byGrape.isEmpty) ...[
                const SizedBox(height: 16),
                _BarCard(
                  title: l10n.byGrape,
                  bars: _withOther(l10n, stats.byGrape),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// The largest names, then the rest summed as "Other".
  List<(String, int)> _withOther(AppLocalizations l10n, NameTally tally) {
    final (top, rest) = tally.top(_topCount);
    return [
      for (final entry in top) (entry.key, entry.value),
      if (rest > 0) (l10n.otherItems, rest),
    ];
  }
}

/// Four headline numbers.
class _Overview extends StatelessWidget {
  const _Overview({required this.stats});

  final CellarStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tiles = [
      (l10n.bottles, '${stats.bottles}'),
      (l10n.wines, '${stats.wines}'),
      (l10n.cellarValue, formatMoney(context, stats.value)),
      if (stats.averagePrice case final average?)
        (l10n.averagePrice, formatMoney(context, average.roundToDouble())),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        // Two per row on phones, four on wider screens.
        final perRow = constraints.maxWidth > 600 ? 4 : 2;
        final width = (constraints.maxWidth - 8 * (perRow - 1)) / perRow;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, value) in tiles)
              SizedBox(
                width: width,
                child: _StatTile(label: label, value: value),
              ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A container of its own, or screen readers merge all tiles into one.
    return Semantics(
      container: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 2,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottles per drinking status, and the wines to drink before the year
/// ends.
class _DrinkingWindowCard extends StatelessWidget {
  const _DrinkingWindowCard({required this.stats, required this.onOpen});

  final CellarStats stats;
  final ValueChanged<Wine> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _SectionCard(
      title: l10n.drinkingWindow,
      children: [
        _BarList(
          bars: [
            for (final status in DrinkingStatus.values)
              if (stats.byStatus[status] > 0)
                (status.displayName(l10n), stats.byStatus[status]),
          ],
          colors: [
            for (final status in DrinkingStatus.values)
              if (stats.byStatus[status] > 0) status.colors(context).$1,
          ],
        ),
        if (stats.lastYear.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(l10n.drinkThisYear, style: theme.textTheme.titleSmall),
          for (final wine in stats.lastYear)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: WineTypeBadge(type: wine.type, size: 36),
              title: Text(wine.name),
              subtitle: Text(l10n.bottleCount(wine.quantity)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onOpen(wine),
            ),
        ],
      ],
    );
  }
}

class _BarCard extends StatelessWidget {
  const _BarCard({required this.title, required this.bars});

  final String title;
  final List<(String, int)> bars;

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: title,
    children: [_BarList(bars: bars)],
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Horizontal bars with a label and the number of bottles. Every bar has
/// its number written out, so color is never needed to read it.
class _BarList extends StatelessWidget {
  const _BarList({required this.bars, this.colors});

  final List<(String, int)> bars;

  /// One per bar; the theme's primary color if null.
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final largest = bars.fold(1, (max, bar) => bar.$2 > max ? bar.$2 : max);
    return Column(
      children: [
        for (final (index, (label, count)) in bars.indexed)
          Semantics(
            container: true,
            label: '$label: ${l10n.bottleCount(count)}',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(label, style: theme.textTheme.bodyMedium),
                      ),
                      Text(
                        '$count',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _Bar(
                    fraction: count / largest,
                    color: colors?[index] ?? theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(4);
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: radius,
      ),
      alignment: Alignment.centerLeft,
      child: AnimatedFractionallySizedBox(
        duration: Motion.of(context, Motion.medium),
        curve: Motion.easeInOut,
        widthFactor: fraction,
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, borderRadius: radius),
        ),
      ),
    );
  }
}
