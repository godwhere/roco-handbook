import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/catalog_models.dart';
import '../../domain/catalog_repository.dart';
import '../../domain/user_models.dart';
import '../../domain/user_repository.dart';
import 'pet_detail_page.dart';
import '../../l10n/app_strings.dart';
import '../../theme/catalog_theme.dart';
import '../../widgets/catalog_asset_image.dart';
import '../../widgets/pet_type_card_background.dart';

class PetCatalogPage extends StatefulWidget {
  const PetCatalogPage({
    required this.repository,
    required this.userRepository,
    required this.datasetId,
    this.layout = PetCatalogLayout.list,
    this.dataVersionLabel,
    this.onShowInformation,
    super.key,
  });

  final CatalogRepository repository;
  final UserRepository userRepository;
  final String datasetId;
  final PetCatalogLayout layout;
  final String? dataVersionLabel;
  final VoidCallback? onShowInformation;

  @override
  State<PetCatalogPage> createState() => _PetCatalogPageState();
}

class _PetCatalogPageState extends State<PetCatalogPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  var _sort = PetSort.handbook;
  var _selectedTypeIds = <String>{};
  var _selectedStages = <int>{};
  var _selectedForms = <PetFormFilter>{};
  var _shinyFilter = PetShinyFilter.any;
  var _selectedSeasons = <String>{};
  var _results = const <PetSummary>[];
  Object? _error;
  var _loading = true;
  var _loadingMore = false;
  var _hasMore = false;
  var _generation = 0;

  static const _pageSize = 60;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _scheduleSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _load);
  }

  Future<void> _load({bool append = false}) async {
    if (append && (_loadingMore || !_hasMore)) {
      return;
    }
    final generation = append ? _generation : ++_generation;
    if (mounted) {
      setState(() {
        if (append) {
          _loadingMore = true;
        } else {
          _loading = true;
        }
        _error = null;
      });
    }
    final query = PetQuery(
      keyword: _searchController.text,
      typeIds: _selectedTypeIds.toList()..sort(),
      stages: _selectedStages.toList()..sort(),
      forms: _selectedForms.toList()
        ..sort((left, right) => left.index.compareTo(right.index)),
      shiny: _shinyFilter,
      seasons: _selectedSeasons.toList()..sort(),
      sort: _sort,
      limit: _pageSize,
      offset: append ? _results.length : 0,
    );
    try {
      final results = await widget.repository.searchPets(query);
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _results = append ? <PetSummary>[..._results, ...results] : results;
        _hasMore = results.length == _pageSize;
        _loading = false;
        _loadingMore = false;
      });
    } on Object catch (error) {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _setSort(PetSort? sort) {
    if (sort == null || _sort == sort) {
      return;
    }
    setState(() => _sort = sort);
    _load();
  }

  Future<void> _showSortOptions() async {
    var selected = _sort;
    final result = await showModalBottomSheet<PetSort>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Column(
              key: const ValueKey('pet-sort-sheet'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.tr('Sort'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: PetSort.values
                      .map(
                        (sort) => ChoiceChip(
                          key: ValueKey('pet-sort-option-${sort.name}'),
                          label: Text(_sortLabel(context, sort)),
                          selected: selected == sort,
                          onSelected: (_) {
                            setSheetState(() => selected = sort);
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(context.tr('Cancel')),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, selected),
                      child: Text(context.tr('Apply')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      _setSort(result);
    }
  }

  Future<void> _showFilters() async {
    final List<CatalogType> types;
    try {
      types = await widget.repository.getTypes();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('Creature types could not be loaded.')),
          ),
        );
      }
      return;
    }
    if (!mounted) {
      return;
    }
    final selected = Set<String>.from(_selectedTypeIds);
    final result = await showModalBottomSheet<_PetCatalogFilterSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        var selectedStages = Set<int>.from(_selectedStages);
        var selectedForms = Set<PetFormFilter>.from(_selectedForms);
        var shinyFilter = _shinyFilter;
        var selectedSeasons = Set<String>.from(_selectedSeasons);
        return StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: SingleChildScrollView(
              key: const ValueKey('pet-filter-sheet'),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.tr('Creature filters'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _PetFilterHeading(label: context.tr('Shiny form')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final filter in <PetShinyFilter>[
                        PetShinyFilter.hasShiny,
                        PetShinyFilter.noShiny,
                      ])
                        ChoiceChip(
                          key: ValueKey('pet-shiny-filter-${filter.name}'),
                          label: Text(
                            context.tr(
                              filter == PetShinyFilter.hasShiny
                                  ? 'Has shiny'
                                  : 'No shiny',
                            ),
                          ),
                          selected: shinyFilter == filter,
                          onSelected: (enabled) {
                            setSheetState(() {
                              shinyFilter = enabled
                                  ? filter
                                  : PetShinyFilter.any;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _PetFilterHeading(label: context.tr('Creature stage')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final stage in const <int>[1, 2, 3])
                        FilterChip(
                          key: ValueKey('pet-stage-filter-$stage'),
                          label: Text(
                            context.tr(switch (stage) {
                              1 => 'First stage',
                              2 => 'Second stage',
                              _ => 'Third stage',
                            }),
                          ),
                          selected: selectedStages.contains(stage),
                          onSelected: (enabled) {
                            setSheetState(() {
                              enabled
                                  ? selectedStages.add(stage)
                                  : selectedStages.remove(stage);
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _PetFilterHeading(label: context.tr('Creature form')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final form in PetFormFilter.values)
                        FilterChip(
                          key: ValueKey('pet-form-filter-${form.name}'),
                          label: Text(
                            context.tr(switch (form) {
                              PetFormFilter.main => 'Main form',
                              PetFormFilter.regional => 'Regional form',
                              PetFormFilter.lord => 'Lord form',
                            }),
                          ),
                          selected: selectedForms.contains(form),
                          onSelected: (enabled) {
                            setSheetState(() {
                              enabled
                                  ? selectedForms.add(form)
                                  : selectedForms.remove(form);
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _PetFilterHeading(label: context.tr('Owning season')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final season in const <String>['1', '2', '3', '4'])
                        FilterChip(
                          key: ValueKey('pet-season-filter-$season'),
                          label: Text('S$season'),
                          selected: selectedSeasons.contains(season),
                          onSelected: (enabled) {
                            setSheetState(() {
                              enabled
                                  ? selectedSeasons.add(season)
                                  : selectedSeasons.remove(season);
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _PetFilterHeading(label: context.tr('Creature type')),
                  const SizedBox(height: 6),
                  Text(context.tr('A creature may match any selected type.')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: types
                        .map(
                          (type) => FilterChip(
                            label: TypeIconLabel(
                              typeName: type.name,
                              compact: true,
                            ),
                            selected: selected.contains(type.typeId),
                            onSelected: (enabled) {
                              setSheetState(() {
                                if (enabled) {
                                  selected.add(type.typeId);
                                } else {
                                  selected.remove(type.typeId);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            selected.clear();
                            selectedStages.clear();
                            selectedForms.clear();
                            shinyFilter = PetShinyFilter.any;
                            selectedSeasons.clear();
                          });
                        },
                        child: Text(context.tr('Clear')),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(context.tr('Cancel')),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Navigator.pop(
                          context,
                          _PetCatalogFilterSelection(
                            typeIds: selected,
                            stages: selectedStages,
                            forms: selectedForms,
                            shiny: shinyFilter,
                            seasons: selectedSeasons,
                          ),
                        ),
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
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _selectedTypeIds = result.typeIds;
      _selectedStages = result.stages;
      _selectedForms = result.forms;
      _shinyFilter = result.shiny;
      _selectedSeasons = result.seasons;
    });
    _load();
  }

  void _open(PetSummary pet) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PetDetailPage(
          repository: widget.repository,
          userRepository: widget.userRepository,
          datasetId: widget.datasetId,
          initialPetId: pet.petId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showsHero = widget.dataVersionLabel != null;
    return SafeArea(
      key: const ValueKey('pet-catalog-safe-area'),
      top: showsHero,
      bottom: false,
      child: Column(
        children: <Widget>[
          if (showsHero)
            _CatalogHeroHeader(
              dataVersionLabel: widget.dataVersionLabel!,
              onShowInformation: widget.onShowInformation,
              child: _buildToolbar(context, inHero: true),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: _buildToolbar(context),
            ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, {bool inHero = false}) {
    final scheme = Theme.of(context).colorScheme;
    final fieldBorderColor = inHero ? const Color(0xFF8BBEF4) : scheme.outline;
    final fillColor = inHero
        ? scheme.surface.withValues(alpha: 0.58)
        : Colors.transparent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _CompactFilterButton(
                key: const ValueKey('pet-sort'),
                icon: Icons.sort_rounded,
                label: context.tr('Sort'),
                semanticValue: _sortLabel(context, _sort),
                borderColor: inHero ? fieldBorderColor : null,
                fillColor: fillColor,
                onPressed: _showSortOptions,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CompactFilterButton(
                key: const ValueKey('pet-filters'),
                icon: Icons.filter_alt_outlined,
                label: _selectedFilterCount == 0
                    ? context.tr(inHero ? 'Types' : 'Filters')
                    : '${context.tr('Filters')} ($_selectedFilterCount)',
                borderColor: inHero ? fieldBorderColor : null,
                fillColor: fillColor,
                onPressed: _showFilters,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 56,
                child: TextField(
                  key: const ValueKey('pet-search'),
                  controller: _searchController,
                  onChanged: _scheduleSearch,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: context.tr('Search creatures'),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: context.tr('Clear search'),
                            onPressed: () {
                              _searchController.clear();
                              _load();
                            },
                            icon: const Icon(Icons.clear_rounded),
                          ),
                    filled: inHero,
                    fillColor: fillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(color: fieldBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(color: fieldBorderColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_searchController.text.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            context.tr(
              'Search results show concrete forms so a matching form opens directly.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  int get _selectedFilterCount =>
      _selectedTypeIds.length +
      _selectedStages.length +
      _selectedForms.length +
      _selectedSeasons.length +
      (_shinyFilter == PetShinyFilter.any ? 0 : 1);

  Widget _buildResults() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _QueryFailure(onRetry: _load);
    }
    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.search_off_rounded, size: 48),
              const SizedBox(height: 12),
              Text(
                context.tr('No creatures match this search.'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _selectedTypeIds.clear();
                    _selectedStages.clear();
                    _selectedForms.clear();
                    _shinyFilter = PetShinyFilter.any;
                    _selectedSeasons.clear();
                  });
                  _load();
                },
                child: Text(context.tr('Clear search and filters')),
              ),
            ],
          ),
        ),
      );
    }
    return switch (widget.layout) {
      PetCatalogLayout.list => _buildListResults(),
      PetCatalogLayout.grid => _buildGridResults(),
    };
  }

  Widget _buildListResults() {
    final bottomClearance = MediaQuery.paddingOf(context).bottom + 24;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        key: const ValueKey('pet-list-results'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(16, 2, 16, bottomClearance),
        itemCount: _results.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == _results.length) {
            return _buildLoadMoreButton();
          }
          final pet = _results[index];
          return _PetResultCard(
            key: ValueKey('pet-result-${pet.petId}'),
            pet: pet,
            onTap: () => _open(pet),
          );
        },
      ),
    );
  }

  Widget _buildGridResults() {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    final bottomClearance = MediaQuery.paddingOf(context).bottom + 12;
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        key: const ValueKey('pet-grid-results'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: <Widget>[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(12, 2, 12, bottomClearance),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.crossAxisExtent >= 720 ? 3 : 2;
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.66 / (1 + ((scale - 1) * 0.24)),
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final pet = _results[index];
                    return _PetGridResultCard(
                      key: ValueKey('pet-result-${pet.petId}'),
                      pet: pet,
                      onTap: () => _open(pet),
                    );
                  }, childCount: _results.length),
                );
              },
            ),
          ),
          if (_hasMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: _buildLoadMoreButton(),
              ),
            ),
          if (!_hasMore) const SliverToBoxAdapter(child: SizedBox(height: 12)),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Center(
      child: OutlinedButton.icon(
        onPressed: _loadingMore ? null : () => _load(append: true),
        icon: _loadingMore
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.expand_more_rounded),
        label: Text(context.tr(_loadingMore ? 'Loading...' : 'Load more')),
      ),
    );
  }
}

String _sortLabel(BuildContext context, PetSort sort) {
  return switch (sort) {
    PetSort.handbook => context.tr('Handbook number'),
    PetSort.name => context.tr('Name'),
    PetSort.attack => context.tr('Attack, high to low'),
    PetSort.magicAttack => context.tr('Magic attack, high to low'),
    PetSort.speed => context.tr('Speed, high to low'),
  };
}

class _CatalogHeroHeader extends StatelessWidget {
  const _CatalogHeroHeader({
    required this.dataVersionLabel,
    required this.child,
    this.onShowInformation,
  });

  final String dataVersionLabel;
  final VoidCallback? onShowInformation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? scheme.onSurface : const Color(0xFF19345E);
    final subtitleColor = isDark
        ? scheme.onSurfaceVariant
        : const Color(0xFF68778F);
    return Container(
      key: const ValueKey('pet-catalog-hero'),
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        image: DecorationImage(
          image: const AssetImage(
            'assets/brand/v1/catalog-header-background.png',
          ),
          fit: BoxFit.cover,
          colorFilter: isDark
              ? const ColorFilter.mode(Color(0x99000000), BlendMode.darken)
              : null,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: 88,
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: 0,
                  left: 0,
                  right: 112,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.tr('Roco World Handbook'),
                      maxLines: 1,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: titleColor,
                        fontSize: 40,
                        height: 1,
                        shadows: <Shadow>[
                          Shadow(
                            color: scheme.surface.withValues(alpha: 0.9),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  bottom: 4,
                  child: Text(
                    context.tr(
                      'Explore the creature world · collect every encounter',
                    ),
                    maxLines: 1,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: subtitleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(
                        height: 42,
                        child: OutlinedButton.icon(
                          key: const ValueKey('pet-catalog-data-version'),
                          onPressed: onShowInformation,
                          icon: const Icon(Icons.menu_book_rounded, size: 19),
                          label: Text(dataVersionLabel),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E5A9B),
                            backgroundColor: scheme.surface.withValues(
                              alpha: 0.58,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            side: const BorderSide(color: Color(0xFF78B7F5)),
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox.square(
                        dimension: 42,
                        child: IconButton.outlined(
                          key: const ValueKey('pet-catalog-information'),
                          tooltip: context.tr('Catalog information'),
                          onPressed: onShowInformation,
                          color: const Color(0xFF1E5A9B),
                          style: IconButton.styleFrom(
                            backgroundColor: scheme.surface.withValues(
                              alpha: 0.58,
                            ),
                            side: const BorderSide(color: Color(0xFF78B7F5)),
                          ),
                          icon: const Icon(Icons.info_outline_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PetResultCard extends StatelessWidget {
  const _PetResultCard({required this.pet, required this.onTap, super.key});

  final PetSummary pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final form = !pet.isDefaultForm && pet.form?.trim().isNotEmpty == true
        ? '\uff08${pet.form!.trim()}\uff09'
        : null;
    return Card(
      child: PetTypeCardBackground(
        key: ValueKey('pet-type-background-${pet.petId}'),
        types: pet.types,
        warmLight:
            !pet.isDefaultForm &&
            pet.types.length == 1 &&
            pet.types.first == '\u5149\u7cfb',
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: <Widget>[
                CatalogAssetImage(
                  assetPath: petIllustrationAsset(pet.illustrationKey),
                  semanticLabel: pet.name,
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                  fallbackIcon: Icons.pets_outlined,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: FittedBox(
                              key: ValueKey('pet-title-fit-${pet.petId}'),
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: <Widget>[
                                  Text(
                                    pet.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: pet.hasShiny
                                              ? _seasonColor(
                                                  context,
                                                  pet.belongSeason,
                                                )
                                              : null,
                                        ),
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                  if (form != null) ...<Widget>[
                                    const SizedBox(width: 6),
                                    Text(
                                      form,
                                      key: ValueKey('pet-form-${pet.petId}'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                      maxLines: 1,
                                      softWrap: false,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'NO.${pet.dexNo}',
                            key: ValueKey('pet-dex-${pet.petId}'),
                            style: CatalogTypography.numbers(
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: <Widget>[
                                for (final type in pet.types)
                                  Tooltip(
                                    message: type,
                                    child: CatalogAssetImage(
                                      key: ValueKey(
                                        'pet-type-${pet.petId}-$type',
                                      ),
                                      assetPath: typeIconAsset(type),
                                      semanticLabel: type,
                                      width: 28,
                                      height: 28,
                                      fallbackIcon: Icons.circle_outlined,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PetGridResultCard extends StatelessWidget {
  const _PetGridResultCard({required this.pet, required this.onTap, super.key});

  final PetSummary pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final form = !pet.isDefaultForm && pet.form?.trim().isNotEmpty == true
        ? pet.form!.trim()
        : null;
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: PetTypeCardBackground(
        key: ValueKey('pet-grid-type-background-${pet.petId}'),
        types: pet.types,
        grid: true,
        warmLight:
            !pet.isDefaultForm &&
            pet.types.length == 1 &&
            pet.types.first == '\u5149\u7cfb',
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => CatalogAssetImage(
                      assetPath: petIllustrationAsset(pet.illustrationKey),
                      semanticLabel: pet.name,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      fit: BoxFit.contain,
                      fallbackIcon: Icons.pets_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          FittedBox(
                            key: ValueKey('pet-grid-title-fit-${pet.petId}'),
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              pet.name,
                              maxLines: 1,
                              softWrap: false,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: pet.hasShiny
                                    ? _seasonColor(context, pet.belongSeason)
                                    : null,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                            child: form == null
                                ? null
                                : FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      form,
                                      key: ValueKey(
                                        'pet-grid-form-${pet.petId}',
                                      ),
                                      maxLines: 1,
                                      softWrap: false,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.surface.withValues(
                          alpha: 0.72,
                        ),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: const SizedBox.square(
                        dimension: 34,
                        child: Icon(Icons.chevron_right_rounded, size: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: <Widget>[
                          for (final type in pet.types)
                            Tooltip(
                              message: type,
                              child: CatalogAssetImage(
                                key: ValueKey(
                                  'pet-grid-type-${pet.petId}-$type',
                                ),
                                assetPath: typeIconAsset(type),
                                semanticLabel: type,
                                width: 27,
                                height: 27,
                                fallbackIcon: Icons.circle_outlined,
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'NO.${pet.dexNo}',
                      key: ValueKey('pet-grid-dex-${pet.petId}'),
                      style: CatalogTypography.numbers(
                        theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PetCatalogFilterSelection {
  const _PetCatalogFilterSelection({
    required this.typeIds,
    required this.stages,
    required this.forms,
    required this.shiny,
    required this.seasons,
  });

  final Set<String> typeIds;
  final Set<int> stages;
  final Set<PetFormFilter> forms;
  final PetShinyFilter shiny;
  final Set<String> seasons;
}

class _PetFilterHeading extends StatelessWidget {
  const _PetFilterHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

Color _seasonColor(BuildContext context, String? season) {
  final brightness = Theme.of(context).brightness;
  return switch (season) {
    '1' =>
      brightness == Brightness.dark
          ? const Color(0xFFA9B4FF)
          : const Color(0xFF5869C2),
    '2' =>
      brightness == Brightness.dark
          ? const Color(0xFFFFAEC3)
          : const Color(0xFFB85E7A),
    '3' =>
      brightness == Brightness.dark
          ? const Color(0xFF89D8C5)
          : const Color(0xFF2F7C6C),
    '4' =>
      brightness == Brightness.dark
          ? const Color(0xFFC3C4FF)
          : const Color(0xFF6767A8),
    _ => Theme.of(context).colorScheme.primary,
  };
}

class _CompactFilterButton extends StatelessWidget {
  const _CompactFilterButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.semanticValue,
    this.borderColor,
    this.fillColor,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? semanticValue;
  final Color? borderColor;
  final Color? fillColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      value: semanticValue,
      button: true,
      child: SizedBox(
        height: 56,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: borderColor == null
                ? null
                : const Color(0xFF1E5A9B),
            backgroundColor: fillColor,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            side: borderColor == null ? null : BorderSide(color: borderColor!),
            shape: const StadiumBorder(),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 20),
                const SizedBox(width: 4),
                Text(label, maxLines: 1),
                const SizedBox(width: 1),
                const Icon(Icons.arrow_drop_down_rounded, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QueryFailure extends StatelessWidget {
  const _QueryFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 12),
            Text(context.tr('The local Catalog query failed.')),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: Text(context.tr('Try again')),
            ),
          ],
        ),
      ),
    );
  }
}
