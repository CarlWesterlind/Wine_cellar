import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/wine.dart';
import '../state/cellar_controller.dart';
import '../widgets/labels.dart';

/// Adds a new wine, or edits [wine] when it is given.
class WineFormScreen extends StatefulWidget {
  const WineFormScreen({super.key, required this.cellar, this.wine});

  final CellarController cellar;
  final Wine? wine;

  @override
  State<WineFormScreen> createState() => _WineFormScreenState();
}

class _WineFormScreenState extends State<WineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  late WineType _type;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final w = widget.wine;
    _type = w?.type ?? WineType.red;
    String text(Object? value) => value?.toString() ?? '';
    _fields = {
      'name': TextEditingController(text: w?.name),
      'producer': TextEditingController(text: text(w?.producer)),
      'vintage': TextEditingController(text: text(w?.vintage)),
      'country': TextEditingController(text: text(w?.country)),
      'region': TextEditingController(text: text(w?.region)),
      'grapes': TextEditingController(text: w?.grapes.join(', ')),
      'quantity': TextEditingController(text: text(w?.quantity ?? 1)),
      'price': TextEditingController(text: _priceText(w?.price)),
      'rack': TextEditingController(text: text(w?.rack)),
      'shelf': TextEditingController(text: text(w?.shelf)),
      'position': TextEditingController(text: text(w?.position)),
      'drinkFrom': TextEditingController(text: text(w?.drinkFrom)),
      'drinkUntil': TextEditingController(text: text(w?.drinkUntil)),
      'notes': TextEditingController(text: text(w?.notes)),
    };
  }

  static String _priceText(double? price) {
    if (price == null) return '';
    return price % 1 == 0 ? price.toInt().toString() : price.toString();
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// The trimmed text of a field, or null if it is empty.
  String? _text(String key) {
    final value = _fields[key]!.text.trim();
    return value.isEmpty ? null : value;
  }

  int? _int(String key) => int.tryParse(_text(key) ?? '');

  double? _double(String key) =>
      double.tryParse((_text(key) ?? '').replaceAll(',', '.'));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final wine = Wine(
      id: widget.wine?.id,
      name: _text('name')!,
      producer: _text('producer'),
      vintage: _int('vintage'),
      type: _type,
      country: _text('country'),
      region: _text('region'),
      grapes: (_text('grapes') ?? '')
          .split(',')
          .map((g) => g.trim())
          .where((g) => g.isNotEmpty)
          .toList(),
      quantity: _int('quantity') ?? 0,
      price: _double('price'),
      rack: _text('rack'),
      shelf: _text('shelf'),
      position: _text('position'),
      drinkFrom: _int('drinkFrom'),
      drinkUntil: _int('drinkUntil'),
      notes: _text('notes'),
    );
    try {
      await widget.cellar.save(wine);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _saving = false;
        _error = '$e';
      });
    }
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
      String key,
      String label, {
      String? hint,
      TextInputType? keyboard,
      String? Function(String?)? validator,
      int maxLines = 1,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _fields[key],
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
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.errorGeneric(_error!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            field('name', l10n.wineName, validator: required),
            field('producer', l10n.producer),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: field(
                    'vintage',
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
                      decoration: InputDecoration(labelText: l10n.wineType),
                      items: [
                        for (final type in WineType.values)
                          DropdownMenuItem(
                            value: type,
                            child: Text(type.label(l10n)),
                          ),
                      ],
                      onChanged: (type) => setState(() => _type = type!),
                    ),
                  ),
                ),
              ],
            ),
            field('country', l10n.country),
            field('region', l10n.region),
            field('grapes', l10n.grapes, hint: l10n.grapesHint),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: field(
                    'quantity',
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
                    'price',
                    l10n.price,
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = double.tryParse(v.trim().replaceAll(',', '.'));
                      return n == null || n < 0 ? l10n.invalidNumber : null;
                    },
                  ),
                ),
              ],
            ),
            section(l10n.location),
            Row(
              children: [
                Expanded(child: field('rack', l10n.rack)),
                const SizedBox(width: 12),
                Expanded(child: field('shelf', l10n.shelf)),
                const SizedBox(width: 12),
                Expanded(child: field('position', l10n.position)),
              ],
            ),
            section(l10n.drinkingWindow),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: field(
                    'drinkFrom',
                    l10n.drinkFrom,
                    keyboard: TextInputType.number,
                    validator: optionalYear,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: field(
                    'drinkUntil',
                    l10n.drinkUntil,
                    keyboard: TextInputType.number,
                    validator: (v) {
                      final error = optionalYear(v);
                      if (error != null) return error;
                      final from = _int('drinkFrom');
                      final until = int.tryParse(v?.trim() ?? '');
                      return from != null && until != null && until < from
                          ? l10n.untilBeforeFrom
                          : null;
                    },
                  ),
                ),
              ],
            ),
            field('notes', l10n.notes, maxLines: 4),
          ],
        ),
      ),
    );
  }
}
