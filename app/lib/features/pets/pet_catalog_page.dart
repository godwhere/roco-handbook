import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/catalog_models.dart';
import '../../domain/catalog_repository.dart';
import '../../domain/user_models.dart';
import '../../domain/user_repository.dart';
import '../personal/personal_controls.dart';
import 'pet_detail_page.dart';

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
  var _mode = PetListMode.handbooks;
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
      final results =
          query.keyword.trim().isNotEmpty || _mode == PetListMode.allForms
          ? await widget.repository.searchPets(query)
          : await widget.repository.searchHandbooks(query);
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

  void _setMode(PetListMode mode) {
    if (_mode == mode) {
      return;
    }
    setState(() => _mode = mode);
    _load();
  }

  void _setSort(PetSort? sort) {
    if (sort == null || _sort == sort) {
      return;
    }
    setState(() => _sort = sort);
    _load();
  }

  Future<void> _showTypeFilters() async {
    final List<CatalogType> types;
    try {
      types = await widget.repository.getTypes();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Creature types could not be loaded.')),
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
                  'Filter by type',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                const Text('A creature may match any selected type.'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: types
                      .map(
                        (type) => FilterChip(
                          label: Text(type.name),
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
                      child: const Text('Clear'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, selected),
                      child: const Text('Apply'),
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
                TextField(
                  key: const ValueKey('pet-search'),
                  controller: _searchController,
                  onChanged: _scheduleSearch,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: 'Search creatures',
                    hintText: 'Name, title, alias, or number',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              _load();
                            },
                            icon: const Icon(Icons.clear_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<PetListMode>(
                  segments: const <ButtonSegment<PetListMode>>[
                    ButtonSegment<PetListMode>(
                      value: PetListMode.handbooks,
                      icon: Icon(Icons.menu_book_outlined),
                      label: Text('Handbook'),
                    ),
                    ButtonSegment<PetListMode>(
                      value: PetListMode.allForms,
                      icon: Icon(Icons.layers_outlined),
                      label: Text('All forms'),
                    ),
                  ],
                  selected: <PetListMode>{_mode},
                  onSelectionChanged: (selection) => _setMode(selection.single),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<PetSort>(
                  initialValue: _sort,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Sort',
                    prefixIcon: Icon(Icons.sort_rounded),
                    isDense: true,
                  ),
                  selectedItemBuilder: (context) => PetSort.values
                      .map(
                        (sort) => Text(
                          _sortLabel(sort),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                      .toList(),
                  items: PetSort.values
                      .map(
                        (sort) => DropdownMenuItem<PetSort>(
                          value: sort,
                          child: Text(
                            _sortLabel(sort),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _setSort,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _showTypeFilters,
                    icon: const Icon(Icons.filter_alt_outlined),
                    label: Text(
                      _selectedTypeIds.isEmpty
                          ? 'Types'
                          : 'Types (${_selectedTypeIds.length})',
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    'Search results show concrete forms so a matching form opens directly.',
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
                'No creatures match this search.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _load();
                },
                child: const Text('Clear search'),
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
                label: Text(_loadingMore ? 'Loading...' : 'Load more'),
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

String _sortLabel(PetSort sort) {
  return switch (sort) {
    PetSort.handbook => 'Handbook number',
    PetSort.name => 'Name',
    PetSort.attack => 'Attack, high to low',
    PetSort.magicAttack => 'Magic attack, high to low',
    PetSort.speed => 'Speed, high to low',
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
    final form =
        pet.form ?? (pet.isDefaultForm ? 'Default form' : 'Form not provided');
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Semantics(
                label: 'Handbook number ${pet.dexNo}',
                child: CircleAvatar(child: Text(pet.dexNo)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pet.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(form),
                    if (pet.types.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: pet.types
                            .map(
                              (type) => Chip(
                                visualDensity: VisualDensity.compact,
                                label: Text(type),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
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
            const Text('The local Catalog query failed.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
