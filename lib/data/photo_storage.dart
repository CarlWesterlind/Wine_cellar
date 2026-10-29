import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'images.dart';

/// Stores bottle photos. A photo is identified by the path [save] returns.
abstract interface class PhotoStorage {
  /// Stores [bytes] (JPEG, PNG or WebP) and returns its path.
  Future<String> save(Uint8List bytes);

  Future<Uint8List> load(String path);

  Future<void> delete(String path);
}

/// Keeps photos in memory. Used in demo mode and in tests.
class InMemoryPhotoStorage implements PhotoStorage {
  final _photos = <String, Uint8List>{};
  var _next = 1;

  int get count => _photos.length;

  @override
  Future<String> save(Uint8List bytes) async {
    final path = 'photo-${_next++}';
    _photos[path] = bytes;
    return path;
  }

  @override
  Future<Uint8List> load(String path) async =>
      _photos[path] ?? (throw StateError('No photo at $path'));

  @override
  Future<void> delete(String path) async => _photos.remove(path);
}

/// Stores photos in the private `wine-photos` bucket, in a folder named
/// after the user so storage policies keep them private.
class SupabasePhotoStorage implements PhotoStorage {
  SupabasePhotoStorage(this._client);

  final SupabaseClient _client;
  final _random = Random.secure();

  /// Recently used photos, so scrolling a list doesn't download them
  /// again. The least recently used are dropped beyond [_cacheSize].
  final _cache = <String, Uint8List>{};
  static const _cacheSize = 60;

  StorageFileApi get _bucket => _client.storage.from('wine-photos');

  @override
  Future<String> save(Uint8List bytes) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Not signed in');
    final mediaType = imageMediaType(bytes);
    if (mediaType == null) throw const UnsupportedImageException();
    final extension = mediaType.split('/').last.replaceFirst('jpeg', 'jpg');
    final id = List.generate(16, (_) => _random.nextInt(16).toRadixString(16));
    final path = '$userId/${id.join()}.$extension';
    await _bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: mediaType),
    );
    _remember(path, bytes);
    return path;
  }

  @override
  Future<Uint8List> load(String path) async {
    final bytes = _cache.remove(path) ?? await _bucket.download(path);
    _remember(path, bytes);
    return bytes;
  }

  /// Adds [bytes] as the most recently used photo.
  void _remember(String path, Uint8List bytes) {
    _cache[path] = bytes;
    if (_cache.length > _cacheSize) _cache.remove(_cache.keys.first);
  }

  @override
  Future<void> delete(String path) async {
    _cache.remove(path);
    await _bucket.remove([path]);
  }
}
