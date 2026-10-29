import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/photo_storage.dart';
import '../errors/error_messages.dart';
import 'motion_widgets.dart';

/// Height of the bottle photo in the form and on the wine page.
const photoHeight = 260.0;

/// A stored bottle photo. Shows a soft placeholder while it loads and fades
/// the photo in. Decorative unless [semanticLabel] is given.
class WinePhoto extends StatefulWidget {
  const WinePhoto({
    super.key,
    required this.photos,
    required this.path,
    this.fit = BoxFit.cover,
    this.semanticLabel,
    this.thumbnailSize,
  });

  final PhotoStorage photos;
  final String path;
  final BoxFit fit;
  final String? semanticLabel;

  /// For small photos: the size it is shown at, in logical pixels, so it is
  /// decoded at that size instead of the full photo.
  final double? thumbnailSize;

  @override
  State<WinePhoto> createState() => _WinePhotoState();
}

class _WinePhotoState extends State<WinePhoto> {
  late Future<Uint8List> _bytes = _load();

  Future<Uint8List> _load() async {
    try {
      return await widget.photos.load(widget.path);
    } catch (error, stack) {
      logError(error, stack);
      rethrow; // Shown as a broken-image placeholder.
    }
  }

  @override
  void didUpdateWidget(WinePhoto old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path || old.photos != widget.photos) {
      _bytes = _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) {
        final Widget child;
        if (snapshot.hasData) {
          child = PhotoBytes(
            snapshot.data!,
            key: const ValueKey('photo'),
            fit: widget.fit,
            semanticLabel: widget.semanticLabel,
            thumbnailSize: widget.thumbnailSize,
          );
        } else if (snapshot.hasError) {
          child = const _Placeholder(
            key: ValueKey('error'),
            icon: Icons.broken_image_outlined,
          );
        } else {
          child = const _Placeholder(key: ValueKey('loading'));
        }
        return FadeSwitcher(child: child);
      },
    );
  }
}

/// A photo from bytes in memory, e.g. one just taken.
class PhotoBytes extends StatelessWidget {
  const PhotoBytes(
    this.bytes, {
    super.key,
    this.fit = BoxFit.cover,
    this.semanticLabel,
    this.thumbnailSize,
  });

  final Uint8List bytes;
  final BoxFit fit;
  final String? semanticLabel;

  /// See [WinePhoto.thumbnailSize].
  final double? thumbnailSize;

  @override
  Widget build(BuildContext context) {
    final size = thumbnailSize;
    return Image.memory(
      bytes,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: size == null
          ? null
          : (size * MediaQuery.devicePixelRatioOf(context)).round(),
      gaplessPlayback: true,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      errorBuilder: (_, _, _) =>
          const _Placeholder(icon: Icons.broken_image_outlined),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({super.key, this.icon});

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: icon == null ? null : Icon(icon, color: scheme.onSurfaceVariant),
    );
  }
}
