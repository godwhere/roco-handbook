import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/catalog_models.dart';
import '../../domain/catalog_repository.dart';
import '../../domain/user_models.dart';
import '../../domain/user_repository.dart';
import '../personal/personal_controls.dart';
import 'skill_detail_page.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/catalog_asset_image.dart';

class SkillCatalogPage extends StatefulWidget {
  const SkillCatalogPage({
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
  State<SkillCatalogPage> createState() => _SkillCatalogPageState();
}

class _SkillCatalogPageState extends State<SkillCatalogPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  var _filter = SkillFilter.all;
  var _results = const <SkillSummary>[];
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
    try {
      final results = await widget.repository.searchSkills(
        SkillQuery(
          keyword: _searchController.text,
          filter: _filter,
          limit: _pageSize,
          offset: append ? _results.length : 0,
        ),
      );
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _results = append ? <SkillSummary>[..._results, ...results] : results;
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

  void _setFilter(SkillFilter filter) {
    if (_filter == filter) {
      return;
    }
    setState(() => _filter = filter);
    _load();
  }

  void _open(SkillSummary skill) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SkillDetailPage(
          repository: widget.repository,
          userRepository: widget.userRepository,
          datasetId: widget.datasetId,
          skillId: skill.skillId,
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
                  key: const ValueKey('skill-search'),
                  controller: _searchController,
                  onChanged: _scheduleSearch,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: context.tr('Search skills'),
                    hintText: context.tr('Skill name'),
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
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<SkillFilter>(
                  segments: <ButtonSegment<SkillFilter>>[
                    ButtonSegment<SkillFilter>(
                      value: SkillFilter.all,
                      label: Text(context.tr('All')),
                    ),
                    ButtonSegment<SkillFilter>(
                      value: SkillFilter.features,
                      label: Text(context.tr('Features')),
                    ),
                    ButtonSegment<SkillFilter>(
                      value: SkillFilter.learnable,
                      label: Text(context.tr('Learnable')),
                    ),
                  ],
                  selected: <SkillFilter>{_filter},
                  onSelectionChanged: (selection) =>
                      _setFilter(selection.single),
                ),
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(context.tr('The local Catalog query failed.')),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _load,
              child: Text(context.tr('Try again')),
            ),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.search_off_rounded, size: 48),
            const SizedBox(height: 12),
            Text(
              context.tr('No skills match this search.'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
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
          final skill = _results[index];
          final object = ObjectRef(
            datasetId: widget.datasetId,
            objectType: UserObjectType.skill,
            objectId: skill.skillId,
            nameSnapshot: skill.name,
          );
          return Card(
            key: ValueKey('skill-result-${skill.skillId}'),
            child: ListTile(
              onTap: () => _open(skill),
              leading: CatalogAssetImage(
                assetPath: skillIconAsset(skill),
                semanticLabel: skill.name,
                width: 48,
                height: 48,
                fallbackIcon: skill.isFeature
                    ? Icons.auto_awesome_rounded
                    : Icons.bolt_rounded,
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(skill.name),
              subtitle: Text(_skillSummaryText(context, skill)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FavoriteIconButton(
                    favorite: widget.favoriteKeys.contains(object.key),
                    objectLabel: skill.skillId,
                    onChanged: (enabled) =>
                        widget.userRepository.setFavorite(object, enabled),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

String _skillSummaryText(BuildContext context, SkillSummary skill) {
  final values = <String>[];
  if (skill.isFeature) {
    values.add(context.tr('Feature'));
  }
  if (skill.element != null) {
    values.add(skill.element!);
  }
  if (skill.category != null) {
    values.add(skill.category!);
  }
  final power = skill.powerValue?.toString() ?? skill.powerText;
  if (power != null) {
    values.add(context.strings.power(power));
  }
  return values.isEmpty
      ? context.tr('Details not provided')
      : values.join(' · ');
}
