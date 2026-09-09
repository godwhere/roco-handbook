import 'package:flutter/material.dart';

import '../../app_version.dart';
import '../../catalog_app.dart';
import '../../data/catalog/catalog_installer.dart';
import '../../data/catalog/catalog_update_source.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.session,
    this.onRestoreBundledCatalog,
    this.onCheckCatalogUpdate,
    this.onInstallCatalogUpdate,
    super.key,
  });

  final CatalogSession session;
  final Future<void> Function()? onRestoreBundledCatalog;
  final Future<CatalogUpdateCheckResult> Function(
    CatalogUpdateCancellationToken cancellation,
  )?
  onCheckCatalogUpdate;
  final Future<void> Function(
    CatalogUpdateCandidate candidate,
    CatalogUpdateCancellationToken cancellation,
    void Function(CatalogUpdateProgress progress) onProgress,
  )?
  onInstallCatalogUpdate;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

enum _CatalogUpdateUiPhase { idle, checking, downloading, verifying }

class _SettingsPageState extends State<SettingsPage> {
  var _updatePhase = _CatalogUpdateUiPhase.idle;
  CatalogUpdateProgress? _updateProgress;
  CatalogUpdateCancellationToken? _updateCancellation;

  bool get _updateBusy => _updatePhase != _CatalogUpdateUiPhase.idle;

  Future<void> _checkForCatalogUpdate() async {
    final checker = widget.onCheckCatalogUpdate;
    final installer = widget.onInstallCatalogUpdate;
    if (_updateBusy || checker == null || installer == null) {
      return;
    }
    final cancellation = CatalogUpdateCancellationToken();
    setState(() {
      _updatePhase = _CatalogUpdateUiPhase.checking;
      _updateProgress = null;
      _updateCancellation = cancellation;
    });
    try {
      final result = await checker(cancellation);
      if (!mounted) {
        return;
      }
      if (result is CatalogUpdateCurrent) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Catalog is up to date.')));
        return;
      }
      final candidate = (result as CatalogUpdateAvailable).candidate;
      final confirmed = await _confirmCatalogDownload(candidate);
      if (confirmed != true || !mounted) {
        return;
      }
      setState(() {
        _updatePhase = _CatalogUpdateUiPhase.downloading;
      });
      await installer(candidate, cancellation, (progress) {
        if (!mounted) {
          return;
        }
        setState(() {
          _updateProgress = progress;
          _updatePhase = switch (progress.phase) {
            CatalogUpdatePhase.downloading => _CatalogUpdateUiPhase.downloading,
            CatalogUpdatePhase.verifyingAndInstalling =>
              _CatalogUpdateUiPhase.verifying,
          };
        });
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Catalog data ${candidate.manifest.dataVersion} installed.',
            ),
          ),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        final code = error is CatalogUpdateException
            ? error.code
            : 'catalog_update';
        final message = code == 'cancelled'
            ? 'Catalog update cancelled. Current Catalog unchanged.'
            : 'Catalog update failed ($code). Current Catalog unchanged.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatePhase = _CatalogUpdateUiPhase.idle;
          _updateProgress = null;
          _updateCancellation = null;
        });
      }
    }
  }

  Future<bool?> _confirmCatalogDownload(CatalogUpdateCandidate candidate) =>
      showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            'Download Catalog data ${candidate.manifest.dataVersion}?',
          ),
          content: Text(
            'Download ${_formatBytes(candidate.manifest.package.archiveBytes)} '
            'using the current network connection. The complete Catalog is '
            'verified before installation. Favorites, collection marks, and '
            'notes are kept.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Later'),
            ),
            FilledButton(
              key: const ValueKey('confirm-catalog-download'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Download'),
            ),
          ],
        ),
      );

  void _cancelCatalogUpdate() {
    if (_updatePhase == _CatalogUpdateUiPhase.verifying) {
      return;
    }
    _updateCancellation?.cancel();
  }

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
    if (confirmed != true || widget.onRestoreBundledCatalog == null) {
      return;
    }
    try {
      await widget.onRestoreBundledCatalog!();
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
    final info = widget.session.info;
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
        Text('Catalog updates', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Checks are started only by you. This App does not check, '
                  'download, or install Catalog data in the background.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const ValueKey('check-catalog-update'),
                  onPressed:
                      _updateBusy ||
                          widget.onCheckCatalogUpdate == null ||
                          widget.onInstallCatalogUpdate == null
                      ? null
                      : _checkForCatalogUpdate,
                  icon: const Icon(Icons.system_update_alt_rounded),
                  label: const Text('Check for Catalog update'),
                ),
                if (_updateBusy) ...<Widget>[
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    label: _updateStatus,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(_updateStatus),
                        const SizedBox(height: 8),
                        if (_updatePhase == _CatalogUpdateUiPhase.downloading)
                          LinearProgressIndicator(
                            key: const ValueKey('catalog-update-progress'),
                            value: _updateProgress?.fraction,
                          )
                        else
                          const LinearProgressIndicator(
                            key: ValueKey('catalog-update-progress'),
                          ),
                        if (_updatePhase !=
                            _CatalogUpdateUiPhase.verifying) ...<Widget>[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            key: const ValueKey('cancel-catalog-update'),
                            onPressed: _cancelCatalogUpdate,
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Cancel'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
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
                  onPressed:
                      widget.onRestoreBundledCatalog == null || _updateBusy
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
                subtitle: Text(
                  _catalogOutcomeLabel(widget.session.catalogOutcome),
                ),
              ),
              ListTile(
                title: const Text('Personal database schema'),
                subtitle: Text('${widget.session.userSchemaVersion}'),
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
            child: SelectableText(widget.session.attribution),
          ),
        ),
      ],
    );
  }

  String get _updateStatus => switch (_updatePhase) {
    _CatalogUpdateUiPhase.idle => '',
    _CatalogUpdateUiPhase.checking => 'Checking for a Catalog update...',
    _CatalogUpdateUiPhase.downloading =>
      'Downloading ${_formatBytes(_updateProgress?.receivedBytes ?? 0)} of '
          '${_formatBytes(_updateProgress?.totalBytes ?? 0)}...',
    _CatalogUpdateUiPhase.verifying => 'Verifying and installing...',
  };
}

String _formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KiB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
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
