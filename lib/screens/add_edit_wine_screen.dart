import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/cellar_services.dart';
import '../data/photo_picker.dart';
import '../errors/error_messages.dart';
import '../l10n/app_localizations.dart';
import '../models/dates.dart';
import '../models/label_scan.dart';
import '../models/sommelier_info.dart';
import '../models/wine.dart';
import '../state/cellar_controller.dart';
import '../theme/motion.dart';
import '../widgets/display_helpers.dart';
import '../widgets/sommelier_card.dart';
import '../widgets/wine_photo.dart';

/// Height of the bottle photo in the form and on the wine page.
const photoHeight = 260.0;

/// The text fields in the form, one per [Wine] property.
enum _WineField {
  name,
  producer,
  vintage,
  country,
  region,
  grapes,
  quantity,
  price,
  rack,
  shelf,
  position,
  drinkFrom,
  drinkUntil,
  purchasedFrom,
}

/// Adds a new wine, or edits [wine] when it is given. A photo of the label
/// can fill in the form with AI.
class AddEditWineScreen extends StatefulWidget {
  const AddEditWineScreen({
    super.key,
    required this.cellar,
    required this.services,
    this.wine,
  });

  final CellarController cellar;
  final CellarServices services;
  final Wine? wine;

  @override
  State<AddEditWineScreen> createState() => _AddEditWineScreenState();
}

