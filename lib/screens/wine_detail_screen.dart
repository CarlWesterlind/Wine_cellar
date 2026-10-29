import 'dart:async';

import 'package:flutter/material.dart';

import '../errors/error_messages.dart';
import '../l10n/app_localizations.dart';
import '../models/tasting_note.dart';
import '../models/wine.dart';
import '../state/cellar_controller.dart';
import '../state/tasting_notes_controller.dart';
import '../widgets/display_helpers.dart';
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
                            () => _cellar.drinkOne(wine),
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
                l10n.purchase,
                wine.hasPurchaseInfo ? formatPurchase(context, wine) : null,
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
              const Divider(height: 32),
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
          for (final note in notes.notes)
            _NoteTile(
              note: note,
              onEdit: () => onEdit(note),
              onDelete: () => onDelete(note),
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
