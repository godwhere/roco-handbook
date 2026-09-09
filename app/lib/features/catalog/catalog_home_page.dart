import 'package:flutter/material.dart';

import '../../catalog_app.dart';
import '../../domain/user_models.dart';
import '../pets/pet_catalog_page.dart';
import '../personal/my_library_page.dart';
import '../settings/settings_page.dart';
import '../skills/skill_catalog_page.dart';

class CatalogHomePage extends StatefulWidget {
  const CatalogHomePage({required this.session, super.key});

  final CatalogSession session;

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
                'About this Catalog',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _InfoRow(label: 'Data version', value: '${info.dataVersion}'),
              _InfoRow(label: 'Catalog schema', value: '${info.schemaVersion}'),
              _InfoRow(label: 'Snapshot', value: info.snapshotId),
              _InfoRow(label: 'Built', value: info.builtAtUtc),
              _InfoRow(
                label: 'Source revision range',
                value:
                    '${info.earliestSourceRevisionUtc} — ${info.latestSourceRevisionUtc}',
              ),
              const SizedBox(height: 16),
              Text('Coverage', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...info.coverage.entries.map(
                (entry) => _InfoRow(
                  label: _coverageLabel(entry.key),
                  value: entry.value ? 'Included' : 'Not included',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Attribution',
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
        title: const Text('Roco Handbook'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Chip(
              visualDensity: VisualDensity.compact,
              label: Text('Data v${widget.session.info.dataVersion}'),
            ),
          ),
          IconButton(
            tooltip: 'Catalog information',
            onPressed: _showAbout,
            icon: const Icon(Icons.info_outline_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: StreamBuilder<List<FavoriteItem>>(
        initialData: const <FavoriteItem>[],
        stream: widget.session.userRepository.watchFavorites(),
        builder: (context, snapshot) {
          final favoriteKeys =
              snapshot.data
                  ?.where(
                    (item) =>
                        item.object.datasetId == widget.session.info.datasetId,
                  )
                  .map((item) => item.object.key)
                  .toSet() ??
              <String>{};
          return IndexedStack(
            index: _index,
            children: <Widget>[
              PetCatalogPage(
                repository: widget.session.repository,
                userRepository: widget.session.userRepository,
                datasetId: widget.session.info.datasetId,
                favoriteKeys: favoriteKeys,
              ),
              SkillCatalogPage(
                repository: widget.session.repository,
                userRepository: widget.session.userRepository,
                datasetId: widget.session.info.datasetId,
                favoriteKeys: favoriteKeys,
              ),
              MyLibraryPage(
                catalogRepository: widget.session.repository,
                userRepository: widget.session.userRepository,
                datasetId: widget.session.info.datasetId,
              ),
              SettingsPage(session: widget.session),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets_rounded),
            label: 'Creatures',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome_rounded),
            label: 'Skills',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: 'My Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
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
