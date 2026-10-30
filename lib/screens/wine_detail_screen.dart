import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/cellar_services.dart';
import '../errors/error_messages.dart';
import '../l10n/app_localizations.dart';
import '../models/consumed_bottle.dart';
import '../models/tasting_note.dart';
import '../models/wine.dart';
import '../state/cellar_controller.dart';
import '../state/tasting_notes_controller.dart';
import '../theme/motion.dart';
import '../widgets/common.dart';
import '../widgets/display_helpers.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/rating_stars.dart';
import '../widgets/sommelier_card.dart';
import '../widgets/wine_photo.dart';
import 'add_edit_wine_screen.dart';
import 'drink_sheet.dart';
import 'tasting_note_dialog.dart';

/// Everything about one wine, and its tasting notes.
class WineDetailScreen extends StatefulWidget {
  const WineDetailScreen({
    super.key,
    required this.cellar,
    required this.services,
    required this.wineId,
  });

  final CellarController cellar;
  final CellarServices services;
  final String wineId;

  @override
  State<WineDetailScreen> createState() => _WineDetailScreenState();
}

class _WineDetailScreenState extends State<WineDetailScreen> {
  late final _notes = TastingNotesController(
    widget.cellar.repository,
    widget.wineId,
  );

  CellarController get _cellar => widget.cellar;

