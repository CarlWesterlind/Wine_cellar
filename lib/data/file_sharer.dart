import 'dart:typed_data';
import 'dart:ui';

import 'package:share_plus/share_plus.dart';

/// Hands a file to the phone's share sheet, e.g. to mail or save it.
/// [origin] is where the sheet points from on tablets.
typedef FileSharer = Future<void> Function(
  Uint8List bytes, {
  required String fileName,
  required String mimeType,
  Rect? origin,
});

Future<void> shareFileWithDevice(
  Uint8List bytes, {
  required String fileName,
  required String mimeType,
  Rect? origin,
}) => SharePlus.instance.share(
  ShareParams(
    files: [XFile.fromData(bytes, mimeType: mimeType)],
    fileNameOverrides: [fileName],
    sharePositionOrigin: origin,
  ),
);
