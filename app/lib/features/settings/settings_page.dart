import 'package:flutter/material.dart';

import '../../app_version.dart';
import '../../catalog_app.dart';
import '../../data/catalog/catalog_installer.dart';
import '../../data/catalog/catalog_update_source.dart';
import '../../l10n/app_strings.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Catalog is up to date.'))),
        );
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
              context.strings.catalogInstalled(candidate.manifest.dataVersion),
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
            ? context.tr('Catalog update cancelled. Current Catalog unchanged.')
            : context.strings.catalogUpdateFailed(code);
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
            dialogContext.strings.downloadCatalogTitle(
              candidate.manifest.dataVersion,
            ),
          ),
          content: Text(
            dialogContext.strings.downloadCatalogBody(
              _formatBytes(candidate.manifest.package.archiveBytes),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(dialogContext.tr('Later')),
            ),
            FilledButton(
              key: const ValueKey('confirm-catalog-download'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(dialogContext.tr('Download')),
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
        title: Text(dialogContext.tr('Restore bundled Catalog?')),
        content: Text(
          dialogContext.tr(
            'This replaces only the offline Catalog with the version included in this App. Favorites, collection marks, and notes are kept. The bundled version may be older than the current Catalog.',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.tr('Cancel')),
          ),
          FilledButton(
            key: const ValueKey('confirm-catalog-restore'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.tr('Restore Catalog')),
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
          SnackBar(content: Text(context.tr('Bundled Catalog restored.'))),
        );
      }
    } on Object catch (error) {
      if (context.mounted) {
        final code = error is CatalogInstallException
            ? error.code
            : 'catalog_restore';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.strings.catalogRestoreFailed(code))),
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
        Text(
          context.tr('Settings'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.brightness_auto_rounded),
                title: Text(context.tr('Theme')),
                subtitle: Text(context.tr('Follow device setting')),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.phone_iphone_rounded),
                title: Text(context.tr('Personal data')),
                subtitle: Text(
                  context.tr(
                    'Favorites, collection marks, and notes stay on this device. Uninstalling the App may remove them.',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          context.tr('Catalog updates'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.tr(
                    'Checks are started only by you. This App does not check, download, or install Catalog data in the background.',
                  ),
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
                  label: Text(context.tr('Check for Catalog update')),
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
                            label: Text(context.tr('Cancel')),
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
        Text(
          context.tr('Catalog recovery'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.tr(
                    'Restore the complete read-only Catalog shipped with this App. Personal data is stored separately and is not removed.',
                  ),
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
                  label: Text(context.tr('Restore bundled Catalog')),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          context.tr('About'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                title: Text(context.tr('App version')),
                subtitle: const Text(AppVersion.display),
              ),
              ListTile(
                title: Text(context.tr('Catalog')),
                subtitle: Text(
                  context.strings.catalogSummary(
                    info.dataVersion,
                    info.schemaVersion,
                  ),
                ),
              ),
              ListTile(
                title: Text(context.tr('Last Catalog action')),
                subtitle: Text(
                  _catalogOutcomeLabel(context, widget.session.catalogOutcome),
                ),
              ),
              ListTile(
                title: Text(context.tr('Personal database schema')),
                subtitle: Text('${widget.session.userSchemaVersion}'),
              ),
              ListTile(
                title: Text(context.tr('Source revision range')),
                subtitle: Text(
                  '${info.earliestSourceRevisionUtc} — ${info.latestSourceRevisionUtc}',
                ),
              ),
              ListTile(
                title: Text(context.tr('Catalog built')),
                subtitle: Text(info.builtAtUtc),
              ),
              ListTile(
                key: const ValueKey('open-source-licenses'),
                leading: const Icon(Icons.code_rounded),
                title: Text(context.tr('Open-source licenses')),
                subtitle: Text(context.tr('Flutter and packaged dependencies')),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: context.tr('Roco World Handbook'),
                  applicationVersion: AppVersion.display,
                  applicationLegalese: context.tr(
                    'Independent, non-commercial, and unofficial.',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          context.tr('Attribution'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
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
    _CatalogUpdateUiPhase.checking => context.tr(
      'Checking for a Catalog update...',
    ),
    _CatalogUpdateUiPhase.downloading => context.strings.downloadingProgress(
      _formatBytes(_updateProgress?.receivedBytes ?? 0),
      _formatBytes(_updateProgress?.totalBytes ?? 0),
    ),
    _CatalogUpdateUiPhase.verifying => context.tr(
      'Verifying and installing...',
    ),
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

String _catalogOutcomeLabel(BuildContext context, CatalogOpenOutcome outcome) {
  return switch (outcome) {
    CatalogOpenOutcome.reused => context.tr(
      'Opened the current validated Catalog',
    ),
    CatalogOpenOutcome.installedBundled => context.tr(
      'Installed bundled Catalog data',
    ),
    CatalogOpenOutcome.installedRemote => context.tr(
      'Installed a verified Catalog package',
    ),
    CatalogOpenOutcome.recoveredPrevious => context.tr(
      'Recovered the previous validated Catalog',
    ),
    CatalogOpenOutcome.restoredBundled => context.tr(
      'Restored the Catalog bundled with this App',
    ),
  };
}
