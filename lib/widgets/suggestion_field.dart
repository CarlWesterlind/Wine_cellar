import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../lexicon/lexicon_search.dart';
import '../theme/motion.dart';

/// Scrolls the focused field near the top of the screen, so the
/// suggestions below it have room above the keyboard.
void _scrollUpOnFocus(FocusNode focus, BuildContext Function() context) {
  focus.addListener(() {
    if (!focus.hasFocus) return;
    // After the keyboard has opened and the screen has resized.
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      final fieldContext = context();
      if (!focus.hasFocus || !fieldContext.mounted) return;
      Scrollable.ensureVisible(
        fieldContext,
        alignment: 0.15,
        duration: Motion.of(fieldContext, Motion.medium),
        curve: Motion.easeInOut,
      );
    });
  });
}

/// A text field with a list of spelling suggestions under it. Tapping a
/// suggestion fills it in; anything else typed is kept as it is.
class SuggestionField<T> extends StatefulWidget {
  const SuggestionField({
    super.key,
    required this.controller,
    required this.label,
    required this.suggest,
    this.onPicked,
    this.decoration,
  });

  final TextEditingController controller;
  final String label;

  /// Suggestions for the text typed so far.
  final List<Suggestion<T>> Function(String text) suggest;
  final ValueChanged<Suggestion<T>>? onPicked;

  /// Extra decoration, e.g. a helper text; [label] is always used.
  final InputDecoration? decoration;

  @override
  State<SuggestionField<T>> createState() => _SuggestionFieldState<T>();
}

class _SuggestionFieldState<T> extends State<SuggestionField<T>> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollUpOnFocus(_focus, () => context);
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RawAutocomplete<Suggestion<T>>(
        textEditingController: widget.controller,
        focusNode: _focus,
        displayStringForOption: (s) => s.text,
        optionsBuilder: (value) => widget.suggest(value.text),
        onSelected: (s) => widget.onPicked?.call(s),
        fieldViewBuilder: (context, controller, focus, _) => TextFormField(
          controller: controller,
          focusNode: focus,
          decoration: (widget.decoration ?? const InputDecoration()).copyWith(
            labelText: widget.label,
          ),
          textCapitalization: TextCapitalization.words,
          // Enter keeps what was typed; it never picks a suggestion.
        ),
        optionsViewBuilder: (context, onSelected, options) => SuggestionList<T>(
          options: options.toList(),
          onSelected: onSelected,
        ),
      ),
    );
  }
}

/// A field holding several values as chips, e.g. grapes, with suggestions
/// while typing. Enter adds what was typed as it is.
class ChipSuggestionField<T> extends StatefulWidget {
  const ChipSuggestionField({
    super.key,
    required this.label,
    required this.values,
    required this.onChanged,
    required this.suggest,
    this.onPicked,
    this.extra,
    this.hint,
  });

  final String label;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final List<Suggestion<T>> Function(String text) suggest;

  /// Called when a suggestion (not free text) is added.
  final ValueChanged<Suggestion<T>>? onPicked;

  /// Shown under the field, e.g. "Blend" and "Don't know" switches.
  final Widget? extra;
  final String? hint;

  @override
  State<ChipSuggestionField<T>> createState() => _ChipSuggestionFieldState<T>();
}

class _ChipSuggestionFieldState<T> extends State<ChipSuggestionField<T>> {
  final _text = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollUpOnFocus(_focus, () => context);
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add(String value) {
    final trimmed = value.trim();
    _text.clear();
    if (trimmed.isEmpty) return;
    final exists = widget.values.any(
      (v) => v.toLowerCase() == trimmed.toLowerCase(),
    );
    if (!exists) widget.onChanged([...widget.values, trimmed]);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RawAutocomplete<Suggestion<T>>(
            textEditingController: _text,
            focusNode: _focus,
            displayStringForOption: (s) => s.text,
            optionsBuilder: (value) => widget.suggest(value.text),
            onSelected: (s) {
              _add(s.text);
              widget.onPicked?.call(s);
            },
            fieldViewBuilder: (context, controller, focus, _) => TextFormField(
              controller: controller,
              focusNode: focus,
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: widget.hint ?? l10n.addItemHint,
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: _add,
            ),
            optionsViewBuilder: (context, onSelected, options) =>
                SuggestionList<T>(
                  options: options.toList(),
                  onSelected: onSelected,
                ),
          ),
          if (widget.values.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final value in widget.values)
                  InputChip(
                    label: Text(value),
                    deleteButtonTooltipMessage: l10n.removeItem(value),
                    onDeleted: () => widget.onChanged([
                      for (final v in widget.values)
                        if (v != value) v,
                    ]),
                  ),
              ],
            ),
          ],
          if (widget.extra != null) ...[
            const SizedBox(height: 4),
            widget.extra!,
          ],
        ],
      ),
    );
  }
}

/// The floating list of suggestions under a field.
class SuggestionList<T> extends StatelessWidget {
  const SuggestionList({
    super.key,
    required this.options,
    required this.onSelected,
  });

  final List<Suggestion<T>> options;
  final ValueChanged<Suggestion<T>> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: _FadeIn(
        child: Material(
          elevation: 4,
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            // Room for about four rows, so the field stays in view above
            // the keyboard.
            constraints: const BoxConstraints(maxHeight: 4.5 * 56),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final option in options)
                  ListTile(
                    minTileHeight: 48,
                    title: Text(option.text),
                    subtitle: option.detail == null
                        ? null
                        : Text(
                            option.detail!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    onTap: () => onSelected(option),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A quick fade, so the list doesn't pop in.
class _FadeIn extends StatelessWidget {
  const _FadeIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Motion.of(context, Motion.fast),
    curve: Motion.easeOut,
    builder: (context, opacity, child) =>
        Opacity(opacity: opacity, child: child),
    child: child,
  );
}