class _AddEditWineScreenState extends State<AddEditWineScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<_WineField, TextEditingController> _controllers;
  late WineType _type;
  DateTime? _purchaseDate;
  SommelierInfo? _sommelier;
  var _saving = false;
  Object? _error;

  // Photo: a new one not yet stored, or the wine's stored one.
  Uint8List? _newPhoto;
  Uint8List? _backPhoto;
  var _storedPhotoRemoved = false;

  // Label scanning.
  var _scanning = false;
  var _scanned = false;
  var _lowConfidence = false;

  /// Fields the AI filled in, with the value it gave, so the hint
  /// disappears once the user changes the value.
  final _aiValues = <_WineField, String>{};
  var _aiType = false;

  CellarServices get _services => widget.services;

  String? get _storedPhoto =>
      _storedPhotoRemoved ? null : widget.wine?.photoPath;

  bool get _hasPhoto => _newPhoto != null || _storedPhoto != null;

  @override
  void initState() {
    super.initState();
    final w = widget.wine;
    _type = w?.type ?? WineType.red;
    _purchaseDate = w?.purchaseDate;
    _sommelier = w?.sommelier;
    String text(Object? value) => value?.toString() ?? '';
    _controllers = {
      _WineField.name: TextEditingController(text: w?.name),
      _WineField.producer: TextEditingController(text: text(w?.producer)),
      _WineField.vintage: TextEditingController(text: text(w?.vintage)),
      _WineField.country: TextEditingController(text: text(w?.country)),
      _WineField.region: TextEditingController(text: text(w?.region)),
      _WineField.grapes: TextEditingController(text: w?.grapes.join(', ')),
      _WineField.quantity: TextEditingController(text: text(w?.quantity ?? 1)),
      _WineField.price: TextEditingController(text: _priceText(w?.price)),
      _WineField.rack: TextEditingController(text: text(w?.rack)),
      _WineField.shelf: TextEditingController(text: text(w?.shelf)),
      _WineField.position: TextEditingController(text: text(w?.position)),
      _WineField.drinkFrom: TextEditingController(text: text(w?.drinkFrom)),
      _WineField.drinkUntil: TextEditingController(text: text(w?.drinkUntil)),
      _WineField.purchasedFrom: TextEditingController(
        text: text(w?.purchasedFrom),
      ),
    };
    for (final MapEntry(key: field, value: controller)
        in _controllers.entries) {
      controller.addListener(() {
        // The user changed an AI value: it is theirs now.
        if (_aiValues.containsKey(field) &&
            _aiValues[field] != controller.text) {
          setState(() => _aiValues.remove(field));
        }
      });
    }
  }

  static String _priceText(double? price) {
    if (price == null) return '';
    return price % 1 == 0 ? price.toInt().toString() : price.toString();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// The trimmed text of a field, or null if it is empty.
  String? _text(_WineField key) {
    final value = _controllers[key]!.text.trim();
    return value.isEmpty ? null : value;
  }

  int? _int(_WineField key) => int.tryParse(_text(key) ?? '');

  double? _double(_WineField key) =>
      double.tryParse((_text(key) ?? '').replaceAll(',', '.'));

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // --- Photo and label scanning ---

  Future<Uint8List?> _pick(PhotoSource source) async {
    try {
      return await _services.pickPhoto(source);
    } catch (error, stack) {
      // E.g. no camera, or the user denied access.
      logError(error, stack);
      if (mounted) {
        _showMessage(errorMessage(AppLocalizations.of(context), error));
      }
      return null;
    }
  }

  /// Takes the front photo, offers to add the back, then reads the label.
  Future<void> _addPhoto(PhotoSource source) async {
    final front = await _pick(source);
    if (front == null || !mounted) return;
    setState(() {
      _newPhoto = front;
      _backPhoto = null;
    });

    final back = await _askForBack(source);
    if (!mounted) return;
    setState(() => _backPhoto = back);
    await _scan();
  }

  Future<Uint8List?> _askForBack(PhotoSource source) async {
    final l10n = AppLocalizations.of(context);
    final addBack = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addBackTitle),
        content: Text(l10n.addBackBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.skip),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.addBack),
          ),
        ],
      ),
    );
    if (addBack != true || !mounted) return null;
    return _pick(source);
  }

  Future<void> _scan() async {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    setState(() => _scanning = true);
    try {
      final front = _newPhoto ?? await _services.photos.load(_storedPhoto!);
      final scan = await _services.scanner.scan(
        front: front,
        back: _backPhoto,
        language: language,
      );
      if (!mounted) return;
      final filled = _applyScan(scan);
      unawaited(HapticFeedback.lightImpact());
      _showMessage(l10n.aiFilledFields(filled));
    } catch (error, stack) {
      logError(error, stack);
      if (mounted) _showMessage(errorMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  /// Fills in the empty fields from [scan]; what the user already typed
  /// stays. Returns how many fields were filled.
  int _applyScan(LabelScan scan) {
    var filled = 0;
    setState(() {
      void fill(_WineField field, Object? value) {
        final text = switch (value) {
          final List<String> list => list.join(', '),
          _ => value?.toString() ?? '',
        };
        final controller = _controllers[field]!;
        if (text.isEmpty || controller.text.trim().isNotEmpty) return;
        _aiValues[field] = text;
        controller.text = text;
        filled++;
      }

      fill(_WineField.name, scan.name);
      fill(_WineField.producer, scan.producer);
      fill(_WineField.vintage, scan.vintage);
      fill(_WineField.country, scan.country);
      fill(_WineField.region, scan.region);
      fill(_WineField.grapes, scan.grapes);
      fill(_WineField.drinkFrom, scan.drinkFrom);
      fill(_WineField.drinkUntil, scan.drinkUntil);

      // The type has no "empty" value, so only new wines take the AI's.
      if (scan.type case final type? when widget.wine == null) {
        if (type != _type) _type = type;
        _aiType = true;
        filled++;
      }
      if (scan.sommelier case final sommelier?) {
        _sommelier = sommelier;
        filled++;
      }
      _scanned = true;
      _lowConfidence = scan.confidence == ScanConfidence.low;
    });
    return filled;
  }

  void _removePhoto() => setState(() {
    _newPhoto = null;
    _backPhoto = null;
    _storedPhotoRemoved = true;
  });

  // --- Saving ---

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final oldPhoto = widget.wine?.photoPath;
    String? uploaded;
    try {
      final photoPath = _newPhoto == null
          ? _storedPhoto
          : uploaded = await _services.photos.save(_newPhoto!);
      final wine = Wine(
        id: widget.wine?.id,
        name: _text(_WineField.name)!,
        producer: _text(_WineField.producer),
        vintage: _int(_WineField.vintage),
        type: _type,
        country: _text(_WineField.country),
        region: _text(_WineField.region),
        grapes: (_text(_WineField.grapes) ?? '')
            .split(',')
            .map((g) => g.trim())
            .where((g) => g.isNotEmpty)
            .toList(),
        quantity: _int(_WineField.quantity) ?? 0,
        price: _double(_WineField.price),
        rack: _text(_WineField.rack),
        shelf: _text(_WineField.shelf),
        position: _text(_WineField.position),
        drinkFrom: _int(_WineField.drinkFrom),
        drinkUntil: _int(_WineField.drinkUntil),
        purchaseDate: _purchaseDate,
        purchasedFrom: _text(_WineField.purchasedFrom),
        photoPath: photoPath,
        sommelier: _sommelier,
      );
      await widget.cellar.save(wine);
      // The old photo was replaced or removed.
      if (oldPhoto != null && oldPhoto != photoPath) {
        unawaited(_deleteQuietly(oldPhoto));
      }
      if (!mounted) return;
      // "Check the AI values before saving" no longer applies.
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      Navigator.of(context).pop();
    } catch (error, stack) {
      logError(error, stack);
      // Don't leave an uploaded photo behind that no wine points to.
      if (uploaded != null) unawaited(_deleteQuietly(uploaded));
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  /// Deletes a photo nothing uses any more. A failure only leaves an
  /// unused file, so it is logged and not shown.
  Future<void> _deleteQuietly(String path) async {
    try {
      await _services.photos.delete(path);
    } catch (error, stack) {
      logError(error, stack);
    }
  }

  Future<void> _pickPurchaseDate() async {
    final today = dateOnly(DateTime.now());
    final first = DateTime(1900);
    final picked = await showDatePicker(
      context: context,
      initialDate: clampDate(_purchaseDate ?? today, first, today),
      firstDate: first,
      lastDate: today,
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    String? required(String? v) =>
        v == null || v.trim().isEmpty ? l10n.requiredField : null;
    String? optionalYear(String? v) {
      if (v == null || v.trim().isEmpty) return null;
      final year = int.tryParse(v.trim());
      return year == null || year < 1800 || year > 2200
          ? l10n.invalidYear
          : null;
    }

    Widget field(
      _WineField key,
      String label, {
      String? hint,
      TextInputType? keyboard,
      String? Function(String?)? validator,
      int maxLines = 1,
    }) {
      final fromAi = _aiValues.containsKey(key);
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: _controllers[key],
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            helperText: fromAi ? l10n.filledByAi : null,
            suffixIcon: fromAi
                ? Icon(Icons.auto_awesome, size: 18, color: scheme.primary)
                : null,
          ),
          keyboardType: keyboard,
          validator: validator,
          maxLines: maxLines,
          textCapitalization: keyboard == null
              ? TextCapitalization.sentences
              : TextCapitalization.none,
        ),
      );
    }

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );

    final busy = _saving || _scanning;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.wine == null ? l10n.addWine : l10n.editWine),
      ),
      // Always visible and easy to reach with a thumb.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: busy ? null : _save,
            child: Text(l10n.save),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        // Not a ListView: it would drop fields scrolled out of view, and
        // their validators would then be skipped when saving.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    errorMessage(l10n, _error!),
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              _PhotoSection(
                newPhoto: _newPhoto,
                storedPhoto: _storedPhoto,
                services: _services,
                scanning: _scanning,
                enabled: !busy,
                onAdd: _addPhoto,
                onScanAgain: _hasPhoto ? _scan : null,
                onRemove: _removePhoto,
              ),
              if (_scanned && _services.demoScanner)
                _Notice(icon: Icons.info_outline, text: l10n.demoScan),
              if (_scanned && _lowConfidence)
                _Notice(icon: Icons.warning_amber, text: l10n.lowConfidence),
              const SizedBox(height: 16),
              field(_WineField.name, l10n.wineName, validator: required),
              field(_WineField.producer, l10n.producer),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: field(
                      _WineField.vintage,
                      l10n.vintage,
                      keyboard: TextInputType.number,
                      validator: optionalYear,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<WineType>(
                        // Rebuilt when the AI picks the type.
                        key: ValueKey(_type),
                        initialValue: _type,
                        isExpanded: true,
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: InputDecoration(
                          labelText: l10n.wineType,
                          helperText: _aiType ? l10n.filledByAi : null,
                        ),
                        items: [
                          for (final type in WineType.values)
                            DropdownMenuItem(
                              value: type,
                              child: Text(type.displayName(l10n)),
                            ),
                        ],
                        onChanged: (type) => setState(() {
                          _type = type!;
                          _aiType = false;
                        }),
                      ),
                    ),
                  ),
                ],
              ),
              field(_WineField.country, l10n.country),
              field(_WineField.region, l10n.region),
              field(_WineField.grapes, l10n.grapes, hint: l10n.grapesHint),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: field(
                      _WineField.quantity,
                      l10n.quantity,
                      keyboard: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        return n == null || n < 0 ? l10n.invalidNumber : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: field(
                      _WineField.price,
                      l10n.price,
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = double.tryParse(
                          v.trim().replaceAll(',', '.'),
                        );
                        return n == null || n < 0 ? l10n.invalidNumber : null;
                      },
                    ),
                  ),
                ],
              ),
              section(l10n.location),
              Row(
                children: [
                  Expanded(child: field(_WineField.rack, l10n.rack)),
                  const SizedBox(width: 12),
                  Expanded(child: field(_WineField.shelf, l10n.shelf)),
                  const SizedBox(width: 12),
                  Expanded(child: field(_WineField.position, l10n.position)),
                ],
              ),
              section(l10n.drinkingWindow),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: field(
                      _WineField.drinkFrom,
                      l10n.drinkFrom,
                      keyboard: TextInputType.number,
                      validator: optionalYear,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: field(
                      _WineField.drinkUntil,
                      l10n.drinkUntil,
                      keyboard: TextInputType.number,
                      validator: (v) {
                        final error = optionalYear(v);
                        if (error != null) return error;
                        final from = _int(_WineField.drinkFrom);
                        final until = int.tryParse(v?.trim() ?? '');
                        return from != null && until != null && until < from
                            ? l10n.untilBeforeFrom
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              section(l10n.purchase),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: _pickPurchaseDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.purchaseDate,
                      suffixIcon: _purchaseDate == null
                          ? const Icon(Icons.calendar_today)
                          : IconButton(
                              tooltip: l10n.clearDate,
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  setState(() => _purchaseDate = null),
                            ),
                    ),
                    isEmpty: _purchaseDate == null,
                    child: Text(
                      _purchaseDate == null
                          ? ''
                          : formatDate(context, _purchaseDate!),
                    ),
                  ),
                ),
              ),
              field(
                _WineField.purchasedFrom,
                l10n.purchasedFrom,
                hint: l10n.purchasedFromHint,
              ),
              if (_sommelier case final sommelier?) ...[
                const SizedBox(height: 12),
                SommelierCard(
                  info: sommelier,
                  onRemove: () => setState(() => _sommelier = null),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The bottle photo, or an invitation to photograph the label.
class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.newPhoto,
    required this.storedPhoto,
    required this.services,
    required this.scanning,
    required this.enabled,
    required this.onAdd,
    required this.onScanAgain,
    required this.onRemove,
  });

  final Uint8List? newPhoto;
  final String? storedPhoto;
  final CellarServices services;
  final bool scanning;
  final bool enabled;
  final ValueChanged<PhotoSource> onAdd;
  final VoidCallback? onScanAgain;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final addButtons = [
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
    ];

    final Widget? photo = switch ((newPhoto, storedPhoto)) {
      (final bytes?, _) => PhotoBytes(bytes, semanticLabel: l10n.winePhoto),
      (null, final path?) => WinePhoto(
        photos: services.photos,
        path: path,
        semanticLabel: l10n.winePhoto,
      ),
      _ => null,
    };

    if (photo == null) {
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
              Wrap(spacing: 8, runSpacing: 8, children: addButtons),
            ],
          ),
        ),
      );
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
                AnimatedSwitcher(
                  duration: Motion.of(context, Motion.medium),
                  switchInCurve: Motion.easeOut,
                  switchOutCurve: Motion.easeOut,
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
            if (onScanAgain != null)
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

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: scheme.onTertiaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: scheme.onTertiaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