  @override
  void initState() {
    super.initState();
    unawaited(_notes.load());
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _edit(Wine wine) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AddEditWineScreen(
        cellar: _cellar,
        services: widget.services,
        wine: wine,
      ),
    ),
  );

  Future<void> _delete(Wine wine) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteWine,
      message: l10n.deleteConfirm(wine.name),
      confirm: l10n.delete,
      cancel: l10n.cancel,
    );
    if (!confirmed || !mounted) return;
    final deleted = await tryOrShowError(context, () => _cellar.delete(wine));
    if (deleted && mounted) Navigator.of(context).pop();
  }

  /// Asks for the date and occasion, then takes a bottle out of stock. A
  /// rating or note becomes a tasting note.
  Future<void> _drinkOne(Wine wine) async {
    final l10n = AppLocalizations.of(context);
    final details = await showDrinkSheet(context, wineName: wine.name);
    if (details == null || !mounted) return;
    unawaited(HapticFeedback.lightImpact());
    final bottle = await runOrShowError(
      context,
      () => _cellar.drinkOne(
        wine,
        date: details.date,
        occasion: details.occasion,
      ),
    );
    if (bottle == null || !mounted) return;
    if (details.rating != null || details.note != null) {
      final note = TastingNote(
        wineId: wine.id!,
        date: details.date,
        rating: details.rating,
        text: details.note ?? bottle.occasion ?? l10n.drankBottle,
      );
      await tryOrShowError(context, () => _notes.save(note));
      if (!mounted) return;
    }
    _showUndo(bottle, wine.name);
  }

  void _showUndo(ConsumedBottle bottle, String wineName) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.bottleDrunk(wineName)),
        action: SnackBarAction(
          label: l10n.undo,
          // Undoing keeps the tasting note; it may still be worth keeping.
          onPressed: () => unawaited(
            tryOrShowError(context, () => _cellar.undoDrink(bottle)),
          ),
        ),
      ),
    );
  }

  void _openPhoto(String path) {
    final l10n = AppLocalizations.of(context);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: InteractiveViewer(
            maxScale: 4,
            child: WinePhoto(
              photos: widget.services.photos,
              path: path,
              fit: BoxFit.contain,
              semanticLabel: l10n.winePhoto,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _writeNote([TastingNote? note]) async {
    final result = await showTastingNoteDialog(
      context,
      wineId: widget.wineId,
      note: note,
    );
    if (result == null || !mounted) return;
    await tryOrShowError(context, () => _notes.save(result));
  }

  Future<void> _deleteNote(TastingNote note) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteNote,
      message: l10n.deleteNoteConfirm,
      confirm: l10n.delete,
      cancel: l10n.cancel,
    );
    if (!confirmed || !mounted) return;
    await tryOrShowError(context, () => _notes.delete(note.id!));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _cellar,
      builder: (context, _) {
        final wine = _cellar.byId(widget.wineId);
        // The wine is gone while the screen closes after a delete.
        if (wine == null) return const Scaffold();

        return Scaffold(
          appBar: AppBar(
            title: Text(wine.name),
            actions: [
              IconButton(
                tooltip: l10n.editWine,
                icon: const Icon(Icons.edit),
                onPressed: () => _edit(wine),
              ),
              IconButton(
                tooltip: l10n.deleteWine,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(wine),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (wine.photoPath != null) ...[
                _PhotoHeader(
                  services: widget.services,
                  path: wine.photoPath!,
                  onTap: () => _openPhoto(wine.photoPath!),
                ),
                const SizedBox(height: 16),
              ],
              _TitleRow(wine: wine),
              const SizedBox(height: 16),
              _StockRow(wine: wine, onDrinkOne: () => _drinkOne(wine)),
              const SizedBox(height: 16),
              _DetailsCard(
                wine: wine,
                year: _cellar.currentYear,
                history: _cellar.historyOf(wine.id!),
              ),
              const SizedBox(height: 24),
              if (wine.sommelier != null) ...[
                SommelierCard(info: wine.sommelier!),
                const SizedBox(height: 24),
              ],
              // Only the notes rebuild when a note changes.
              ListenableBuilder(
                listenable: _notes,
                builder: (context, _) => _NotesSection(
                  notes: _notes,
                  onAdd: _writeNote,
                  onEdit: _writeNote,
                  onDelete: _deleteNote,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({
    required this.services,
    required this.path,
    required this.onTap,
  });

  final CellarServices services;
  final String path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).winePhoto,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: photoHeight,
          child: Material(
            child: InkWell(
              onTap: onTap,
              child: WinePhoto(photos: services.photos, path: path),
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.wine});

  final Wine wine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        WineTypeBadge(type: wine.type, size: 56),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(wine.name, style: theme.textTheme.titleLarge),
              if (wine.producer != null)
                Text(
                  wine.producer!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The number of bottles and the "Drink a bottle" button.
class _StockRow extends StatelessWidget {
  const _StockRow({required this.wine, required this.onDrinkOne});

  final Wine wine;
  final VoidCallback onDrinkOne;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        RollingText(
          l10n.bottleCount(wine.quantity),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Spacer(),
        FilledButton.tonalIcon(
          onPressed: wine.quantity == 0 ? null : onDrinkOne,
          icon: const Icon(Icons.local_bar),
          label: Text(l10n.drinkOne),
        ),
      ],
    );
  }
}

/// Type, vintage, origin, price, purchase, location, drinking window and
/// bottles drunk. Rows without a value are left out.
class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.wine,
    required this.year,
    required this.history,
  });

  final Wine wine;
  final int year;

  /// Bottles of this wine drunk, newest first.
  final List<ConsumedBottle> history;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasWindow = wine.drinkFrom != null || wine.drinkUntil != null;

    final rows = <Widget>[
      LabeledValue(l10n.wineType, wine.type.displayName(l10n)),
      if (wine.vintage != null) LabeledValue(l10n.vintage, '${wine.vintage}'),
      if (wine.country != null) LabeledValue(l10n.country, wine.country!),
      if (wine.region != null) LabeledValue(l10n.region, wine.region!),
      if (wine.grapes.isNotEmpty)
        LabeledValue(l10n.grapes, wine.grapes.join(', ')),
      if (wine.price != null)
        LabeledValue(l10n.price, formatMoney(context, wine.price!)),
      if (wine.hasPurchaseInfo)
        LabeledValue(l10n.purchase, formatPurchase(context, wine)),
      if (wine.hasLocation)
        LabeledValue(l10n.location, formatLocation(l10n, wine)),
      LabeledValue.custom(
        l10n.drinkingWindow,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasWindow)
              Text('${wine.drinkFrom ?? ''}–${wine.drinkUntil ?? ''}'),
            const SizedBox(height: 4),
            DrinkingStatusChip(status: wine.drinkingStatus(year)),
          ],
        ),
      ),
      if (history.isNotEmpty)
        LabeledValue(
          l10n.drunkTimes(history.length),
          [
            for (final bottle in history)
              [
                formatDate(context, bottle.date),
                if (bottle.occasion != null) bottle.occasion!,
              ].join(' · '),
          ].join('\n'),
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: row,
              ),
          ],
        ),
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({
    required this.notes,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final TastingNotesController notes;
  final VoidCallback onAdd;
  final ValueChanged<TastingNote> onEdit;
  final ValueChanged<TastingNote> onDelete;

  Widget _content(AppLocalizations l10n) {
    final error = notes.error;
    final list = notes.notes;
    if (notes.loading && list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Column(
        children: [
          Text(errorMessage(l10n, error), textAlign: TextAlign.center),
          TextButton(onPressed: notes.load, child: Text(l10n.retry)),
        ],
      );
    }
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(l10n.noNotes),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < list.length; i++)
          FadeSlideIn(
            key: ValueKey(list[i].id),
            index: i,
            child: _NoteTile(
              note: list[i],
              onEdit: () => onEdit(list[i]),
              onDelete: () => onDelete(list[i]),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.myNotes,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l10n.addNote),
            ),
          ],
        ),
        // Grows and shrinks smoothly as notes are added or removed.
        AnimatedSize(
          duration: Motion.of(context, Motion.medium),
          curve: Motion.easeInOut,
          alignment: Alignment.topCenter,
          child: _content(l10n),
        ),
      ],
    );
  }
}

enum _NoteAction { edit, delete }

class _NoteTile extends StatelessWidget {
  const _NoteTile({
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  final TastingNote note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onEdit,
      title: Row(
        children: [
          Text(formatDate(context, note.date)),
          const SizedBox(width: 8),
          RatingStars(rating: note.rating),
        ],
      ),
      subtitle: Text(note.text),
      trailing: PopupMenuButton<_NoteAction>(
        onSelected: (action) {
          switch (action) {
            case _NoteAction.edit:
              onEdit();
            case _NoteAction.delete:
              onDelete();
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: _NoteAction.edit, child: Text(l10n.edit)),
          PopupMenuItem(value: _NoteAction.delete, child: Text(l10n.delete)),
        ],
      ),
    );
  }
}
