import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/sommelier_info.dart';

/// The AI's sommelier notes, clearly marked as AI suggestions. With
/// [onRemove] the card has a button to discard them.
class SommelierCard extends StatelessWidget {
  const SommelierCard({super.key, required this.info, this.onRemove});

  final SommelierInfo info;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget part(String label, Widget child) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );

    Widget text(String value) => Text(value, style: theme.textTheme.bodyLarge);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.sommelier,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    tooltip: l10n.removeSommelier,
                    icon: const Icon(Icons.close),
                    onPressed: onRemove,
                  ),
              ],
            ),
            if (info.tastingProfile case final taste?)
              part(l10n.tastingProfile, text(taste)),
            if (info.foodPairings.isNotEmpty)
              part(
                l10n.foodPairing,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final food in info.foodPairings)
                      Chip(
                        label: Text(food),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
            if (info.servingTemperature case final temperature?)
              part(l10n.servingTemperature, text(temperature)),
            if (info.decanting case final decanting?)
              part(l10n.decanting, text(decanting)),
            if (info.producerInfo case final producer?)
              part(l10n.aboutProducer, text(producer)),
            const SizedBox(height: 12),
            Text(
              l10n.aiDisclaimer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
