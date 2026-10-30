import 'package:flutter/material.dart';

import '../data/cellar_services.dart';
import '../errors/error_messages.dart';
import '../l10n/app_localizations.dart';
import '../models/rack.dart';
import '../models/wine.dart';
import '../state/cellar_controller.dart';
import '../theme/motion.dart';
import '../widgets/common.dart';
import '../widgets/display_helpers.dart';
import 'rack_dialog.dart';
import 'wine_detail_screen.dart';

/// The racks of the cellar drawn as grids, with a dot for every place that
/// holds a wine.
class CellarMapScreen extends StatelessWidget {
  const CellarMapScreen({
    super.key,
    required this.cellar,
    required this.services,
  });

  final CellarController cellar;
  final CellarServices services;

  Set<String> _namesExcept(Rack? rack) => {
    for (final r in cellar.racks)
      if (r.id != rack?.id) r.name.toLowerCase(),
  };

  Future<void> _editRack(BuildContext context, [Rack? rack]) async {
    final result = await showRackDialog(
      context,
      rack: rack,
      takenNames: _namesExcept(rack),
    );
    if (result == null || !context.mounted) return;
    await tryOrShowError(context, () => cellar.saveRack(result));
  }

  Future<void> _deleteRack(BuildContext context, Rack rack) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteRack,
      message: l10n.deleteRackConfirm(rack.name),
      confirm: l10n.delete,
      cancel: l10n.cancel,
    );
    if (!confirmed || !context.mounted) return;
    await tryOrShowError(context, () => cellar.deleteRack(rack));
  }

  void _openWine(BuildContext context, Wine wine) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => WineDetailScreen(
        cellar: cellar,
        services: services,
        wineId: wine.id!,
      ),
    ),
  );

  /// Opens the wine in a place, or lets the user pick one if several wines
  /// claim the same place.
  Future<void> _openSlot(BuildContext context, List<Wine> wines) async {
    final wine = wines.length == 1
        ? wines.single
        : await _pickWine(context, wines: wines, title: null);
    if (wine != null && context.mounted) _openWine(context, wine);
  }

  Future<void> _fillSlot(
    BuildContext context,
    Rack rack,
    int shelf,
    int slot,
  ) async {
    final l10n = AppLocalizations.of(context);
    // Wines without a place in any rack come first.
    final wines = cellar.allWines.where((w) => w.quantity > 0).toList();
    bool placed(Wine wine) => cellar.racks.any((r) => r.placeOf(wine) != null);
    final sorted = [...wines.where((w) => !placed(w)), ...wines.where(placed)];
    final wine = await _pickWine(
      context,
      wines: sorted,
      title: l10n.placeWine(shelf, slot),
    );
    if (wine == null || !context.mounted) return;
    await tryOrShowError(
      context,
      () => cellar.place(wine, rack, shelf: shelf, slot: slot),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: cellar,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.navMap),
          actions: [
            if (cellar.racks.isNotEmpty)
              IconButton(
                tooltip: l10n.addRack,
                icon: const Icon(Icons.add),
                onPressed: () => _editRack(context),
              ),
          ],
        ),
        body: cellar.racks.isEmpty
            ? MessageView(
                icon: Icons.grid_view,
                title: l10n.noRacksTitle,
                message: l10n.noRacks,
                action: FilledButton.icon(
                  onPressed: () => _editRack(context),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addRack),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  for (final rack in cellar.racks)
                    Padding(
                      key: ValueKey(rack.id),
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _RackCard(
                        rack: rack,
                        wines: cellar.allWines,
                        onEdit: () => _editRack(context, rack),
                        onDelete: () => _deleteRack(context, rack),
                        onOpenSlot: (wines) => _openSlot(context, wines),
                        onFillSlot: (shelf, slot) =>
                            _fillSlot(context, rack, shelf, slot),
                        onOpenWine: (wine) => _openWine(context, wine),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// A list of wines in a bottom sheet. Returns the one tapped.
Future<Wine?> _pickWine(
  BuildContext context, {
  required List<Wine> wines,
  required String? title,
}) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<Wine>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          if (wines.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.noWinesToPlace),
            ),
          for (final wine in wines)
            ListTile(
              leading: WineTypeBadge(type: wine.type, size: 36),
              title: Text(
                wine.vintage == null
                    ? wine.name
                    : '${wine.name} ${wine.vintage}',
              ),
              subtitle: wine.hasLocation
                  ? Text(formatLocation(l10n, wine))
                  : null,
              onTap: () => Navigator.of(context).pop(wine),
            ),
        ],
      ),
    ),
  );
}

