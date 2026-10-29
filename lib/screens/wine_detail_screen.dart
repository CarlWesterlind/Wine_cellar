import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../errors/error_messages.dart';
import '../l10n/app_localizations.dart';
import '../models/tasting_note.dart';
import '../models/wine.dart';
import '../state/cellar_controller.dart';
import '../state/tasting_notes_controller.dart';
import '../theme/motion.dart';
import '../widgets/display_helpers.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/rating_stars.dart';
import 'add_edit_wine_screen.dart';
import 'tasting_note_dialog.dart';

class WineDetailScreen extends StatefulWidget {
  const WineDetailScreen({
    super.key,
    required this.cellar,
    required this.wineId,
  });

  final CellarController cellar;
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

  Future<bool> _confirm(String title, String message, String action) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _deleteWine(Wine wine) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      l10n.deleteWine,
      l10n.deleteConfirm(wine.name),
      l10n.delete,
    );
    if (!confirmed || !mounted) return;
    final deleted = await runOrShowError(
      context,
      () => _cellar.delete(wine.id!),
    );
    if (deleted && mounted) Navigator.of(context).pop();
  }

  Future<void> _writeNote([TastingNote? note]) async {
    final result = await showTastingNoteDialog(
      context,
      wineId: widget.wineId,
      note: note,
    );
    if (result == null || !mounted) return;
    await runOrShowError(context, () => _notes.save(result));
  }

  Future<void> _deleteNote(TastingNote note) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      l10n.deleteNote,
      l10n.deleteNoteConfirm,
      l10n.delete,
    );
    if (!confirmed || !mounted) return;
    await runOrShowError(context, () => _notes.delete(note.id!));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([_cellar, _notes]),
      builder: (context, _) {
        final wine = _cellar.byId(widget.wineId);
        // The wine is gone while the screen pops after a delete.
        if (wine == null) return const Scaffold();

        final status = wine.drinkingStatus(_cellar.currentYear);
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
                        AddEditWineScreen(cellar: _cellar, wine: wine),
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.deleteWine,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteWine(wine),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  WineTypeBadge(type: wine.type, size: 56),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wine.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (wine.producer != null)
                          Text(
                            wine.producer!,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  RollingText(
                    l10n.bottleCount(wine.quantity),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: wine.quantity == 0
                        ? null
                        : () {
                            unawaited(HapticFeedback.lightImpact());
                            unawaited(
                              runOrShowError(
                                context,
                                () => _cellar.drinkOne(wine),
                              ),
                            );
                          },
                    icon: const Icon(Icons.local_bar),
                    label: Text(l10n.drinkOne),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                        wine.price == null
                            ? null
                            : formatMoney(context, wine.price!),
                      ),
                      _InfoRow(
                        l10n.purchase,
                        wine.hasPurchaseInfo
                            ? formatPurchase(context, wine)
                            : null,
                      ),
                      _InfoRow(
                        l10n.location,
                        wine.hasLocation ? formatLocation(l10n, wine) : null,
                      ),
                      _InfoRow.custom(
                        l10n.drinkingWindow,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (wine.drinkFrom != null ||
                                wine.drinkUntil != null)
                              Text(
                                '${wine.drinkFrom ?? ''}–${wine.drinkUntil ?? ''}',
                              ),
                            const SizedBox(height: 4),
                            DrinkingStatusChip(status: status),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _NotesSection(
                notes: _notes,
                onAdd: _writeNote,
                onEdit: _writeNote,
                onDelete: _deleteNote,
              ),
            ],
          ),
        );
      },
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = notes.error;
    return AnimatedSize(
      duration: Motion.of(context, Motion.medium),
      curve: Motion.easeInOut,
      alignment: Alignment.topCenter,
      child: _content(context, l10n, error),
    );
  }

  Widget _content(BuildContext context, AppLocalizations l10n, Object? error) {
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
        if (notes.loading && notes.notes.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (error != null)
          Column(
            children: [
              Text(errorMessage(l10n, error), textAlign: TextAlign.center),
              TextButton(onPressed: notes.load, child: Text(l10n.retry)),
            ],
          )
        else if (notes.notes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l10n.noNotes),
          )
        else
          for (final (index, note) in notes.notes.indexed)
            FadeSlideIn(
              key: ValueKey(note.id),
              index: index,
              child: _NoteTile(
                note: note,
                onEdit: () => onEdit(note),
                onDelete: () => onDelete(note),
              ),
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
        onSelected: (action) => switch (action) {
          _NoteAction.edit => onEdit(),
          _NoteAction.delete => onDelete(),
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: _NoteAction.edit, child: Text(l10n.edit)),
          PopupMenuItem(value: _NoteAction.delete, child: Text(l10n.delete)),
        ],
      ),
    );
  }
}

/// A labelled value. Hidden when there is no value.
class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value) : child = null;

  /// Shows [child] instead of a text value.
  const _InfoRow.custom(this.label, Widget this.child) : value = null;

  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (value == null && child == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          child ?? Text(value!, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
