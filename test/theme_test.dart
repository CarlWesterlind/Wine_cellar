import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wine_cellar/theme/app_theme.dart';

/// WCAG contrast ratio between two colors, from 1:1 to 21:1.
double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // WCAG AAA asks for 7:1 for normal text; non-text UI like stars needs 3:1.
  const text = 7.0;
  const graphics = 3.0;

  for (final (name, scheme, colors) in [
    ('light', AppTheme.lightScheme, CellarColors.light),
    ('dark', AppTheme.darkScheme, CellarColors.dark),
  ]) {
    group('$name theme has high contrast', () {
      final backgrounds = {
        'surface': scheme.surface,
        'card': scheme.surfaceContainerLow,
        'input': scheme.surfaceContainerHigh,
      };

      for (final MapEntry(key: bgName, value: bg) in backgrounds.entries) {
        test('text on $bgName', () {
          expect(contrast(scheme.onSurface, bg), greaterThanOrEqualTo(text));
          expect(
            contrast(scheme.onSurfaceVariant, bg),
            greaterThanOrEqualTo(text),
          );
          expect(contrast(scheme.primary, bg), greaterThanOrEqualTo(text));
        });
      }

      test('buttons and banners', () {
        expect(
          contrast(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(text),
        );
        expect(
          contrast(scheme.onPrimaryContainer, scheme.primaryContainer),
          greaterThanOrEqualTo(text),
        );
        expect(
          contrast(scheme.onTertiaryContainer, scheme.tertiaryContainer),
          greaterThanOrEqualTo(text),
        );
        expect(
          contrast(scheme.error, scheme.surface),
          greaterThanOrEqualTo(text),
        );
      });

      test('drinking window chips', () {
        for (final (fg, bg) in [
          (colors.ready, colors.readyContainer),
          (colors.tooEarly, colors.tooEarlyContainer),
          (colors.pastPeak, colors.pastPeakContainer),
          (colors.unknown, colors.unknownContainer),
        ]) {
          expect(contrast(fg, bg), greaterThanOrEqualTo(text));
        }
      });

      test('rating stars', () {
        expect(
          contrast(colors.star, scheme.surfaceContainerLow),
          greaterThanOrEqualTo(graphics),
        );
      });
    });
  }
}
