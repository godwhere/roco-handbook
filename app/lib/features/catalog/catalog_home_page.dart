import 'package:flutter/material.dart';

import '../../catalog_app.dart';
import '../../data/catalog/catalog_update_source.dart';
import '../pets/pet_catalog_page.dart';
import '../settings/settings_page.dart';
import '../skills/skill_catalog_page.dart';
import '../tools/tools_page.dart';
import '../../l10n/app_strings.dart';

class CatalogHomePage extends StatefulWidget {
  const CatalogHomePage({
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
  State<CatalogHomePage> createState() => _CatalogHomePageState();
}

class _CatalogHomePageState extends State<CatalogHomePage> {
  var _index = 0;

  void _showAbout() {
    final info = widget.session.info;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.tr('About this Catalog'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _InfoRow(
                label: context.tr('Data version'),
                value: '${info.dataVersion}',
              ),
              _InfoRow(
                label: context.tr('Catalog schema'),
                value: '${info.schemaVersion}',
              ),
              _InfoRow(label: context.tr('Snapshot'), value: info.snapshotId),
              _InfoRow(label: context.tr('Built'), value: info.builtAtUtc),
              _InfoRow(
                label: context.tr('Source revision range'),
                value:
                    '${info.earliestSourceRevisionUtc} — ${info.latestSourceRevisionUtc}',
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('Coverage'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...info.coverage.entries.map(
                (entry) => _InfoRow(
                  label: context.tr(_coverageLabel(entry.key)),
                  value: context.tr(entry.value ? 'Included' : 'Not included'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('Attribution'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SelectableText(widget.session.attribution),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Roco World Handbook')),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Chip(
              visualDensity: VisualDensity.compact,
              label: Text(
                context.strings.dataVersion(widget.session.info.dataVersion),
              ),
            ),
          ),
          IconButton(
            tooltip: context.tr('Catalog information'),
            onPressed: _showAbout,
            icon: const Icon(Icons.info_outline_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: <Widget>[
          PetCatalogPage(
            key: ValueKey('pet-catalog-${widget.session.info.dataVersion}'),
            repository: widget.session.repository,
            userRepository: widget.session.userRepository,
            datasetId: widget.session.info.datasetId,
          ),
          SkillCatalogPage(
            key: ValueKey('skill-catalog-${widget.session.info.dataVersion}'),
            repository: widget.session.repository,
            userRepository: widget.session.userRepository,
            datasetId: widget.session.info.datasetId,
          ),
          ToolsPage(
            key: ValueKey('tools-${widget.session.info.dataVersion}'),
            catalogRepository: widget.session.repository,
            userRepository: widget.session.userRepository,
            datasetId: widget.session.info.datasetId,
          ),
          SettingsPage(
            session: widget.session,
            onRestoreBundledCatalog: widget.onRestoreBundledCatalog,
            onCheckCatalogUpdate: widget.onCheckCatalogUpdate,
            onInstallCatalogUpdate: widget.onInstallCatalogUpdate,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: Image.asset(
              'assets/wiki/v2/ui/navigation/creatures.png',
              width: 28,
              height: 28,
              semanticLabel: context.tr('Creatures'),
            ),
            selectedIcon: Image.asset(
              'assets/wiki/v2/ui/navigation/creatures.png',
              width: 32,
              height: 32,
              semanticLabel: context.tr('Creatures'),
            ),
            label: context.tr('Creatures'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_awesome_outlined),
            selectedIcon: const Icon(Icons.auto_awesome_rounded),
            label: context.tr('Skills'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.dashboard_customize_outlined),
            selectedIcon: const Icon(Icons.dashboard_customize_rounded),
            label: context.tr('Tools'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: context.tr('Settings'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

String _coverageLabel(String value) {
  return value
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
