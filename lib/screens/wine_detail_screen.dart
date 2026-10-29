import 'package:flutter/material.dart';

import '../errors/error_messages.dart';
import '../l10n/app_localizations.dart';
import '../models/wine.dart';
import '../state/cellar_controller.dart';
import '../widgets/display_helpers.dart';
import 'add_edit_wine_screen.dart';

class WineDetailScreen extends StatelessWidget {
  const WineDetailScreen({
    super.key,
    required this.cellar,
    required this.wineId,
  });

  final CellarController cellar;
  final String wineId;

  Future<void> _confirmDelete(BuildContext context, Wine wine) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteWine),
        content: Text(l10n.deleteConfirm(wine.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final deleted = await runOrShowError(
      context,
      () => cellar.delete(wine.id!),
    );
    if (deleted && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: cellar,
      builder: (context, _) {
        final wine = cellar.byId(wineId);
        // The wine is gone while the screen pops after a delete.
        if (wine == null) return const Scaffold();

        final status = wine.drinkingStatus(cellar.currentYear);
        return Scaffold(
          appBar: AppBar(
            title: Text(wine.name),
            actions: [
              IconButton(
                tooltip: l10n.editWine,
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        AddEditWineScreen(cellar: cellar, wine: wine),
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.deleteWine,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, wine),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: wine.type.color,
                    child: const Icon(Icons.wine_bar, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wine.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (wine.producer != null) Text(wine.producer!),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    l10n.bottleCount(wine.quantity),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: wine.quantity == 0
                        ? null
                        : () => runOrShowError(
                            context,
                            () => cellar.drinkOne(wine),
                          ),
                    icon: const Icon(Icons.local_bar),
                    label: Text(l10n.drinkOne),
                  ),
                ],
              ),
              const Divider(height: 32),
              _InfoRow(l10n.wineType, wine.type.displayName(l10n)),
              _InfoRow(l10n.vintage, wine.vintage?.toString()),
              _InfoRow(l10n.country, wine.country),
              _InfoRow(l10n.region, wine.region),
              _InfoRow(
                l10n.grapes,
                wine.grapes.isEmpty ? null : wine.grapes.join(', '),
              ),
              _InfoRow(
                l10n.price,
                wine.price == null ? null : formatMoney(context, wine.price!),
              ),
              _InfoRow(
                l10n.location,
                wine.hasLocation ? formatLocation(l10n, wine) : null,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.drinkingWindow),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (wine.drinkFrom != null || wine.drinkUntil != null)
                      Text('${wine.drinkFrom ?? ''}–${wine.drinkUntil ?? ''}'),
                    const SizedBox(height: 4),
                    DrinkingStatusChip(status: status),
                  ],
                ),
              ),
              _InfoRow(l10n.notes, wine.notes),
            ],
          ),
        );
      },
    );
  }
}

/// A labelled value. Hidden when there is no value.
class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value!),
    );
  }
}
