import 'package:flutter/material.dart';

import '../../domain/catalog_models.dart';
import '../../domain/catalog_repository.dart';
import '../../domain/game_descriptions.dart';
import '../../domain/user_repository.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/catalog_asset_image.dart';
import '../skills/skill_detail_page.dart';

class GameDescriptionCatalogPage extends StatefulWidget {
  const GameDescriptionCatalogPage({
    required this.repository,
    required this.catalogRepository,
    required this.userRepository,
    required this.datasetId,
    super.key,
  });

  final GameDescriptionRepository repository;
  final CatalogRepository catalogRepository;
  final UserRepository userRepository;
  final String datasetId;

  @override
  State<GameDescriptionCatalogPage> createState() =>
      _GameDescriptionCatalogPageState();
}

class _GameDescriptionCatalogPageState
    extends State<GameDescriptionCatalogPage> {
  final _searchController = TextEditingController();
  late final Future<GameDescriptionCatalog> _catalog = widget.repository.load();
  String? _category;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Game description handbook'))),
      body: FutureBuilder<GameDescriptionCatalog>(
        future: _catalog,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                context.tr('Game description data could not be loaded.'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildCatalog(context, snapshot.requireData);
        },
      ),
    );
  }

  Widget _buildCatalog(BuildContext context, GameDescriptionCatalog catalog) {
    final keyword = _searchController.text.trim().toLowerCase();
    final entries = catalog.entries
        .where((entry) {
          final matchesCategory =
              _category == null || entry.category == _category;
          final matchesSearch =
              keyword.isEmpty ||
              entry.name.toLowerCase().contains(keyword) ||
              entry.description.toLowerCase().contains(keyword);
          return matchesCategory && matchesSearch;
        })
        .toList(growable: false);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.tr('Read statuses, marks, weather, and battle rules.'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('game-description-search'),
                controller: _searchController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
                autocorrect: false,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: context.tr('Search game descriptions'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    ChoiceChip(
                      key: const ValueKey('game-description-category-all'),
                      label: Text(context.tr('All')),
                      selected: _category == null,
                      onSelected: (_) => setState(() => _category = null),
                    ),
                    for (final category in catalog.categoryOrder) ...<Widget>[
                      const SizedBox(width: 8),
                      ChoiceChip(
                        key: ValueKey('game-description-category-$category'),
                        avatar: Icon(_categoryIcon(category), size: 18),
                        label: Text(context.tr(_categoryLabel(category))),
                        selected: _category == category,
                        onSelected: (_) {
                          setState(() {
                            _category = _category == category ? null : category;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${entries.length} ${context.tr('descriptions')}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text(
                    context.tr('No game descriptions match these filters.'),
                  ),
                )
              : ListView.separated(
                  key: const ValueKey('game-description-list'),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final color = _categoryColor(entry.category);
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: ValueKey('game-description-${entry.noteId}'),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => GameDescriptionDetailPage(
                              entry: entry,
                              catalogRepository: widget.catalogRepository,
                              userRepository: widget.userRepository,
                              datasetId: widget.datasetId,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              CircleAvatar(
                                backgroundColor: color.withValues(alpha: 0.16),
                                foregroundColor: color,
                                child: Icon(_categoryIcon(entry.category)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            entry.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          context.tr(
                                            _categoryLabel(entry.category),
                                          ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(color: color),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      entry.description,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class GameDescriptionDetailPage extends StatelessWidget {
  const GameDescriptionDetailPage({
    required this.entry,
    required this.catalogRepository,
    required this.userRepository,
    required this.datasetId,
    super.key,
  });

  final GameDescriptionEntry entry;
  final CatalogRepository catalogRepository;
  final UserRepository userRepository;
  final String datasetId;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(entry.category);
    return Scaffold(
      appBar: AppBar(title: Text(entry.name)),
      body: FutureBuilder<List<SkillSummary>>(
        future: catalogRepository.getSkillsForDescriptionNote(entry.noteId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(context.tr('The local Catalog query failed.')),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final features = snapshot.requireData
              .where((skill) => skill.isFeature)
              .toList(growable: false);
          final skills = snapshot.requireData
              .where((skill) => !skill.isFeature)
              .toList(growable: false);
          return ListView(
            key: ValueKey('game-description-detail-${entry.noteId}'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: <Widget>[
              Card(
                color: Color.alphaBlend(
                  color.withValues(alpha: 0.14),
                  Theme.of(context).colorScheme.surfaceContainerLow,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          CircleAvatar(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            child: Icon(_categoryIcon(entry.category)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.name,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Chip(
                            label: Text(
                              context.tr(_categoryLabel(entry.category)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        context.tr('Game description'),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _RelatedSkillSection(
                title: 'Related features',
                emptyText: 'No related features are included.',
                skills: features,
                catalogRepository: catalogRepository,
                userRepository: userRepository,
                datasetId: datasetId,
              ),
              const SizedBox(height: 20),
              _RelatedSkillSection(
                title: 'Related skills',
                emptyText: 'No related skills are included.',
                skills: skills,
                catalogRepository: catalogRepository,
                userRepository: userRepository,
                datasetId: datasetId,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RelatedSkillSection extends StatelessWidget {
  const _RelatedSkillSection({
    required this.title,
    required this.emptyText,
    required this.skills,
    required this.catalogRepository,
    required this.userRepository,
    required this.datasetId,
  });

  final String title;
  final String emptyText;
  final List<SkillSummary> skills;
  final CatalogRepository catalogRepository;
  final UserRepository userRepository;
  final String datasetId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${context.tr(title)} (${skills.length})',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (skills.isEmpty)
          Text(context.tr(emptyText))
        else
          for (final skill in skills)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: CatalogAssetImage(
                  assetPath: skillIconAsset(skill),
                  semanticLabel: skill.name,
                  width: 52,
                  height: 52,
                  borderRadius: BorderRadius.circular(14),
                  fallbackIcon: skill.isFeature
                      ? Icons.auto_awesome_rounded
                      : Icons.bolt_rounded,
                ),
                title: Text(
                  skill.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: skill.description == null
                    ? null
                    : Text(
                        skill.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => SkillDetailPage(
                      repository: catalogRepository,
                      userRepository: userRepository,
                      datasetId: datasetId,
                      skillId: skill.skillId,
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

String _categoryLabel(String category) => switch (category) {
  'status' => 'Status',
  'mark' => 'Mark',
  'weather' => 'Weather',
  'action' => 'Battle action',
  'rule' => 'Battle rule',
  _ => 'Other',
};

IconData _categoryIcon(String category) => switch (category) {
  'status' => Icons.monitor_heart_outlined,
  'mark' => Icons.local_offer_outlined,
  'weather' => Icons.cloud_outlined,
  'action' => Icons.swap_horiz_rounded,
  'rule' => Icons.rule_rounded,
  _ => Icons.more_horiz_rounded,
};

Color _categoryColor(String category) => switch (category) {
  'status' => const Color(0xFF9D5360),
  'mark' => const Color(0xFF7656A2),
  'weather' => const Color(0xFF397B98),
  'action' => const Color(0xFFA86634),
  'rule' => const Color(0xFF397A64),
  _ => const Color(0xFF646B6B),
};
