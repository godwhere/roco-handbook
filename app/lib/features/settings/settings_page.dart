import 'package:flutter/material.dart';

import '../../app_version.dart';
import '../../catalog_app.dart';
import '../../data/catalog/catalog_installer.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.session,
    this.onRestoreBundledCatalog,
    super.key,
  });

  final CatalogSession session;
  final Future<void> Function()? onRestoreBundledCatalog;

  Future<void> _confirmRestore(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore bundled Catalog?'),
        content: const Text(
          'This replaces only the offline Catalog with the version included '
          'in this App. Favorites, collection marks, and notes are kept. The '
          'bundled version may be older than the current Catalog.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-catalog-restore'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore Catalog'),
          ),
        ],
      ),
    );
    if (confirmed != true || onRestoreBundledCatalog == null) {
      return;
    }
    try {
      await onRestoreBundledCatalog!();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bundled Catalog restored.')),
        );
      }
    } on Object catch (error) {
      if (context.mounted) {
        final code = error is CatalogInstallException
            ? error.code
            : 'catalog_restore';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Catalog restore failed ($code).')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = session.info;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: <Widget>[
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        const Card(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.brightness_auto_rounded),
                title: Text('Theme'),
                subtitle: Text('Follow device setting'),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.phone_iphone_rounded),
                title: Text('Personal data'),
                subtitle: Text(
                  'Favorites, collection marks, and notes stay on this device. Uninstalling the App may remove them.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Catalog recovery', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Restore the complete read-only Catalog shipped with this '
                  'App. Personal data is stored separately and is not removed.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  key: const ValueKey('restore-bundled-catalog'),
                  onPressed: onRestoreBundledCatalog == null
                      ? null
                      : () => _confirmRestore(context),
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('Restore bundled Catalog'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('About', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: <Widget>[
              const ListTile(
                title: Text('App version'),
                subtitle: Text(AppVersion.display),
              ),
              ListTile(
                title: const Text('Catalog'),
                subtitle: Text(
                  'Data ${info.dataVersion} · Schema ${info.schemaVersion}',
                ),
              ),
              ListTile(
                title: const Text('Last Catalog action'),
                subtitle: Text(_catalogOutcomeLabel(session.catalogOutcome)),
              ),
              ListTile(
                title: const Text('Personal database schema'),
                subtitle: Text('${session.userSchemaVersion}'),
              ),
              ListTile(
                title: const Text('Source revision range'),
                subtitle: Text(
                  '${info.earliestSourceRevisionUtc} — ${info.latestSourceRevisionUtc}',
                ),
              ),
              ListTile(
                title: const Text('Catalog built'),
                subtitle: Text(info.builtAtUtc),
              ),
              ListTile(
                key: const ValueKey('open-source-licenses'),
                leading: const Icon(Icons.code_rounded),
                title: const Text('Open-source licenses'),
                subtitle: const Text('Flutter and packaged dependencies'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Roco Handbook',
                  applicationVersion: AppVersion.display,
                  applicationLegalese:
                      'Independent, non-commercial, and unofficial.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Attribution', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(session.attribution),
          ),
        ),
      ],
    );
  }
}

String _catalogOutcomeLabel(CatalogOpenOutcome outcome) {
  return switch (outcome) {
    CatalogOpenOutcome.reused => 'Opened the current validated Catalog',
    CatalogOpenOutcome.installedBundled => 'Installed bundled Catalog data',
    CatalogOpenOutcome.installedRemote =>
      'Installed a verified Catalog package',
    CatalogOpenOutcome.recoveredPrevious =>
      'Recovered the previous validated Catalog',
    CatalogOpenOutcome.restoredBundled =>
      'Restored the Catalog bundled with this App',
  };
}
