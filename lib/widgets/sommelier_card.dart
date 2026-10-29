import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/sommelier_info.dart';
import 'common.dart';

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

    final parts = <Widget>[
      if (info.tastingProfile != null)
        LabeledValue(l10n.tastingProfile, info.tastingProfile!),
      if (info.foodPairings.isNotEmpty)
        LabeledValue.custom(
          l10n.foodPairing,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final food in info.foodPairings)
                Chip(label: Text(food), visualDensity: VisualDensity.compact),
            ],
          ),
        ),
      if (info.servingTemperature != null)
        LabeledValue(l10n.servingTemperature, info.servingTemperature!),
      if (info.decanting != null) LabeledValue(l10n.decanting, info.decanting!),
      if (info.producerInfo != null)
        LabeledValue(l10n.aboutProducer, info.producerInfo!),
    ];

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
            for (final part in parts)
              Padding(padding: const EdgeInsets.only(top: 12), child: part),
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
