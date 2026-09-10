import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/catalog/asset_game_description_repository.dart';
import '../../data/catalog/asset_tool_catalog_repository.dart';
import '../../domain/catalog_models.dart';
import '../../domain/catalog_repository.dart';
import '../../domain/game_descriptions.dart';
import '../../domain/tool_catalogs.dart';
import '../../domain/user_repository.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/catalog_asset_image.dart';
import '../personal/my_library_page.dart';
import '../pets/pet_detail_page.dart';
import '../skills/skill_detail_page.dart';
import 'activity_timeline_page.dart';
import 'game_description_page.dart';
import 'outfit_inspiration_page.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({
    required this.catalogRepository,
    required this.userRepository,
    required this.datasetId,
    this.gameDescriptionRepository = const AssetGameDescriptionRepository(),
    this.activityTimelineRepository = const AssetActivityTimelineRepository(),
    this.fashionCatalogRepository = const AssetFashionCatalogRepository(),
    super.key,
  });

  final CatalogRepository catalogRepository;
  final UserRepository userRepository;
  final String datasetId;
  final GameDescriptionRepository gameDescriptionRepository;
  final ActivityTimelineRepository activityTimelineRepository;
  final FashionCatalogRepository fashionCatalogRepository;

  void _open(BuildContext context, Widget page) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    final cards = <_ToolCardData>[
      _ToolCardData(
        keyName: 'season-archive',
        title: 'Season archive',
        description: 'Browse creatures by their stored season.',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF536E73),
        onTap: () => _open(
          context,
          SeasonArchivePage(
            repository: catalogRepository,
            userRepository: userRepository,
            datasetId: datasetId,
          ),
        ),
      ),
      _ToolCardData(
        keyName: 'feature-handbook',
        title: 'Feature handbook',
        description: 'Browse every source-backed creature feature.',
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFF6B5E4D),
        onTap: () => _open(
          context,
          FeatureHandbookPage(
            repository: catalogRepository,
            userRepository: userRepository,
            datasetId: datasetId,
          ),
        ),
      ),
      _ToolCardData(
        keyName: 'egg-groups',
        title: 'Egg groups',
        description: 'Find creatures that share an egg group.',
        icon: Icons.egg_alt_rounded,
        color: const Color(0xFF5E735E),
        onTap: () => _open(
          context,
          EggGroupsPage(
            repository: catalogRepository,
            userRepository: userRepository,
            datasetId: datasetId,
          ),
        ),
      ),
      _ToolCardData(
        keyName: 'game-descriptions',
        title: 'Game descriptions',
        description: 'Browse source terminology and descriptions.',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF746D62),
        onTap: () => _open(
          context,
          GameDescriptionCatalogPage(
            repository: gameDescriptionRepository,
            catalogRepository: catalogRepository,
            userRepository: userRepository,
            datasetId: datasetId,
          ),
        ),
      ),
      _ToolCardData(
        keyName: 'event-timeline',
        title: 'Event timeline',
        description: 'Review activities on a chronological timeline.',
        icon: Icons.timeline_rounded,
        color: const Color(0xFF8B6B35),
        onTap: () => _open(
          context,
          ActivityTimelinePage(repository: activityTimelineRepository),
        ),
      ),
      _ToolCardData(
        keyName: 'outfit-inspiration',
        title: 'Outfit inspiration',
        description: 'Browse source-backed outfit ideas.',
        icon: Icons.checkroom_rounded,
        color: const Color(0xFF8A567B),
        onTap: () => _open(
          context,
          OutfitInspirationPage(repository: fashionCatalogRepository),
        ),
      ),
      _ToolCardData(
        keyName: 'personal-library',
        title: 'Personal library',
        description: 'Open favorites, collection marks, and notes.',
        icon: Icons.bookmark_rounded,
        color: const Color(0xFF5F6279),
        onTap: () => _open(
          context,
          Scaffold(
            appBar: AppBar(title: Text(context.tr('My Library'))),
            body: MyLibraryPage(
              catalogRepository: catalogRepository,
              userRepository: userRepository,
              datasetId: datasetId,
            ),
          ),
        ),
      ),
    ];
    return SafeArea(
      top: false,
      child: ListView.separated(
        key: const ValueKey('tools-page'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        itemCount: cards.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.tr('Offline tools'),
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(context.tr('Explore the Catalog from new angles.')),
                ],
              ),
            );
          }
          return _ToolCard(data: cards[index - 1]);
        },
      ),
    );
  }
}

