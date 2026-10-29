import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/photo_storage.dart';
import '../errors/error_messages.dart';
import '../theme/motion.dart';

/// A stored bottle photo. Shows a soft placeholder while it loads and fades
/// the photo in. Decorative unless [semanticLabel] is given.
class WinePhoto extends StatefulWidget {
  const WinePhoto({
    super.key,
    required this.photos,
    required this.path,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  });

  final PhotoStorage photos;
  final String path;
  final BoxFit fit;
  final String? semanticLabel;

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
      builder: (context, snapshot) => AnimatedSwitcher(
        duration: Motion.of(context, Motion.medium),
        switchInCurve: Motion.easeOut,
        child: switch (snapshot) {
          AsyncSnapshot(hasData: true, :final data!) => PhotoBytes(
            data,
            key: const ValueKey('photo'),
            fit: widget.fit,
            semanticLabel: widget.semanticLabel,
          ),
          AsyncSnapshot(hasError: true) => _Placeholder(
            key: const ValueKey('error'),
            icon: Icons.broken_image_outlined,
          ),
          _ => const _Placeholder(key: ValueKey('loading')),
        },
      ),
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
  });

  final Uint8List bytes;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      bytes,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
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
