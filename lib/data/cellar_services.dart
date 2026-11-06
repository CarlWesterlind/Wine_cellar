import '../lexicon/lexicon_store.dart';
import 'file_sharer.dart';
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
    required this.lexicon,
    this.pickPhoto = pickPhotoWithDevice,
    this.shareFile = shareFileWithDevice,
    this.isDemo = false,
  });

  /// Demo mode: sample wines in memory, nothing saved, and an example
  /// result instead of real label scanning.
  factory CellarServices.demo(LexiconStore lexicon) => CellarServices(
    wines: InMemoryWineRepository.demo(),
    photos: InMemoryPhotoStorage(),
    scanner: const DemoLabelScanner(),
    lexicon: lexicon,
    isDemo: true,
  );

  final WineRepository wines;
  final PhotoStorage photos;
  final LabelScanner scanner;

  /// Spelling suggestions for grapes, places and label terms. Shared by all
  /// sessions, so it is loaded once.
  final LexiconStore lexicon;

  /// Takes or chooses a photo; replaced in tests.
  final PhotoPicker pickPhoto;

  /// Opens the share sheet for an exported file; replaced in tests.
  final FileSharer shareFile;

  /// In demo mode the app says that nothing is saved and that scans are
  /// examples.
  final bool isDemo;
}
