import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/catalog_models.dart';
import '../../domain/catalog_repository.dart';
import '../../domain/user_models.dart';
import '../../domain/user_repository.dart';
import '../personal/personal_controls.dart';
import 'pet_detail_page.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/catalog_asset_image.dart';

class PetCatalogPage extends StatefulWidget {
  const PetCatalogPage({
    required this.repository,
    required this.userRepository,
    required this.datasetId,
    required this.favoriteKeys,
    super.key,
  });

  final CatalogRepository repository;
  final UserRepository userRepository;
  final String datasetId;
  final Set<String> favoriteKeys;

  @override
  State<PetCatalogPage> createState() => _PetCatalogPageState();
}

class _PetCatalogPageState extends State<PetCatalogPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  var _sort = PetSort.handbook;
  var _selectedTypeIds = <String>{};
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

  Future<void> _showTypeFilters() async {
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
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.tr('Filter by type'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(context.tr('A creature may match any selected type.')),
                const SizedBox(height: 16),
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
                      onPressed: () => Navigator.pop(context, <String>{}),
                      child: Text(context.tr('Clear')),
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
    if (result == null || !mounted) {
      return;
    }
    setState(() => _selectedTypeIds = result);
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
    return SafeArea(
      top: false,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Column(
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
                        onPressed: _showSortOptions,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CompactFilterButton(
                        key: const ValueKey('pet-types'),
                        icon: Icons.filter_alt_outlined,
                        label: _selectedTypeIds.isEmpty
                            ? context.tr('Types')
                            : '${context.tr('Types')} (${_selectedTypeIds.length})',
                        onPressed: _showTypeFilters,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
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
                          filled: false,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
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
            ),
          ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

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
                  _load();
                },
                child: Text(context.tr('Clear search')),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
        itemCount: _results.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == _results.length) {
            return Center(
              child: OutlinedButton.icon(
                onPressed: _loadingMore ? null : () => _load(append: true),
                icon: _loadingMore
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more_rounded),
                label: Text(
                  context.tr(_loadingMore ? 'Loading...' : 'Load more'),
                ),
              ),
            );
          }
          final pet = _results[index];
          final object = ObjectRef(
            datasetId: widget.datasetId,
            objectType: UserObjectType.pet,
            objectId: pet.petId,
            nameSnapshot: pet.name,
          );
          return _PetResultCard(
            key: ValueKey('pet-result-${pet.petId}'),
            pet: pet,
            onTap: () => _open(pet),
            favorite: widget.favoriteKeys.contains(object.key),
            onFavoriteChanged: (enabled) =>
                widget.userRepository.setFavorite(object, enabled),
          );
        },
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

class _PetResultCard extends StatelessWidget {
  const _PetResultCard({
    required this.pet,
    required this.onTap,
    required this.favorite,
    required this.onFavoriteChanged,
    super.key,
  });

  final PetSummary pet;
  final VoidCallback onTap;
  final bool favorite;
  final Future<void> Function(bool enabled) onFavoriteChanged;

  @override
  Widget build(BuildContext context) {
    final form = !pet.isDefaultForm && pet.form?.trim().isNotEmpty == true
        ? '\uff08${pet.form!.trim()}\uff09'
        : '';
    final title = '${pet.name}$form';
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 112,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CatalogAssetImage(
                      assetPath: petIllustrationAsset(pet.illustrationKey),
                      semanticLabel: pet.name,
                      width: 112,
                      height: 112,
                      fit: BoxFit.contain,
                      fallbackIcon: Icons.pets_outlined,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pet.dexNo,
                      key: ValueKey('pet-dex-${pet.petId}'),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            pet.types.join(' \u00b7 '),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        FavoriteIconButton(
                          favorite: favorite,
                          objectLabel: pet.petId,
                          onChanged: onFavoriteChanged,
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
    );
  }
}

class _CompactFilterButton extends StatelessWidget {
  const _CompactFilterButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.semanticValue,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? semanticValue;
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
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 20),
                const SizedBox(width: 4),
                Text(label, maxLines: 1),
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
