import 'package:flutter/material.dart';

import '../models/dates.dart';
import 'display_helpers.dart';

/// A tinted box with an icon and a short message, e.g. "Demo mode".
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
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
    );
  }
}

/// Asks a yes/no question. Returns true only if the user taps [confirm].
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirm,
  required String cancel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// A small grey label with a value below it. Use [LabeledValue.custom] to
/// show a widget instead of text.
class LabeledValue extends StatelessWidget {
  const LabeledValue(this.label, String this.value, {super.key}) : child = null;

  const LabeledValue.custom(this.label, Widget this.child, {super.key})
    : value = null;

  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        child ?? Text(value!, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}

/// A form field showing a date, opening a calendar when tapped. Only dates
/// from 1900 up to today can be picked. With [onCleared] it has a button to
/// remove the date.
class PastDateField extends StatelessWidget {
  const PastDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onCleared,
    this.clearTooltip,
    this.today,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback? onCleared;
  final String? clearTooltip;

  /// For tests; defaults to the real date.
  final DateTime Function()? today;

  Future<void> _pick(BuildContext context) async {
    final lastDate = dateOnly((today ?? DateTime.now)());
    final firstDate = DateTime(1900);
    final picked = await showDatePicker(
      context: context,
      initialDate: clampDate(value ?? lastDate, firstDate, lastDate),
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    return InkWell(
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value != null && onCleared != null
              ? IconButton(
                  tooltip: clearTooltip,
                  icon: const Icon(Icons.clear),
                  onPressed: onCleared,
                )
              : const Icon(Icons.calendar_today),
        ),
        isEmpty: value == null,
        child: Text(value == null ? '' : formatDate(context, value)),
      ),
    );
  }
}

/// A centered icon, optional title, message and button, for empty and error
/// states.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String? title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: scheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