enum _RackAction { edit, delete }

class _RackCard extends StatelessWidget {
  const _RackCard({
    required this.rack,
    required this.wines,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenSlot,
    required this.onFillSlot,
    required this.onOpenWine,
  });

  final Rack rack;
  final List<Wine> wines;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<List<Wine>> onOpenSlot;
  final void Function(int shelf, int slot) onFillSlot;
  final ValueChanged<Wine> onOpenWine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Only wines with bottles left take up a place.
    final slots = <(int, int), List<Wine>>{};
    final withoutPlace = <Wine>[];
    for (final wine in wines) {
      if (wine.quantity == 0 || !rack.holds(wine)) continue;
      final place = rack.placeOf(wine);
      if (place == null) {
        withoutPlace.add(wine);
      } else {
        slots.putIfAbsent((place.shelf, place.slot), () => []).add(wine);
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      '${l10n.rack} ${rack.name}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                PopupMenuButton<_RackAction>(
                  tooltip: l10n.moreOptions,
                  onSelected: (action) => switch (action) {
                    _RackAction.edit => onEdit(),
                    _RackAction.delete => onDelete(),
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _RackAction.edit,
                      child: Text(l10n.editRack),
                    ),
                    PopupMenuItem(
                      value: _RackAction.delete,
                      child: Text(l10n.deleteRack),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              l10n.rackUsage(slots.length, rack.capacity),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            // Wide racks scroll sideways instead of shrinking the places.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var shelf = 1; shelf <= rack.shelves; shelf++)
                    Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: ExcludeSemantics(
                            child: Text(
                              '$shelf',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        for (var slot = 1; slot <= rack.slotsPerShelf; slot++)
                          _Slot(
                            shelf: shelf,
                            slot: slot,
                            wines: slots[(shelf, slot)] ?? const [],
                            onOpen: onOpenSlot,
                            onFill: () => onFillSlot(shelf, slot),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            if (withoutPlace.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(l10n.notInGrid, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final wine in withoutPlace)
                    ActionChip(
                      avatar: CircleAvatar(backgroundColor: wine.type.color),
                      label: Text(wine.name),
                      onPressed: () => onOpenWine(wine),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One place in a rack: a dot in the wine's color, or an empty ring.
class _Slot extends StatelessWidget {
  const _Slot({
    required this.shelf,
    required this.slot,
    required this.wines,
    required this.onOpen,
    required this.onFill,
  });

  final int shelf;
  final int slot;
  final List<Wine> wines;
  final ValueChanged<List<Wine>> onOpen;
  final VoidCallback onFill;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final empty = wines.isEmpty;
    final label = empty
        ? l10n.emptySlot(shelf, slot)
        : l10n.filledSlot(shelf, slot, wines.map((w) => w.name).join(', '));
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: InkResponse(
          onTap: empty ? onFill : () => onOpen(wines),
          radius: 24,
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: AnimatedContainer(
                duration: Motion.of(context, Motion.medium),
                curve: Motion.easeOut,
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: empty ? null : wines.first.type.color,
                  // A ring keeps light wines visible on a light card.
                  border: Border.all(
                    color: empty ? scheme.outlineVariant : scheme.outline,
                    width: empty ? 1.5 : 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