class _ToolCardData {
  const _ToolCardData({
    required this.keyName,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String keyName;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.data});

  final _ToolCardData data;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return Card(
      key: ValueKey('tool-card-${data.keyName}'),
      clipBehavior: Clip.antiAlias,
      color: Color.alphaBlend(
        data.color.withValues(alpha: 0.16),
        Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: data.color.withValues(alpha: 0.28)),
      ),
      child: InkWell(
        onTap: data.onTap,
        child: SizedBox(
          height: 112,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 0,
                  right: 64,
                  top: 0,
                  child: Text(
                    context.tr(data.title),
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(
                      dimension: 52,
                      child: Icon(data.icon, size: 26, color: data.color),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 48,
                  bottom: 0,
                  child: Text(
                    context.tr(data.description),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: foreground.withValues(alpha: 0.65)),
                  ),
                ),
                const Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(Icons.north_east_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SeasonArchivePage extends StatelessWidget {
  const SeasonArchivePage({
    required this.repository,
    required this.userRepository,
    required this.datasetId,
    super.key,
  });

  final CatalogRepository repository;
  final UserRepository userRepository;
  final String datasetId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Season archive'))),
      body: FutureBuilder<List<List<PetSummary>>>(
        future: Future.wait<List<PetSummary>>(<Future<List<PetSummary>>>[
          for (final season in const <String>['1', '2', '3', '4'])
            repository.searchPets(
              PetQuery(seasons: <String>[season], limit: 200),
            ),
        ]),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(context.tr('The local Catalog query failed.')),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final results = snapshot.requireData;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final season = '${index + 1}';
              final seasonName = context.strings.seasonName(index + 1);
              final color = _seasonColor(index + 1);
              return Card(
                color: Color.alphaBlend(
                  color.withValues(alpha: 0.18),
                  Theme.of(context).colorScheme.surfaceContainerLow,
                ),
                child: ListTile(
                  key: ValueKey('season-archive-s$season'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    child: Text('S$season'),
                  ),
                  title: Text(
                    'S$season · $seasonName',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${results[index].length} ${context.tr('members')}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => _PetListPage(
                        title: 'S$season · $seasonName',
                        emptyMessage:
                            'No creatures are included for this season yet.',
                        repository: repository,
                        userRepository: userRepository,
                        datasetId: datasetId,
                        query: PetQuery(seasons: <String>[season], limit: 200),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class FeatureHandbookPage extends StatelessWidget {
  const FeatureHandbookPage({
    required this.repository,
    required this.userRepository,
    required this.datasetId,
    super.key,
  });

  final CatalogRepository repository;
  final UserRepository userRepository;
  final String datasetId;

  Future<List<SkillSummary>> _loadFeatures() async {
    const pageSize = 200;
    final features = <SkillSummary>[];
    while (true) {
      final page = await repository.searchSkills(
        SkillQuery(
          filter: SkillFilter.features,
          limit: pageSize,
          offset: features.length,
        ),
      );
      features.addAll(page);
      if (page.length < pageSize) {
        return features;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Feature handbook'))),
      body: FutureBuilder<List<SkillSummary>>(
        future: _loadFeatures(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(context.tr('Feature handbook could not be loaded.')),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final features = snapshot.requireData;
          return ListView.separated(
            key: const ValueKey('feature-handbook-list'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: features.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final feature = features[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CatalogAssetImage(
                    assetPath: skillIconAsset(feature),
                    semanticLabel: feature.name,
                    width: 56,
                    height: 56,
                    borderRadius: BorderRadius.circular(28),
                    fallbackIcon: Icons.auto_awesome_rounded,
                  ),
                  title: Text(
                    feature.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: feature.description == null
                      ? null
                      : Text(
                          feature.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => SkillDetailPage(
                        repository: repository,
                        userRepository: userRepository,
                        datasetId: datasetId,
                        skillId: feature.skillId,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class EggGroupsPage extends StatefulWidget {
  const EggGroupsPage({
    required this.repository,
    required this.userRepository,
    required this.datasetId,
    super.key,
  });

  final CatalogRepository repository;
  final UserRepository userRepository;
  final String datasetId;

  @override
  State<EggGroupsPage> createState() => _EggGroupsPageState();
}

class _EggGroupsPageState extends State<EggGroupsPage> {
  static const _pageSize = 80;

  final _searchController = TextEditingController();
  final _selectedGroupIds = <int>{};
  List<EggGroupSummary>? _groups;
  List<PetSummary> _pets = const <PetSummary>[];
  Timer? _searchDebounce;
  Object? _error;
  bool _loading = true;
  bool _hasMore = false;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await widget.repository.getEggGroups();
      if (!mounted) return;
      setState(() => _groups = groups);
      await _loadPets(reset: true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _scheduleSearch(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 250),
      () => _loadPets(reset: true),
    );
    setState(() {});
  }

  Future<void> _loadPets({required bool reset}) async {
    final groups = _groups;
    if (groups == null) return;
    final generation = ++_requestGeneration;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _pets = const <PetSummary>[];
        _hasMore = false;
      }
    });
    try {
      final allowedGroupIds =
          _selectedGroupIds.isEmpty
                ? groups
                      .map((group) => group.eggGroupId)
                      .toList(growable: false)
                : _selectedGroupIds.toList(growable: false)
            ..sort();
      final offset = reset ? 0 : _pets.length;
      final page = allowedGroupIds.isEmpty
          ? const <PetSummary>[]
          : await widget.repository.searchPets(
              PetQuery(
                keyword: _searchController.text.trim(),
                eggGroupIds: allowedGroupIds,
                limit: _pageSize,
                offset: offset,
              ),
            );
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _pets = reset ? page : <PetSummary>[..._pets, ...page];
        _hasMore = page.length == _pageSize;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _showFilters() async {
    final groups = _groups;
    if (groups == null) return;
    final selected = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final draft = Set<int>.of(_selectedGroupIds);
        return StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            key: const ValueKey('egg-group-filter-sheet'),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                20 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    context.tr('Egg-group filters'),
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('A creature may match any selected egg group.'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final group in groups)
                        FilterChip(
                          key: ValueKey('egg-group-filter-${group.eggGroupId}'),
                          selected: draft.contains(group.eggGroupId),
                          label: Text(
                            '${context.tr(_eggGroupName(group.eggGroupId))} '
                            '${group.memberCount}',
                          ),
                          onSelected: (value) => setSheetState(() {
                            if (value) {
                              draft.add(group.eggGroupId);
                            } else {
                              draft.remove(group.eggGroupId);
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      TextButton(
                        key: const ValueKey('egg-group-filters-clear'),
                        onPressed: () => setSheetState(draft.clear),
                        child: Text(context.tr('Clear')),
                      ),
                      const Spacer(),
                      FilledButton(
                        key: const ValueKey('egg-group-filters-apply'),
                        onPressed: () => Navigator.of(context).pop(draft),
                        child: Text(context.tr('Apply')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedGroupIds
        ..clear()
        ..addAll(selected);
    });
    await _loadPets(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Egg groups'))),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('egg-group-filters'),
                    onPressed: _groups == null ? null : _showFilters,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Icons.filter_alt_outlined),
                    label: Text(
                      _selectedGroupIds.isEmpty
                          ? context.tr('Filters')
                          : '${context.tr('Filters')} '
                                '(${_selectedGroupIds.length})',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    key: const ValueKey('egg-group-search'),
                    controller: _searchController,
                    onChanged: _scheduleSearch,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: context.tr('Search creatures'),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: context.tr('Clear search'),
                              onPressed: () {
                                _searchController.clear();
                                _loadPets(reset: true);
                              },
                              icon: const Icon(Icons.clear_rounded),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildEggGroupResults(context)),
        ],
      ),
    );
  }

  Widget _buildEggGroupResults(BuildContext context) {
    if (_groups == null && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _pets.isEmpty) {
      return Center(child: Text(context.tr('Egg groups could not be loaded.')));
    }
    if (!_loading && _pets.isEmpty) {
      return Center(child: Text(context.tr('No creatures match this search.')));
    }
    return ListView.separated(
      key: const ValueKey('egg-groups-list'),
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
      itemCount: _pets.length + (_hasMore || _loading ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == _pets.length) {
          return Center(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )
                : TextButton(
                    key: const ValueKey('egg-groups-load-more'),
                    onPressed: () => _loadPets(reset: false),
                    child: Text(context.tr('Load more')),
                  ),
          );
        }
        final pet = _pets[index];
        return Card(
          child: ListTile(
            key: ValueKey('egg-group-pet-${pet.petId}'),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            leading: CatalogAssetImage(
              assetPath: petIllustrationAsset(pet.illustrationKey),
              semanticLabel: pet.name,
              width: 64,
              height: 64,
              fallbackIcon: Icons.pets_outlined,
            ),
            title: Text(
              pet.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('NO.${pet.dexNo}'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => PetDetailPage(
                  repository: widget.repository,
                  userRepository: widget.userRepository,
                  datasetId: widget.datasetId,
                  initialPetId: pet.petId,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PetListPage extends StatelessWidget {
  const _PetListPage({
    required this.title,
    required this.emptyMessage,
    required this.repository,
    required this.userRepository,
    required this.datasetId,
    required this.query,
  });

  final String title;
  final String emptyMessage;
  final CatalogRepository repository;
  final UserRepository userRepository;
  final String datasetId;
  final PetQuery query;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<PetSummary>>(
        future: repository.searchPets(query),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(context.tr('The local Catalog query failed.')),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final pets = snapshot.requireData;
          if (pets.isEmpty) {
            return Center(child: Text(context.tr(emptyMessage)));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: pets.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final pet = pets[index];
              return Card(
                child: ListTile(
                  leading: CatalogAssetImage(
                    assetPath: petIllustrationAsset(pet.illustrationKey),
                    semanticLabel: pet.name,
                    width: 64,
                    height: 64,
                    fallbackIcon: Icons.pets_outlined,
                  ),
                  title: Text(pet.name),
                  subtitle: Text('NO.${pet.dexNo}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => PetDetailPage(
                        repository: repository,
                        userRepository: userRepository,
                        datasetId: datasetId,
                        initialPetId: pet.petId,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Color _seasonColor(int season) => switch (season) {
  1 => const Color(0xFF5869C2),
  2 => const Color(0xFFB85E7A),
  3 => const Color(0xFF2F7C6C),
  _ => const Color(0xFF6767A8),
};

String _eggGroupName(int id) => switch (id) {
  1 => 'Undiscovered',
  2 => 'Giant Spirit Group',
  3 => 'Amphibious Group',
  4 => 'Insect Group',
  5 => 'Sky Group',
  6 => 'Animal Group',
  7 => 'Fairy Group',
  8 => 'Plant Group',
  9 => 'Humanoid Group',
  10 => 'Soft-bodied Group',
  11 => 'Earth Group',
  12 => 'Magic Group',
  13 => 'Ocean Group',
  14 => 'Flying Dragon Group',
  15 => 'Mechanical Group',
  _ => 'Unknown',
};
