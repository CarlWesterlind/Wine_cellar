import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/photo_picker.dart';
import '../data/photo_storage.dart';
import '../l10n/app_localizations.dart';
import 'motion_widgets.dart';
import 'wine_photo.dart';

/// The top of the wine form: the bottle photo with buttons to change it, or,
/// without a photo, an invitation to photograph the label.
class LabelPhotoSection extends StatelessWidget {
  const LabelPhotoSection({
    super.key,
    required this.newPhoto,
    required this.storedPhoto,
    required this.photos,
    required this.scanning,
    required this.enabled,
    required this.onAdd,
    required this.onScanAgain,
    required this.onRemove,
  });

  /// A photo just taken, not stored yet.
  final Uint8List? newPhoto;

  /// The path of the wine's stored photo, used when there is no [newPhoto].
  final String? storedPhoto;
  final PhotoStorage photos;

  /// True while the AI reads the label.
  final bool scanning;
  final bool enabled;
  final ValueChanged<PhotoSource> onAdd;
  final VoidCallback onScanAgain;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final Widget photo;
    if (newPhoto != null) {
      photo = PhotoBytes(newPhoto!, semanticLabel: l10n.winePhoto);
    } else if (storedPhoto != null) {
      photo = WinePhoto(
        photos: photos,
        path: storedPhoto!,
        semanticLabel: l10n.winePhoto,
      );
    } else {
      return _Invitation(enabled: enabled, onAdd: onAdd);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          // A fixed height, so the buttons below stay in view on wide
          // screens too.
          child: SizedBox(
            height: photoHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                photo,
                FadeSwitcher(
                  child: scanning
                      ? _ScanningOverlay(label: l10n.readingLabel)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton.icon(
              onPressed: enabled ? () => onAdd(PhotoSource.camera) : null,
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(l10n.changePhoto),
            ),
            TextButton.icon(
              onPressed: enabled ? onScanAgain : null,
              icon: const Icon(Icons.auto_awesome),
              label: Text(l10n.scanAgain),
            ),
            TextButton.icon(
              onPressed: enabled ? onRemove : null,
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.removePhoto),
            ),
          ],
        ),
      ],
    );
  }
}

class _Invitation extends StatelessWidget {
  const _Invitation({required this.enabled, required this.onAdd});

  final bool enabled;
  final ValueChanged<PhotoSource> onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.scanLabelTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.scanLabelBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: enabled ? () => onAdd(PhotoSource.camera) : null,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(l10n.takePhoto),
                ),
                OutlinedButton.icon(
                  onPressed: enabled ? () => onAdd(PhotoSource.gallery) : null,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(l10n.choosePhoto),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dims the photo and shows progress while the AI reads the label.
class _ScanningOverlay extends StatelessWidget {
  const _ScanningOverlay({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: label,
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        alignment: Alignment.center,
        // A solid box, so the label text behind never competes with it.
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 12),
              ExcludeSemantics(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
