import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/dates.dart';
import '../widgets/common.dart';
import '../widgets/rating_stars.dart';

/// What the user filled in when drinking a bottle. [rating] and [note] are
/// null if left empty.
typedef DrinkDetails = ({
  DateTime date,
  String? occasion,
  int? rating,
  String? note,
});

/// Asks when and with whom a bottle of [wineName] was drunk, with an
/// optional rating and note. Returns null if cancelled.
Future<DrinkDetails?> showDrinkSheet(
  BuildContext context, {
  required String wineName,
  DateTime Function() clock = DateTime.now,
}) => showModalBottomSheet<DrinkDetails>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => _DrinkSheet(wineName: wineName, clock: clock),
);

class _DrinkSheet extends StatefulWidget {
  const _DrinkSheet({required this.wineName, required this.clock});

  final String wineName;
  final DateTime Function() clock;

  @override
  State<_DrinkSheet> createState() => _DrinkSheetState();
}

class _DrinkSheetState extends State<_DrinkSheet> {
  final _occasion = TextEditingController();
  final _note = TextEditingController();
  late DateTime _date = dateOnly(widget.clock());
  int? _rating;

  @override
  void dispose() {
    _occasion.dispose();
    _note.dispose();
    super.dispose();
  }

  void _drink() {
    final note = _note.text.trim();
    Navigator.of(context).pop<DrinkDetails>((
      date: _date,
      occasion: _occasion.text,
      rating: _rating,
      note: note.isEmpty ? null : note,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      // Stays above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.drinkOne, style: theme.textTheme.titleLarge),
            Text(
              widget.wineName,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            PastDateField(
              label: l10n.drinkDate,
              value: _date,
              onChanged: (date) => setState(() => _date = date),
              today: widget.clock,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _occasion,
              decoration: InputDecoration(
                labelText: l10n.occasion,
                hintText: l10n.occasionHint,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Text(l10n.rating, style: theme.textTheme.labelLarge),
            RatingStars(
              rating: _rating,
              onChanged: (rating) => setState(() => _rating = rating),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              decoration: InputDecoration(
                labelText: l10n.noteOptional,
                hintText: l10n.noteHint,
              ),
              minLines: 2,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _drink,
              icon: const Icon(Icons.local_bar),
              label: Text(l10n.drink),
            ),
          ],
        ),
      ),
    );
  }
}
