import 'package:flutter/material.dart';

import '../errors/error_messages.dart';
import '../l10n/app_localizations.dart';
import '../models/dates.dart';
import '../models/wine.dart';
import '../state/cellar_controller.dart';
import '../widgets/display_helpers.dart';

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

/// Adds a new wine, or edits [wine] when it is given.
class AddEditWineScreen extends StatefulWidget {
  const AddEditWineScreen({super.key, required this.cellar, this.wine});

  final CellarController cellar;
  final Wine? wine;

  @override
  State<AddEditWineScreen> createState() => _AddEditWineScreenState();
}

class _AddEditWineScreenState extends State<AddEditWineScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<_WineField, TextEditingController> _controllers;
  late WineType _type;
  DateTime? _purchaseDate;
  var _saving = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    final w = widget.wine;
    _type = w?.type ?? WineType.red;
    _purchaseDate = w?.purchaseDate;
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
      );
      await widget.cellar.save(wine);
      if (mounted) Navigator.of(context).pop();
    } catch (error, stack) {
      logError(error, stack);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error;
      });
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
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _controllers[key],
        decoration: InputDecoration(labelText: label, hintText: hint),
        keyboardType: keyboard,
        validator: validator,
        maxLines: maxLines,
        textCapitalization: keyboard == null
            ? TextCapitalization.sentences
            : TextCapitalization.none,
      ),
    );

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.wine == null ? l10n.addWine : l10n.editWine),
      ),
      // Always visible and easy to reach with a thumb.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _saving ? null : _save,
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
                        initialValue: _type,
                        isExpanded: true,
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: InputDecoration(labelText: l10n.wineType),
                        items: [
                          for (final type in WineType.values)
                            DropdownMenuItem(
                              value: type,
                              child: Text(type.displayName(l10n)),
                            ),
                        ],
                        onChanged: (type) => setState(() => _type = type!),
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
            ],
          ),
        ),
      ),
    );
  }
}
