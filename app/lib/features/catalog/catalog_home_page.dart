import 'package:flutter/material.dart';

import '../../catalog_app.dart';
import '../../data/catalog/catalog_update_source.dart';
import '../../domain/user_models.dart';
import '../pets/pet_catalog_page.dart';
import '../settings/settings_page.dart';
import '../skills/skill_catalog_page.dart';
import '../tools/tools_page.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/catalog_platform_navigation.dart';

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
  var _petCatalogLayout = PetCatalogLayout.grid;

  @override
  void initState() {
    super.initState();
    _loadPetCatalogLayout();
  }

  Future<void> _loadPetCatalogLayout() async {
    try {
      final layout = await widget.session.userRepository.getPetCatalogLayout();
      if (mounted && layout != _petCatalogLayout) {
        setState(() => _petCatalogLayout = layout);
      }
    } on Object {
      // A damaged optional preference must not block the offline Catalog.
    }
  }

  Future<void> _setPetCatalogLayout(PetCatalogLayout layout) async {
    if (layout == _petCatalogLayout) {
      return;
    }
    final previous = _petCatalogLayout;
    setState(() => _petCatalogLayout = layout);
    try {
      await widget.session.userRepository.setPetCatalogLayout(layout);
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _petCatalogLayout = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('Creature catalog layout could not be saved.'),
          ),
        ),
      );
    }
  }

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
      appBar: CatalogPlatformAppBar(
        title: context.tr('Roco World Handbook'),
        dataVersionLabel: context.strings.dataVersion(
          widget.session.info.dataVersion,
        ),
        onShowInformation: _showAbout,
        informationAccessibilityLabel: context.tr('Catalog information'),
      ),
      body: IndexedStack(
        index: _index,
        children: <Widget>[
          PetCatalogPage(
            key: ValueKey('pet-catalog-${widget.session.info.dataVersion}'),
            repository: widget.session.repository,
            userRepository: widget.session.userRepository,
            datasetId: widget.session.info.datasetId,
            layout: _petCatalogLayout,
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
            petCatalogLayout: _petCatalogLayout,
            onPetCatalogLayoutChanged: _setPetCatalogLayout,
            onRestoreBundledCatalog: widget.onRestoreBundledCatalog,
            onCheckCatalogUpdate: widget.onCheckCatalogUpdate,
            onInstallCatalogUpdate: widget.onInstallCatalogUpdate,
          ),
        ],
      ),
      bottomNavigationBar: CatalogPlatformBottomNavigation(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        labels: <String>[
          context.tr('Creatures'),
          context.tr('Skills'),
          context.tr('Tools'),
          context.tr('Settings'),
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
