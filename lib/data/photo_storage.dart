import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'label_scanner.dart';

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

  /// Photos already downloaded, so lists don't download them again.
  final _cache = <String, Uint8List>{};

  StorageFileApi get _bucket => _client.storage.from('wine-photos');

  @override
  Future<String> save(Uint8List bytes) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Not signed in');
    final mediaType = imageMediaType(bytes);
    if (mediaType == null) {
      throw const LabelScanException(ScanFailure.unsupportedImage);
    }
    final extension = mediaType.split('/').last.replaceFirst('jpeg', 'jpg');
    final id = List.generate(16, (_) => _random.nextInt(16).toRadixString(16));
    final path = '$userId/${id.join()}.$extension';
    await _bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: mediaType),
    );
    _cache[path] = bytes;
    return path;
  }

  @override
  Future<Uint8List> load(String path) async =>
      _cache[path] ??= await _bucket.download(path);

  @override
  Future<void> delete(String path) async {
    _cache.remove(path);
    await _bucket.remove([path]);
  }
}
