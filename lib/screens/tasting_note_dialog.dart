import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/dates.dart';
import '../models/tasting_note.dart';
import '../widgets/display_helpers.dart';
import '../widgets/rating_stars.dart';

/// Lets the user write a new note for [wineId], or edit [note]. Returns the
/// note to save, or null if cancelled.
Future<TastingNote?> showTastingNoteDialog(
  BuildContext context, {
  required String wineId,
  TastingNote? note,
  DateTime Function() clock = DateTime.now,
}) => showDialog<TastingNote>(
  context: context,
  builder: (_) => _TastingNoteDialog(wineId: wineId, note: note, clock: clock),
);

class _TastingNoteDialog extends StatefulWidget {
  const _TastingNoteDialog({
    required this.wineId,
    required this.note,
    required this.clock,
  });

  final String wineId;
  final TastingNote? note;
  final DateTime Function() clock;

  @override
  State<_TastingNoteDialog> createState() => _TastingNoteDialogState();
}

class _TastingNoteDialogState extends State<_TastingNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _text = TextEditingController(text: widget.note?.text);
  late DateTime _date = widget.note?.date ?? dateOnly(widget.clock());
  late int? _rating = widget.note?.rating;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = dateOnly(widget.clock());
    final first = DateTime(1900);
    final picked = await showDatePicker(
      context: context,
      initialDate: clampDate(_date, first, today),
      firstDate: first,
      lastDate: today,
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      TastingNote(
        id: widget.note?.id,
        wineId: widget.wineId,
        date: _date,
        rating: _rating,
        text: _text.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.note == null ? l10n.addNote : l10n.editNote),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.noteDate,
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(formatDate(context, _date)),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.rating, style: Theme.of(context).textTheme.labelLarge),
            RatingStars(
              rating: _rating,
              onChanged: (rating) => setState(() => _rating = rating),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _text,
              autofocus: widget.note == null,
              decoration: InputDecoration(
                labelText: l10n.noteText,
                hintText: l10n.noteHint,
              ),
              minLines: 3,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l10n.requiredField : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}
