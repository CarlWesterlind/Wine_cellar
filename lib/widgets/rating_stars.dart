import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/tasting_note.dart';

/// One to five stars. With [onChanged] the stars can be tapped; tapping the
/// current rating again clears it.
class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.onChanged});

  final int? rating;
  final ValueChanged<int?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = Theme.of(context).colorScheme.primary;
    final onChanged = this.onChanged;

    Icon star(int value) => Icon(
      value <= (rating ?? 0) ? Icons.star : Icons.star_border,
      color: color,
      size: onChanged == null ? 16 : 32,
    );

    if (onChanged == null) {
      if (rating == null) return const SizedBox.shrink();
      return Semantics(
        label: l10n.ratingStars(rating!),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (
                var i = TastingNote.minRating;
                i <= TastingNote.maxRating;
                i++
              )
                star(i),
            ],
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = TastingNote.minRating; i <= TastingNote.maxRating; i++)
          IconButton(
            tooltip: l10n.ratingStars(i),
            onPressed: () => onChanged(i == rating ? null : i),
            icon: star(i),
          ),
      ],
    );
  }
}
