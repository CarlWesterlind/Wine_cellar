import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

enum PhotoSource { camera, gallery }

/// Lets the user take or choose a photo. Returns null if they cancel.
typedef PhotoPicker = Future<Uint8List?> Function(PhotoSource source);

/// Photos are scaled down to this many pixels on the longest side: sharp
/// enough to read a label, small enough to upload quickly and keep the AI
/// cost per scan low.
const maxPhotoSide = 1600.0;

/// Uses the phone's camera or photo library (or a file chooser on the web).
Future<Uint8List?> pickPhotoWithDevice(PhotoSource source) async {
  final file = await ImagePicker().pickImage(
    source: switch (source) {
      PhotoSource.camera => ImageSource.camera,
      PhotoSource.gallery => ImageSource.gallery,
    },
    maxWidth: maxPhotoSide,
    maxHeight: maxPhotoSide,
    imageQuality: 85,
  );
  return file?.readAsBytes();
}
