import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/number_input.dart';
import '../models/rack.dart';

/// Lets the user create a rack, or change [rack]. Returns the rack to save,
/// or null if cancelled. [takenNames] are the other racks' names, in lower
/// case.
Future<Rack?> showRackDialog(
  BuildContext context, {
  Rack? rack,
  required Set<String> takenNames,
}) => showDialog<Rack>(
  context: context,
  builder: (_) => _RackDialog(rack: rack, takenNames: takenNames),
);

class _RackDialog extends StatefulWidget {
  const _RackDialog({required this.rack, required this.takenNames});

  final Rack? rack;
  final Set<String> takenNames;

  @override
  State<_RackDialog> createState() => _RackDialogState();
}

class _RackDialogState extends State<_RackDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.rack?.name);
  late final _shelves = TextEditingController(
    text: '${widget.rack?.shelves ?? 4}',
  );
  late final _slots = TextEditingController(
    text: '${widget.rack?.slotsPerShelf ?? 6}',
  );

  @override
  void dispose() {
    _name.dispose();
    _shelves.dispose();
    _slots.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      Rack(
        id: widget.rack?.id,
        name: _name.text,
        shelves: parseWholeNumber(_shelves.text)!,
        slotsPerShelf: parseWholeNumber(_slots.text)!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String? validateSize(String? text) {
      final value = parseWholeNumber(text);
      return value == null || value < 1 || value > Rack.maxSize
          ? l10n.rackSizeError(Rack.maxSize)
          : null;
    }

    return AlertDialog(
      title: Text(widget.rack == null ? l10n.addRack : l10n.editRack),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: widget.rack == null,
              decoration: InputDecoration(
                labelText: l10n.rackName,
                hintText: l10n.rackNameHint,
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (text) {
                final name = text?.trim() ?? '';
                if (name.isEmpty) return l10n.requiredField;
                if (widget.takenNames.contains(name.toLowerCase())) {
                  return l10n.rackNameTaken;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _shelves,
              decoration: InputDecoration(labelText: l10n.rackShelves),
              keyboardType: TextInputType.number,
              validator: validateSize,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _slots,
              decoration: InputDecoration(labelText: l10n.rackSlots),
              keyboardType: TextInputType.number,
              validator: validateSize,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}
