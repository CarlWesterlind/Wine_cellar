import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/cellar_services.dart';
import '../data/photo_picker.dart';
import '../errors/error_messages.dart';
import '../l10n/app_localizations.dart';
import '../models/label_scan.dart';
import '../models/number_input.dart';
import '../models/sommelier_info.dart';
import '../models/wine.dart';
import '../state/cellar_controller.dart';
import '../widgets/common.dart';
import '../widgets/display_helpers.dart';
import '../widgets/label_photo_section.dart';
import '../widgets/sommelier_card.dart';

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
  purchasedFrom;

  /// What the field shows when editing [wine], or for a new wine.
  String initialText(Wine? wine) {
    String text(Object? value) => value?.toString() ?? '';
    return switch (this) {
      name => text(wine?.name),
      producer => text(wine?.producer),
      vintage => text(wine?.vintage),
      country => text(wine?.country),
      region => text(wine?.region),
      grapes => wine?.grapes.join(', ') ?? '',
      quantity => text(wine?.quantity ?? 1),
      price => _priceText(wine?.price),
      rack => text(wine?.rack),
      shelf => text(wine?.shelf),
      position => text(wine?.position),
      drinkFrom => text(wine?.drinkFrom),
      drinkUntil => text(wine?.drinkUntil),
      purchasedFrom => text(wine?.purchasedFrom),
    };
  }

  /// "650" rather than "650.0".
  static String _priceText(double? price) {
    if (price == null) return '';
    return price % 1 == 0 ? price.toInt().toString() : price.toString();
  }
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
  final _controllers = <_WineField, TextEditingController>{};
  late WineType _type = widget.wine?.type ?? WineType.red;
  late DateTime? _purchaseDate = widget.wine?.purchaseDate;
  late SommelierInfo? _sommelier = widget.wine?.sommelier;
  var _saving = false;
  Object? _error;

  // Photo: a new one not yet stored, or the wine's stored one.
  Uint8List? _newPhoto;
  Uint8List? _backPhoto;
  var _storedPhotoRemoved = false;

  // Label scanning.
  var _scanning = false;
  LabelScan? _lastScan;

  /// Values the AI filled in. A field shows "Suggested by AI" while it
  /// still has that value.
  final _aiValues = <_WineField, String>{};
  WineType? _aiType;

  CellarServices get _services => widget.services;

  String? get _storedPhoto =>
      _storedPhotoRemoved ? null : widget.wine?.photoPath;

  bool get _busy => _saving || _scanning;

  @override
  void initState() {
    super.initState();
    for (final field in _WineField.values) {
      final controller = TextEditingController(
        text: field.initialText(widget.wine),
      );
      // Rebuild so the AI hint disappears once the user changes the value.
      controller.addListener(() {
        if (_aiValues.containsKey(field)) setState(() {});
      });
      _controllers[field] = controller;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// The trimmed text of a field, or null if it is empty.
  String? _text(_WineField field) {
    final value = _controllers[field]!.text.trim();
    return value.isEmpty ? null : value;
  }

  bool _isFromAi(_WineField field) =>
      _aiValues[field] != null && _aiValues[field] == _controllers[field]!.text;

  // --- Photo and label scanning ---

  /// Takes the front photo, offers to add the back, then reads the label.
  Future<void> _addPhoto(PhotoSource source) async {
    final front = await runOrShowError(
      context,
      () => _services.pickPhoto(source),
    );
    if (front == null || !mounted) return;
    setState(() {
      _newPhoto = front;
      _backPhoto = null;
      _storedPhotoRemoved = false;
    });

    final l10n = AppLocalizations.of(context);
    final addBack = await showConfirmDialog(
      context,
      title: l10n.addBackTitle,
      message: l10n.addBackBody,
      confirm: l10n.addBack,
      cancel: l10n.skip,
    );
    if (!mounted) return;
    if (addBack) {
      _backPhoto = await runOrShowError<Uint8List?>(
        context,
        () => _services.pickPhoto(source),
      );
      if (!mounted) return;
    }
    await _scan();
  }

  Future<void> _scan() async {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    setState(() => _scanning = true);
    final scan = await runOrShowError(context, () async {
      final front = _newPhoto ?? await _services.photos.load(_storedPhoto!);
      return _services.scanner.scan(
        front: front,
        back: _backPhoto,
        language: language,
      );
    });
    if (!mounted) return;
    setState(() => _scanning = false);
    if (scan == null) return; // The error has been shown.

    final filled = _applyScan(scan);
    unawaited(HapticFeedback.lightImpact());
    showMessage(context, l10n.aiFilledFields(filled));
  }

  /// Fills in the empty fields from [scan]; what the user already typed
  /// stays. Returns how many fields were filled.
  int _applyScan(LabelScan scan) {
    var filled = 0;
    final values = {
      _WineField.name: scan.name,
      _WineField.producer: scan.producer,
      _WineField.vintage: scan.vintage?.toString(),
      _WineField.country: scan.country,
      _WineField.region: scan.region,
      _WineField.grapes: scan.grapes.isEmpty ? null : scan.grapes.join(', '),
      _WineField.drinkFrom: scan.drinkFrom?.toString(),
      _WineField.drinkUntil: scan.drinkUntil?.toString(),
    };
    setState(() {
      values.forEach((field, value) {
        if (_fillIfEmpty(field, value)) filled++;
      });
      // The type always has a value, so only a new wine takes the AI's.
      if (scan.type != null && widget.wine == null) {
        _type = scan.type!;
        _aiType = scan.type;
        filled++;
      }
      if (scan.sommelier != null) {
        _sommelier = scan.sommelier;
        filled++;
      }
      _lastScan = scan;
    });
    return filled;
  }

  /// Puts [value] in [field] if the field is empty. Returns whether it did.
  bool _fillIfEmpty(_WineField field, String? value) {
    final controller = _controllers[field]!;
    if (value == null || controller.text.trim().isNotEmpty) return false;
    _aiValues[field] = value;
    controller.text = value;
    return true;
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
    try {
      final wine = Wine(
        id: widget.wine?.id,
        name: _text(_WineField.name)!,
        producer: _text(_WineField.producer),
        vintage: parseWholeNumber(_text(_WineField.vintage)),
        type: _type,
        country: _text(_WineField.country),
        region: _text(_WineField.region),
        grapes: [
          for (final grape in (_text(_WineField.grapes) ?? '').split(','))
            if (grape.trim().isNotEmpty) grape.trim(),
        ],
        quantity: parseWholeNumber(_text(_WineField.quantity)) ?? 0,
        price: parseDecimal(_text(_WineField.price)),
        rack: _text(_WineField.rack),
        shelf: _text(_WineField.shelf),
        position: _text(_WineField.position),
        drinkFrom: parseWholeNumber(_text(_WineField.drinkFrom)),
        drinkUntil: parseWholeNumber(_text(_WineField.drinkUntil)),
        purchaseDate: _purchaseDate,
        purchasedFrom: _text(_WineField.purchasedFrom),
        photoPath: _storedPhoto,
        sommelier: _sommelier,
      );
      await widget.cellar.save(wine, newPhoto: _newPhoto);
      if (!mounted) return;
      // "Check the AI values before saving" no longer applies.
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      Navigator.of(context).pop();
    } catch (error, stack) {
      logError(error, stack);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  // --- Building the form ---

  Widget _textField(
    _WineField field,
    String label, {
    String? hint,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    final l10n = AppLocalizations.of(context);
    final fromAi = _isFromAi(field);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _controllers[field],
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: fromAi ? l10n.filledByAi : null,
          suffixIcon: fromAi
              ? Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
        ),
        keyboardType: keyboard,
        validator: validator,
        textCapitalization: keyboard == null
            ? TextCapitalization.sentences
            : TextCapitalization.none,
      ),
    );
  }

  /// Two widgets side by side, sharing the width.
  Widget _pair(Widget left, Widget right) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: left),
      const SizedBox(width: 12),
      Expanded(child: right),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scan = _lastScan;
    const number = TextInputType.number;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.wine == null ? l10n.addWine : l10n.editWine),
      ),
      // Always visible and easy to reach with a thumb.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _busy ? null : _save,
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              LabelPhotoSection(
                newPhoto: _newPhoto,
                storedPhoto: _storedPhoto,
                photos: _services.photos,
                scanning: _scanning,
                enabled: !_busy,
                onAdd: _addPhoto,
                onScanAgain: _scan,
                onRemove: _removePhoto,
              ),
              if (scan != null && _services.isDemo)
                _Spaced(
                  NoticeBanner(icon: Icons.info_outline, text: l10n.demoScan),
                ),
              if (scan?.confidence == ScanConfidence.low)
                _Spaced(
                  NoticeBanner(
                    icon: Icons.warning_amber,
                    text: l10n.lowConfidence,
                  ),
                ),
              const SizedBox(height: 16),
              _textField(
                _WineField.name,
                l10n.wineName,
                validator: (v) => _validateRequired(l10n, v),
              ),
              _textField(_WineField.producer, l10n.producer),
              _pair(
                _textField(
                  _WineField.vintage,
                  l10n.vintage,
                  keyboard: number,
                  validator: (v) => _validateYear(l10n, v),
                ),
                _TypeDropdown(
                  value: _type,
                  fromAi: _aiType != null && _aiType == _type,
                  onChanged: (type) => setState(() => _type = type),
                ),
              ),
              _textField(_WineField.country, l10n.country),
              _textField(_WineField.region, l10n.region),
              _textField(_WineField.grapes, l10n.grapes, hint: l10n.grapesHint),
              _pair(
                _textField(
                  _WineField.quantity,
                  l10n.quantity,
                  keyboard: number,
                  validator: (v) => _validateQuantity(l10n, v),
                ),
                _textField(
                  _WineField.price,
                  l10n.price,
                  keyboard: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) => _validatePrice(l10n, v),
                ),
              ),
              _SectionTitle(l10n.location),
              Row(
                children: [
                  Expanded(child: _textField(_WineField.rack, l10n.rack)),
                  const SizedBox(width: 12),
                  Expanded(child: _textField(_WineField.shelf, l10n.shelf)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _textField(_WineField.position, l10n.position),
                  ),
                ],
              ),
              _SectionTitle(l10n.drinkingWindow),
              _pair(
                _textField(
                  _WineField.drinkFrom,
                  l10n.drinkFrom,
                  keyboard: number,
                  validator: (v) => _validateYear(l10n, v),
                ),
                _textField(
                  _WineField.drinkUntil,
                  l10n.drinkUntil,
                  keyboard: number,
                  validator: (v) => _validateDrinkUntil(
                    l10n,
                    v,
                    from: parseWholeNumber(_text(_WineField.drinkFrom)),
                  ),
                ),
              ),
              _SectionTitle(l10n.purchase),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PastDateField(
                  label: l10n.purchaseDate,
                  value: _purchaseDate,
                  onChanged: (date) => setState(() => _purchaseDate = date),
                  onCleared: () => setState(() => _purchaseDate = null),
                  clearTooltip: l10n.clearDate,
                ),
              ),
              _textField(
                _WineField.purchasedFrom,
                l10n.purchasedFrom,
                hint: l10n.purchasedFromHint,
              ),
              if (_sommelier != null) ...[
                const SizedBox(height: 12),
                SommelierCard(
                  info: _sommelier!,
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

// --- Validators: return an error message, or null if the value is fine ---

String? _validateRequired(AppLocalizations l10n, String? value) =>
    value == null || value.trim().isEmpty ? l10n.requiredField : null;

/// An empty year is fine; a filled-in one must be between 1800 and 2200.
String? _validateYear(AppLocalizations l10n, String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final year = parseWholeNumber(value);
  if (year == null || year < 1800 || year > 2200) return l10n.invalidYear;
  return null;
}

String? _validateDrinkUntil(
  AppLocalizations l10n,
  String? value, {
  required int? from,
}) {
  final yearError = _validateYear(l10n, value);
  if (yearError != null) return yearError;
  final until = parseWholeNumber(value);
  if (from != null && until != null && until < from) {
    return l10n.untilBeforeFrom;
  }
  return null;
}

String? _validateQuantity(AppLocalizations l10n, String? value) {
  final quantity = parseWholeNumber(value);
  return quantity == null || quantity < 0 ? l10n.invalidNumber : null;
}

/// An empty price is fine; a filled-in one must be a number of 0 or more.
String? _validatePrice(AppLocalizations l10n, String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final price = parseDecimal(value);
  return price == null || price < 0 ? l10n.invalidNumber : null;
}

// --- Small building blocks of the form ---

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 8),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );
}

/// Adds a little space above a notice.
class _Spaced extends StatelessWidget {
  const _Spaced(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(top: 8), child: child);
}

class _TypeDropdown extends StatelessWidget {
  const _TypeDropdown({
    required this.value,
    required this.fromAi,
    required this.onChanged,
  });

  final WineType value;
  final bool fromAi;
  final ValueChanged<WineType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<WineType>(
        // A new key when the AI picks the type, so the field shows it.
        key: ValueKey(value),
        initialValue: value,
        isExpanded: true,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: l10n.wineType,
          helperText: fromAi ? l10n.filledByAi : null,
        ),
        items: [
          for (final type in WineType.values)
            DropdownMenuItem(value: type, child: Text(type.displayName(l10n))),
        ],
        onChanged: (type) => onChanged(type!),
      ),
    );
  }
}
