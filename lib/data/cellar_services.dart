import 'label_scanner.dart';
import 'photo_picker.dart';
import 'photo_storage.dart';
import 'wine_repository.dart';

/// Everything the cellar screens need from the outside world, for one
/// signed-in user.
class CellarServices {
  const CellarServices({
    required this.wines,
    required this.photos,
    required this.scanner,
    this.pickPhoto = pickPhotoWithDevice,
    this.isDemo = false,
  });

  /// Demo mode: sample wines in memory, nothing saved, and an example
  /// result instead of real label scanning.
  factory CellarServices.demo() => CellarServices(
    wines: InMemoryWineRepository.demo(),
    photos: InMemoryPhotoStorage(),
    scanner: const DemoLabelScanner(),
    isDemo: true,
  );

  final WineRepository wines;
  final PhotoStorage photos;
  final LabelScanner scanner;

  /// Takes or chooses a photo; replaced in tests.
  final PhotoPicker pickPhoto;

  /// In demo mode the app says that nothing is saved and that scans are
  /// examples.
  final bool isDemo;
}
