import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/catalog_models.dart';
import '../../domain/catalog_repository.dart';
import '../../domain/user_repository.dart';
import 'skill_detail_page.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/catalog_asset_image.dart';

class SkillCatalogPage extends StatefulWidget {
  const SkillCatalogPage({
    required this.repository,
    required this.userRepository,
    required this.datasetId,
    super.key,
  });

  final CatalogRepository repository;
  final UserRepository userRepository;
  final String datasetId;

  @override
  State<SkillCatalogPage> createState() => _SkillCatalogPageState();
}

class _SkillCatalogPageState extends State<SkillCatalogPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  Set<String> _skillTypes = <String>{};
  Set<String> _skillTags = <String>{};
  Set<String> _typeIds = <String>{};
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
          filter: SkillFilter.learnable,
          skillTypes: _skillTypes.toList(growable: false),
          tags: _skillTags.toList(growable: false),
          typeIds: _typeIds.toList(growable: false),
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

  void _resetCatalog() {
    _searchController.clear();
    setState(() {
      _skillTypes = <String>{};
      _skillTags = <String>{};
      _typeIds = <String>{};
    });
    _load();
  }

  Future<void> _showFilters() async {
    final types = await widget.repository.getTypes();
    if (!mounted) {
      return;
    }
    final selection = await showModalBottomSheet<_SkillCatalogFilterSelection>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        var skillTypes = Set<String>.from(_skillTypes);
        var skillTags = Set<String>.from(_skillTags);
        var typeIds = Set<String>.from(_typeIds);
        return StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: SingleChildScrollView(
              key: const ValueKey('skill-catalog-filter-sheet'),
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                20 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.tr('Skill filters'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 18),
                  _FilterHeading(label: context.tr('Skill type')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _skillTypeFilters
                        .map(
                          (skillType) => FilterChip(
                            key: ValueKey(
                              'skill-catalog-type-filter-$skillType',
                            ),
                            avatar: CatalogAssetImage(
                              assetPath: skillCategoryIconAsset(skillType),
                              semanticLabel: skillType,
                              width: 20,
                              height: 20,
                              fallbackIcon: Icons.category_outlined,
                            ),
                            label: Text(skillType),
                            selected: skillTypes.contains(skillType),
                            onSelected: (selected) {
                              setSheetState(() {
                                if (selected) {
                                  skillTypes.add(skillType);
                                } else {
                                  skillTypes.remove(skillType);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  _FilterHeading(label: context.tr('Skill tags')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _skillTagFilters
                        .map(
                          (tag) => FilterChip(
                            key: ValueKey('skill-catalog-tag-filter-$tag'),
                            label: Text(tag),
                            selected: skillTags.contains(tag),
                            onSelected: (selected) {
                              setSheetState(() {
                                if (selected) {
                                  skillTags.add(tag);
                                } else {
                                  skillTags.remove(tag);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  _FilterHeading(label: context.tr('Skill element')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: types
                        .map(
                          (type) => FilterChip(
                            key: ValueKey(
                              'skill-catalog-element-filter-${type.typeId}',
                            ),
                            avatar: CatalogAssetImage(
                              assetPath: typeIconAsset(type.name),
                              semanticLabel: type.name,
                              width: 22,
                              height: 22,
                              fallbackIcon: Icons.circle_outlined,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            label: Text(type.name),
                            selected: typeIds.contains(type.typeId),
                            onSelected: (selected) {
                              setSheetState(() {
                                if (selected) {
                                  typeIds.add(type.typeId);
                                } else {
                                  typeIds.remove(type.typeId);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: <Widget>[
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            skillTypes.clear();
                            skillTags.clear();
                            typeIds.clear();
                          });
                        },
                        child: Text(context.tr('Clear')),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(context.tr('Cancel')),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(
                          _SkillCatalogFilterSelection(
                            skillTypes: skillTypes,
                            skillTags: skillTags,
                            typeIds: typeIds,
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
    if (selection == null || !mounted) {
      return;
    }
    setState(() {
      _skillTypes = selection.skillTypes;
      _skillTags = selection.skillTags;
      _typeIds = selection.typeIds;
    });
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _SkillToolbarButton(
                    key: const ValueKey('skill-handbook'),
                    icon: Icons.menu_book_outlined,
                    label: context.tr('Skill handbook'),
                    selected: true,
                    onPressed: _resetCatalog,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SkillToolbarButton(
                    key: const ValueKey('skill-filters'),
                    icon: Icons.filter_alt_outlined,
                    label: _selectedFilterCount == 0
                        ? context.tr('Skill filters')
                        : '${context.tr('Skill filters')} ($_selectedFilterCount)',
                    onPressed: _showFilters,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    key: const ValueKey('skill-search'),
                    controller: _searchController,
                    onChanged: _scheduleSearch,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.none,
                    autocorrect: false,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: context.tr('Search skills'),
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
          ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  int get _selectedFilterCount =>
      _skillTypes.length + _skillTags.length + _typeIds.length;

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
          return _SkillResultCard(
            key: ValueKey('skill-result-${skill.skillId}'),
            skill: skill,
            onTap: () => _open(skill),
          );
        },
      ),
    );
  }
}

class _SkillResultCard extends StatelessWidget {
  const _SkillResultCard({required this.skill, required this.onTap, super.key});

  final SkillSummary skill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final skillType = _displaySkillType(skill);
    final energy = _numericText(skill.energyValue, skill.energyText);
    final power = _numericText(skill.powerValue, skill.powerText);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              CatalogAssetImage(
                assetPath: skillIconAsset(skill),
                semanticLabel: skill.name,
                width: 68,
                height: 68,
                fallbackIcon: Icons.bolt_rounded,
                borderRadius: BorderRadius.circular(14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            skill.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (skill.element != null) ...<Widget>[
                          const SizedBox(width: 8),
                          Tooltip(
                            message: skill.element!,
                            child: CatalogAssetImage(
                              key: ValueKey(
                                'skill-result-element-${skill.skillId}',
                              ),
                              assetPath: typeIconAsset(skill.element!),
                              semanticLabel: skill.element!,
                              width: 24,
                              height: 24,
                              fallbackIcon: Icons.circle_outlined,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        if (skillType != null)
                          _SkillCatalogValue(
                            label: skillType,
                            assetPath: skillCategoryIconAsset(skillType),
                          ),
                        Text('${context.tr('Energy')} $energy'),
                        Text('${context.tr('Power')} $power'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      skill.description ?? context.tr('Details not provided'),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillCatalogValue extends StatelessWidget {
  const _SkillCatalogValue({required this.label, required this.assetPath});

  final String label;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CatalogAssetImage(
          assetPath: assetPath,
          semanticLabel: label,
          width: 18,
          height: 18,
          fallbackIcon: Icons.category_outlined,
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}

class _SkillToolbarButton extends StatelessWidget {
  const _SkillToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final child = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 20),
          const SizedBox(width: 4),
          Text(label, maxLines: 1),
        ],
      ),
    );
    return SizedBox(
      height: 56,
      child: selected
          ? FilledButton.tonal(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              onPressed: onPressed,
              child: child,
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              onPressed: onPressed,
              child: child,
            ),
    );
  }
}

class _FilterHeading extends StatelessWidget {
  const _FilterHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.titleMedium
        ?.copyWith(fontWeight: FontWeight.w700),
  );
}

final class _SkillCatalogFilterSelection {
  const _SkillCatalogFilterSelection({
    required this.skillTypes,
    required this.skillTags,
    required this.typeIds,
  });

  final Set<String> skillTypes;
  final Set<String> skillTags;
  final Set<String> typeIds;
}

String? _displaySkillType(SkillSummary skill) {
  if (_skillTypeFilters.contains(skill.damageClass)) {
    return skill.damageClass;
  }
  if (_skillTypeFilters.contains(skill.category)) {
    return skill.category;
  }
  return null;
}

String _numericText(num? value, String? text) {
  if (value == null) {
    return text ?? '—';
  }
  return value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
}

const _skillTypeFilters = <String>[
  '\u7269\u653b',
  '\u9b54\u653b',
  '\u9632\u5fa1',
  '\u72b6\u6001',
];

const _skillTagFilters = <String>[
  '\u5f02\u5e38',
  '\u56de\u8840',
  '\u56de\u80fd',
  '\u5e94\u5bf9',
  '\u5370\u8bb0',
  '\u9a71\u6563',
  '\u5148\u624b',
  '\u79bb\u573a',
  '\u5929\u6c14',
  '\u9009\u62e9',
  '\u5de7\u53d8',
  '\u5f3a\u5316',
  '\u8fde\u51fb',
  '\u840c\u5316',
  '\u5f15\u7535',
  '\u8fc5\u6377',
  '\u4f20\u52a8',
  '\u8ff8\u53d1',
  '\u5949\u732e',
  '\u6253\u65ad',
];
