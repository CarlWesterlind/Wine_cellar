import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/tasting_note.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';

/// One to five stars. With [onChanged] the stars can be tapped; tapping the
/// current rating again clears it.
class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.onChanged});

  final int? rating;
  final ValueChanged<int?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = CellarColors.of(context).star;
    final onChanged = this.onChanged;

    Widget star(int value) {
      final filled = value <= (rating ?? 0);
      final icon = Icon(
        filled ? Icons.star_rounded : Icons.star_outline_rounded,
        color: color,
        size: onChanged == null ? 18 : 32,
      );
      if (onChanged == null) return icon;
      // Filled stars pop in slightly when chosen.
      return AnimatedScale(
        scale: filled ? 1 : 0.88,
        duration: Motion.of(context, Motion.fast),
        curve: Motion.easeOut,
        child: icon,
      );
    }

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
            onPressed: () {
              unawaited(HapticFeedback.selectionClick());
              onChanged(i == rating ? null : i);
            },
            icon: star(i),
          ),
      ],
    );
  }
}
