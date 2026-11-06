import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/cellar_services.dart';
import '../data/photo_picker.dart';
import '../errors/error_messages.dart';
import '../l10n/app_localizations.dart';
import '../lexicon/lexicon.dart';
import '../lexicon/lexicon_search.dart';
import '../models/label_scan.dart';
import '../models/number_input.dart';
import '../models/sommelier_info.dart';
import '../models/wine.dart';
import '../state/cellar_controller.dart';
import '../widgets/common.dart';
import '../widgets/display_helpers.dart';
import '../widgets/label_photo_section.dart';
import '../widgets/sommelier_card.dart';
import '../widgets/suggestion_field.dart';

/// The text fields in the form, one per [Wine] property.
enum _WineField {
  name,
  producer,
  vintage,
  country,
  region,
  subregion,
  appellation,
  vineyard,
  sweetness,
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
      subregion => text(wine?.subregion),
      appellation => text(wine?.appellation),
      vineyard => text(wine?.vineyard),
      sweetness => text(wine?.sweetness),
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
  late List<String> _grapes = [...?widget.wine?.grapes];
  late bool _grapesAreBlend = widget.wine?.grapesAreBlend ?? false;
  late bool _grapesUnknown = widget.wine?.grapesUnknown ?? false;
  late List<String> _classifications = [...?widget.wine?.classifications];
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
      if (_grapes.isEmpty && !_grapesUnknown && scan.grapes.isNotEmpty) {
        _grapes = [...scan.grapes];
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

  // --- Spelling suggestions from the lexicon ---

  /// Null while the lexicon loads; there are no suggestions until then.
  LexiconSearch? get _search => _services.lexicon.search;
  Lexicon? get _lexicon => _services.lexicon.lexicon;
  String get _language => Localizations.localeOf(context).languageCode;

  /// The country typed so far, if the lexicon knows it.
  String? get _countryId {
    final text = _text(_WineField.country);
    return text == null ? null : _lexicon?.countryFor(text)?.id;
  }

  /// The lexicon place typed in [field], if any.
  LexPlace? _placeIn(_WineField field, PlaceLevel level, {String? withinId}) {
    final text = _text(field);
    if (text == null) return null;
    return _lexicon?.placeNamed(text, level: level, withinId: withinId);
  }

  LexPlace? get _region => _placeIn(_WineField.region, PlaceLevel.region);
  LexPlace? get _subregion => _placeIn(
    _WineField.subregion,
    PlaceLevel.subregion,
    withinId: _region?.id,
  );
  LexPlace? get _appellation => _placeIn(
    _WineField.appellation,
    PlaceLevel.appellation,
    withinId: _subregion?.id ?? _region?.id,
  );

  /// The smallest place typed so far, for ordering classifications.
  String? get _placeId => (_appellation ?? _subregion ?? _region)?.id;

  /// Places of [level] for [text]. Inside [withinId] first; if nothing
  /// there matches, anywhere. With nothing typed, only the places inside
  /// [withinId] are listed.
  List<Suggestion<LexPlace>> _suggestPlaces(
    String text,
    PlaceLevel level, {
    String? withinId,
  }) {
    final search = _search;
    if (search == null) return const [];
    if (text.trim().isEmpty && withinId == null) return const [];
    List<Suggestion<LexPlace>> find(String? within) => search.places(
      text,
      level: level,
      countryId: _countryId,
      withinId: within,
      languageCode: _language,
    );
    final inside = find(withinId);
    return inside.isEmpty && withinId != null && text.trim().isNotEmpty
        ? find(null)
        : inside;
  }

  /// After a place is picked, fills in the empty fields for the places it
  /// lies in and its country. What the user typed is never replaced.
  void _fillAround(LexPlace place) {
    final lexicon = _lexicon;
    if (lexicon == null) return;
    setState(() {
      for (final p in lexicon.pathOf(place).skip(1)) {
        final field = switch (p.level) {
          PlaceLevel.region => _WineField.region,
          PlaceLevel.subregion => _WineField.subregion,
          PlaceLevel.appellation => _WineField.appellation,
          PlaceLevel.vineyard => null,
        };
        if (field != null && _text(field) == null) {
          _controllers[field]!.text = p.name;
        }
      }
      final country = lexicon.countryById(lexicon.countryIdOf(place));
      if (country != null && _text(_WineField.country) == null) {
        _controllers[_WineField.country]!.text = country.nameIn(_language);
      }
    });
  }

  /// Grapes and named blends for [text]. The wine's country decides which
  /// name comes first, e.g. Shiraz or Syrah.
  List<Suggestion<Object>> _suggestGrapes(String text) {
    final search = _search;
    if (search == null || text.trim().isEmpty) return const [];
    return [
      for (final s in search.grapes(text, countryId: _countryId))
        Suggestion<Object>(s.text, s.entry, detail: s.detail),
      for (final s in search.blends(text, _language))
        Suggestion<Object>(s.text, s.entry),
    ].take(LexiconSearch.limit).toList();
  }

  void _setGrapes(List<String> grapes) => setState(() {
    _grapes = grapes;
    // Naming a grape answers "don't know".
    if (grapes.isNotEmpty) _grapesUnknown = false;
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
        subregion: _text(_WineField.subregion),
        appellation: _text(_WineField.appellation),
        vineyard: _text(_WineField.vineyard),
        grapes: _grapes,
        grapesAreBlend: _grapesAreBlend,
        grapesUnknown: _grapesUnknown,
        classifications: _classifications,
        sweetness: _text(_WineField.sweetness),
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

  /// Shows "Suggested by AI" while [field] has the value the AI filled in.
  InputDecoration _decoration(_WineField field, String label, {String? hint}) {
    final fromAi = _isFromAi(field);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: fromAi ? AppLocalizations.of(context).filledByAi : null,
      suffixIcon: fromAi
          ? Icon(
              Icons.auto_awesome,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
    );
  }

  Widget _textField(
    _WineField field,
    String label, {
    String? hint,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _controllers[field],
        decoration: _decoration(field, label, hint: hint),
        keyboardType: keyboard,
        validator: validator,
        textCapitalization: keyboard == null
            ? TextCapitalization.sentences
            : TextCapitalization.none,
      ),
    );
  }

  /// A text field with lexicon suggestions under it.
  Widget _suggestionField<T>(
    _WineField field,
    String label,
    List<Suggestion<T>> Function(String text) suggest, {
    ValueChanged<Suggestion<T>>? onPicked,
  }) => SuggestionField<T>(
    controller: _controllers[field]!,
    label: label,
    decoration: _decoration(field, label),
    suggest: suggest,
    onPicked: (s) {
      // Rebuild, so fields below suggest within the picked place.
      setState(() {});
      onPicked?.call(s);
    },
  );

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
              _SectionTitle(l10n.origin),
              _suggestionField<LexCountry>(
                _WineField.country,
                l10n.country,
                (text) => text.trim().isEmpty
                    ? const []
                    : _search?.countries(text, _language) ?? const [],
              ),
              _suggestionField<LexPlace>(
                _WineField.region,
                l10n.region,
                (text) => _suggestPlaces(text, PlaceLevel.region),
                onPicked: (s) => _fillAround(s.entry),
              ),
              _suggestionField<LexPlace>(
                _WineField.subregion,
                l10n.subregion,
                (text) => _suggestPlaces(
                  text,
                  PlaceLevel.subregion,
                  withinId: _region?.id,
                ),
                onPicked: (s) => _fillAround(s.entry),
              ),
              _suggestionField<LexPlace>(
                _WineField.appellation,
                l10n.appellation,
                (text) => _suggestPlaces(
                  text,
                  PlaceLevel.appellation,
                  withinId: _subregion?.id ?? _region?.id,
                ),
                onPicked: (s) => _fillAround(s.entry),
              ),
              _suggestionField<LexPlace>(
                _WineField.vineyard,
                l10n.vineyard,
                (text) => _suggestPlaces(
                  text,
                  PlaceLevel.vineyard,
                  withinId: _appellation?.id,
                ),
                onPicked: (s) => _fillAround(s.entry),
              ),
              _SectionTitle(l10n.grapes),
              ChipSuggestionField<Object>(
                label: l10n.grapes,
                values: _grapes,
                onChanged: _setGrapes,
                suggest: _suggestGrapes,
                onPicked: (s) {
                  if (s.entry is LexBlend) {
                    setState(() => _grapesAreBlend = true);
                  }
                },
                extra: _GrapeOptions(
                  blend: _grapesAreBlend,
                  unknown: _grapesUnknown,
                  // "Don't know" only while no grape is named.
                  canBeUnknown: _grapes.isEmpty,
                  onBlend: (value) => setState(() => _grapesAreBlend = value),
                  onUnknown: (value) => setState(() => _grapesUnknown = value),
                ),
              ),
              ChipSuggestionField<LexClassification>(
                label: l10n.classification,
                values: _classifications,
                onChanged: (values) =>
                    setState(() => _classifications = values),
                suggest: (text) => text.trim().isEmpty
                    ? const []
                    : _search?.classifications(
                            text,
                            countryId: _countryId,
                            placeId: _placeId,
                          ) ??
                          const [],
              ),
              _suggestionField<LexSweetness>(
                _WineField.sweetness,
                l10n.sweetness,
                (text) => text.trim().isEmpty
                    ? const []
                    : _search?.sweetness(text, countryId: _countryId) ??
                          const [],
              ),
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

/// The "Blend" and "Don't know" switches under the grapes.
class _GrapeOptions extends StatelessWidget {
  const _GrapeOptions({
    required this.blend,
    required this.unknown,
    required this.canBeUnknown,
    required this.onBlend,
    required this.onUnknown,
  });

  final bool blend;
  final bool unknown;
  final bool canBeUnknown;
  final ValueChanged<bool> onBlend;
  final ValueChanged<bool> onUnknown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: Text(l10n.blend),
          selected: blend,
          onSelected: onBlend,
        ),
        FilterChip(
          label: Text(l10n.grapesUnknown),
          selected: unknown,
          onSelected: canBeUnknown ? onUnknown : null,
        ),
      ],
    );
  }
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
