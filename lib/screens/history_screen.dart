import 'package:flutter/material.dart';

import '../data/cellar_services.dart';
import '../errors/error_messages.dart';
import '../l10n/app_localizations.dart';
import '../models/consumed_bottle.dart';
import '../state/cellar_controller.dart';
import '../widgets/common.dart';
import '../widgets/display_helpers.dart';
import '../widgets/motion_widgets.dart';
import 'wine_detail_screen.dart';

/// Every bottle drunk, newest first.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    super.key,
    required this.cellar,
    required this.services,
  });

  final CellarController cellar;
  final CellarServices services;

  void _openWine(BuildContext context, String wineId) => Navigator.of(context)
      .push(
        MaterialPageRoute<void>(
          builder: (_) => WineDetailScreen(
            cellar: cellar,
            services: services,
            wineId: wineId,
          ),
        ),
      );

  Future<void> _putBack(BuildContext context, ConsumedBottle bottle) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.putBack,
      message: l10n.putBackConfirm,
      confirm: l10n.putBack,
      cancel: l10n.cancel,
    );
    if (!confirmed || !context.mounted) return;
    await tryOrShowError(context, () => cellar.undoDrink(bottle));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navHistory)),
      body: ListenableBuilder(
        listenable: cellar,
        builder: (context, _) => FadeSwitcher(child: _body(context, l10n)),
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n) {
    final error = cellar.error;
    if (error != null) {
      return MessageView(
        key: const ValueKey('error'),
        icon: Icons.cloud_off_outlined,
        message: errorMessage(l10n, error),
        action: OutlinedButton(onPressed: cellar.load, child: Text(l10n.retry)),
      );
    }
    final history = cellar.history;
    if (history.isEmpty) {
      return MessageView(
        key: const ValueKey('empty'),
        icon: Icons.history,
        title: l10n.emptyHistoryTitle,
        message: l10n.emptyHistory,
      );
    }
    final theme = Theme.of(context);
    return ListView(
      key: const ValueKey('list'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(
            l10n.drunkTimes(history.length),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final (index, bottle) in history.indexed)
          FadeSlideIn(
            key: ValueKey(bottle.id),
            index: index,
            child: _HistoryTile(
              bottle: bottle,
              cellar: cellar,
              onOpen: () => _openWine(context, bottle.wineId),
              onPutBack: () => _putBack(context, bottle),
            ),
          ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.bottle,
    required this.cellar,
    required this.onOpen,
    required this.onPutBack,
  });

  final ConsumedBottle bottle;
  final CellarController cellar;
  final VoidCallback onOpen;
  final VoidCallback onPutBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // History is deleted along with its wine, so the wine is always there.
    final wine = cellar.byId(bottle.wineId);
    if (wine == null) return const SizedBox.shrink();
    final title = wine.vintage == null
        ? wine.name
        : '${wine.name} ${wine.vintage}';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: WineTypeBadge(type: wine.type, size: 40),
      title: Text(title),
      subtitle: Text(
        [
          formatDate(context, bottle.date),
          if (bottle.occasion != null) bottle.occasion!,
        ].join(' · '),
      ),
      onTap: onOpen,
      trailing: IconButton(
        tooltip: l10n.putBack,
        icon: const Icon(Icons.undo),
        onPressed: onPutBack,
      ),
    );
  }
}
