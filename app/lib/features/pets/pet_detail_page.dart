import 'package:flutter/material.dart';

import '../../domain/catalog_models.dart';
import '../../domain/catalog_repository.dart';
import '../../domain/type_relations.dart';
import '../../domain/user_models.dart';
import '../../domain/user_repository.dart';
import '../../data/catalog/asset_type_relation_repository.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/catalog_asset_image.dart';
import '../personal/personal_controls.dart';
import '../skills/skill_detail_page.dart';

class PetDetailPage extends StatefulWidget {
  const PetDetailPage({
    required this.repository,
    required this.userRepository,
    required this.datasetId,
    required this.initialPetId,
    this.typeRelationRepository = const AssetTypeRelationRepository(),
    super.key,
  });

  final CatalogRepository repository;
  final UserRepository userRepository;
  final String datasetId;
  final String initialPetId;
  final TypeRelationRepository typeRelationRepository;

  @override
  State<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {
  late String _petId;
  late Future<_PetPageData> _data;
  final ScrollController _scrollController = ScrollController();
  final Map<_PetSection, GlobalKey> _sectionKeys = <_PetSection, GlobalKey>{
    for (final section in _PetSection.values)
      section: GlobalKey(debugLabel: 'pet-section-${section.id}'),
  };
  _PetSection _activeSection = _PetSection.basicInformation;
  _PetSkillCategory _skillCategory = _PetSkillCategory.native;
  Set<String> _skillTypes = <String>{};
  Set<String> _skillElements = <String>{};

  @override
  void initState() {
    super.initState();
    _petId = widget.initialPetId;
    _data = _load(_petId);
    _scrollController.addListener(_updateActiveSection);
  }

  Future<_PetPageData> _load(String petId) async {
    final detail = await widget.repository.getPetDetail(petId);
    final values = await Future.wait<Object>(<Future<Object>>[
      widget.repository.getSkillsForPet(petId),
      widget.repository.getEvolutionGraph(petId),
      widget.typeRelationRepository.forCreatureTypes(detail.summary.types),
    ]);
    return _PetPageData(
      detail: detail,
      skills: values[0] as PetSkillBundle,
      evolution: values[1] as EvolutionGraph,
      typeRelationships: values[2] as PetTypeRelationships,
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateActiveSection)
      ..dispose();
    super.dispose();
  }

  void _retry() {
    setState(() => _data = _load(_petId));
  }

  void _openSkill(String skillId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SkillDetailPage(
          repository: widget.repository,
          userRepository: widget.userRepository,
          datasetId: widget.datasetId,
          skillId: skillId,
        ),
      ),
    );
  }

  void _openPet(String petId) {
    if (petId == _petId) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PetDetailPage(
          repository: widget.repository,
          userRepository: widget.userRepository,
          datasetId: widget.datasetId,
          initialPetId: petId,
          typeRelationRepository: widget.typeRelationRepository,
        ),
      ),
    );
  }

  void _jumpToSection(_PetSection section) {
    final target = _sectionKeys[section]?.currentContext;
    if (target == null) {
      return;
    }
    setState(() => _activeSection = section);
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.06,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );
  }

  void _updateActiveSection() {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 4) {
      _setActiveSection(_PetSection.source);
      return;
    }

    final anchor = MediaQuery.sizeOf(context).height * 0.28;
    var active = _PetSection.values.first;
    for (final section in _PetSection.values) {
      final sectionContext = _sectionKeys[section]?.currentContext;
      final renderObject = sectionContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) {
        continue;
      }
      final top = renderObject.localToGlobal(Offset.zero).dy;
      if (top <= anchor) {
        active = section;
      } else {
        break;
      }
    }
    _setActiveSection(active);
  }

  void _setActiveSection(_PetSection section) {
    if (section == _activeSection || !mounted) {
      return;
    }
    setState(() => _activeSection = section);
  }

  String _sectionLabel(BuildContext context, _PetSection section) {
    if (section == _PetSection.skills) {
      return context.tr(_skillCategory.label);
    }
    return context.tr(section.label);
  }

  Future<void> _showSkillFilters(PetSkillBundle bundle) async {
    final elements =
        bundle.learnableSkills
            .map((item) => item.skill.element)
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
    final selection = await showModalBottomSheet<_SkillFilterSelection>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        var skillTypes = Set<String>.from(_skillTypes);
        var skillElements = Set<String>.from(_skillElements);
        return StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: SingleChildScrollView(
              key: const ValueKey('pet-skill-filter-sheet'),
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
                    context.tr('Filter skills'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    context.tr('Skill type'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _skillTypeOrder
                        .map(
                          (skillType) => FilterChip(
                            key: ValueKey('skill-type-filter-$skillType'),
                            avatar: CatalogAssetImage(
                              assetPath: skillCategoryIconAsset(skillType),
                              semanticLabel: skillType,
                              width: 22,
                              height: 22,
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
                  Text(
                    context.tr('Skill element'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: elements
                        .map(
                          (element) => FilterChip(
                            key: ValueKey('skill-element-filter-$element'),
                            avatar: CatalogAssetImage(
                              assetPath: typeIconAsset(element),
                              semanticLabel: element,
                              width: 22,
                              height: 22,
                              fallbackIcon: Icons.circle_outlined,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            label: Text(element),
                            selected: skillElements.contains(element),
                            onSelected: (selected) {
                              setSheetState(() {
                                if (selected) {
                                  skillElements.add(element);
                                } else {
                                  skillElements.remove(element);
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
                            skillElements.clear();
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
                          _SkillFilterSelection(
                            skillTypes: skillTypes,
                            skillElements: skillElements,
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
      _skillElements = selection.skillElements;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Creature details'))),
      body: FutureBuilder<_PetPageData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _DetailFailure(onRetry: _retry);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.requireData;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _updateActiveSection(),
          );
          return Stack(
            children: <Widget>[
              SelectionArea(
                child: SingleChildScrollView(
                  key: ValueKey('pet-detail-${data.detail.summary.petId}'),
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _Header(
                        detail: data.detail,
                        userRepository: widget.userRepository,
                        datasetId: widget.datasetId,
                      ),
                      const SizedBox(height: 24),
                      _Section(
                        key: _sectionKeys[_PetSection.basicInformation],
                        title: context.tr('Basic information'),
                        child: _BasicInformation(detail: data.detail),
                      ),
                      const SizedBox(height: 18),
                      _Section(
                        key: _sectionKeys[_PetSection.feature],
                        title: context.tr('Feature'),
                        child: data.skills.featureSkill == null
                            ? Text(context.tr('Not provided'))
                            : _FeatureCard(
                                skill: data.skills.featureSkill!,
                                onOpenSkill: _openSkill,
                              ),
                      ),
                      const SizedBox(height: 18),
                      _Section(
                        key: _sectionKeys[_PetSection.baseStats],
                        title: context.tr('Base stats'),
                        child: _Stats(detail: data.detail),
                      ),
                      const SizedBox(height: 18),
                      _Section(
                        key: _sectionKeys[_PetSection.skills],
                        title: context.tr('Skills'),
                        child: _PetSkills(
                          bundle: data.skills,
                          selectedCategory: _skillCategory,
                          selectedSkillTypes: _skillTypes,
                          selectedElements: _skillElements,
                          onCategorySelected: (category) {
                            setState(() => _skillCategory = category);
                          },
                          onShowFilters: () => _showSkillFilters(data.skills),
                          onOpenSkill: _openSkill,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _Section(
                        key: _sectionKeys[_PetSection.evolution],
                        title: context.tr('Evolution'),
                        child: _EvolutionList(
                          graph: data.evolution,
                          currentPetId: data.detail.summary.petId,
                          onOpenPet: _openPet,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _Section(
                        key: _sectionKeys[_PetSection.typeRelationships],
                        title: context.tr('Type relationships'),
                        trailing: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: data.detail.summary.types
                              .map(
                                (type) => Chip(
                                  visualDensity: VisualDensity.compact,
                                  label: TypeIconLabel(typeName: type),
                                ),
                              )
                              .toList(),
                        ),
                        child: _TypeRelationships(
                          relationships: data.typeRelationships,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _Section(
                        key: _sectionKeys[_PetSection.library],
                        title: context.tr('My library'),
                        child: _CreaturePersonalData(
                          userRepository: widget.userRepository,
                          datasetId: widget.datasetId,
                          detail: data.detail,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _Section(
                        key: _sectionKeys[_PetSection.source],
                        title: context.tr('Source'),
                        child: _SourceList(
                          sources: data.detail.sourceReferences,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 3,
                bottom: 12,
                child: Center(
                  child: _SectionNavigator(
                    activeSection: _activeSection,
                    labels: <_PetSection, String>{
                      for (final section in _PetSection.values)
                        section: _sectionLabel(context, section),
                    },
                    onSelected: _jumpToSection,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

enum _PetSection {
  basicInformation('basic-information', 'Basic information'),
  feature('feature', 'Feature'),
  baseStats('base-stats', 'Base stats'),
  skills('skills', 'Skills'),
  evolution('evolution', 'Evolution'),
  typeRelationships('type-relationships', 'Type relationships'),
  library('library', 'My library'),
  source('source', 'Source');

  const _PetSection(this.id, this.label);

  final String id;
  final String label;
}

enum _PetSkillCategory {
  native('native', 'Pet skills'),
  blood('blood', 'Bloodline effects'),
  stone('stone', 'Learnable skills');

  const _PetSkillCategory(this.sourceKind, this.label);

  final String sourceKind;
  final String label;
}

const _skillTypeOrder = <String>[
  '\u7269\u653b',
  '\u9b54\u653b',
  '\u9632\u5fa1',
  '\u72b6\u6001',
];

final class _SkillFilterSelection {
  const _SkillFilterSelection({
    required this.skillTypes,
    required this.skillElements,
  });

  final Set<String> skillTypes;
  final Set<String> skillElements;
}

class _SectionNavigator extends StatelessWidget {
  const _SectionNavigator({
    required this.activeSection,
    required this.labels,
    required this.onSelected,
  });

  final _PetSection activeSection;
  final Map<_PetSection, String> labels;
  final ValueChanged<_PetSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _PetSection.values
          .map(
            (section) => Tooltip(
              key: ValueKey('section-tooltip-${section.id}'),
              message: labels[section]!,
              triggerMode: TooltipTriggerMode.longPress,
              preferBelow: false,
              decoration: ShapeDecoration(
                color: colors.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colors.outline),
                ),
              ),
              textStyle: TextStyle(color: colors.onSurface),
              child: Semantics(
                selected: section == activeSection,
                button: true,
                label: labels[section],
                child: InkResponse(
                  key: ValueKey('section-dot-${section.id}'),
                  radius: 18,
                  onTap: () => onSelected(section),
                  child: SizedBox(
                    width: 32,
                    height: 28,
                    child: Center(
                      child: AnimatedContainer(
                        key: ValueKey('section-dot-mark-${section.id}'),
                        duration: const Duration(milliseconds: 160),
                        width: section == activeSection ? 12 : 7,
                        height: section == activeSection ? 12 : 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: section == activeSection
                              ? colors.primary
                              : colors.outlineVariant,
                          border: Border.all(
                            color: section == activeSection
                                ? colors.onPrimaryContainer
                                : colors.outline,
                            width: section == activeSection ? 1.5 : 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.skill, required this.onOpenSkill});

  final SkillSummary skill;
  final ValueChanged<String> onOpenSkill;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onOpenSkill(skill.skillId),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CatalogAssetImage(
              assetPath: skillIconAsset(skill),
              semanticLabel: skill.name,
              width: 64,
              height: 64,
              fallbackIcon: Icons.auto_awesome_rounded,
              borderRadius: BorderRadius.circular(32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    skill.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(skill.description ?? context.tr('Details not provided')),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _PetSkills extends StatelessWidget {
  const _PetSkills({
    required this.bundle,
    required this.selectedCategory,
    required this.selectedSkillTypes,
    required this.selectedElements,
    required this.onCategorySelected,
    required this.onShowFilters,
    required this.onOpenSkill,
  });

  final PetSkillBundle bundle;
  final _PetSkillCategory selectedCategory;
  final Set<String> selectedSkillTypes;
  final Set<String> selectedElements;
  final ValueChanged<_PetSkillCategory> onCategorySelected;
  final VoidCallback onShowFilters;
  final ValueChanged<String> onOpenSkill;

  @override
  Widget build(BuildContext context) {
    final skills = bundle.learnableSkills
        .where((item) {
          final sourceMatches = switch (selectedCategory) {
            _PetSkillCategory.native => item.sourceKind == 'native',
            _PetSkillCategory.blood => item.sourceKind == 'blood',
            _PetSkillCategory.stone =>
              item.sourceKind == 'stone' || item.sourceKind == 'legendary',
          };
          final skillType = _skillType(item.skill);
          return sourceMatches &&
              (selectedSkillTypes.isEmpty ||
                  selectedSkillTypes.contains(skillType)) &&
              (selectedElements.isEmpty ||
                  selectedElements.contains(item.skill.element));
        })
        .toList(growable: false);
    final filterCount = selectedSkillTypes.length + selectedElements.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            for (final category in _PetSkillCategory.values) ...<Widget>[
              Expanded(
                child: category == selectedCategory
                    ? FilledButton.tonal(
                        key: ValueKey(
                          'pet-skill-category-${category.sourceKind}',
                        ),
                        style: _skillCategoryButtonStyle(),
                        onPressed: () => onCategorySelected(category),
                        child: _SkillCategoryButtonContent(category: category),
                      )
                    : OutlinedButton(
                        key: ValueKey(
                          'pet-skill-category-${category.sourceKind}',
                        ),
                        style: _skillCategoryButtonStyle(),
                        onPressed: () => onCategorySelected(category),
                        child: _SkillCategoryButtonContent(category: category),
                      ),
              ),
              if (category != _PetSkillCategory.values.last)
                const SizedBox(width: 6),
            ],
            const SizedBox(width: 6),
            Badge.count(
              count: filterCount,
              isLabelVisible: filterCount > 0,
              child: IconButton.outlined(
                key: const ValueKey('pet-skill-filter'),
                tooltip: context.tr('Filter skills'),
                onPressed: onShowFilters,
                icon: const Icon(Icons.filter_alt_outlined),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (skills.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              selectedSkillTypes.isNotEmpty || selectedElements.isNotEmpty
                  ? context.tr('No skills match these filters.')
                  : context.tr('No learning source is provided.'),
            ),
          )
        else
          ...skills.map(
            (skill) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PetSkillCard(
                key: ValueKey('pet-skill-${skill.skill.skillId}'),
                learnableSkill: skill,
                onTap: () => onOpenSkill(skill.skill.skillId),
              ),
            ),
          ),
      ],
    );
  }
}

class _PetSkillCard extends StatelessWidget {
  const _PetSkillCard({
    required this.learnableSkill,
    required this.onTap,
    super.key,
  });

  final LearnableSkill learnableSkill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final skill = learnableSkill.skill;
    final skillType = _skillType(skill);
    final energy = _skillNumber(skill.energyValue, skill.energyText);
    final power = _skillNumber(skill.powerValue, skill.powerText);
    final additionalSource = _additionalSkillSource(context, learnableSkill);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              CatalogAssetImage(
                assetPath: skillIconAsset(skill),
                semanticLabel: skill.name,
                width: 64,
                height: 64,
                fallbackIcon: Icons.bolt_rounded,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      key: ValueKey('pet-skill-heading-${skill.skillId}'),
                      spacing: 8,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text(
                          skill.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (skill.element != null)
                          Tooltip(
                            message: skill.element!,
                            child: CatalogAssetImage(
                              key: ValueKey(
                                'pet-skill-element-${skill.skillId}',
                              ),
                              assetPath: typeIconAsset(skill.element!),
                              semanticLabel: skill.element!,
                              width: 24,
                              height: 24,
                              fallbackIcon: Icons.circle_outlined,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        if (learnableSkill.learnLevel != null)
                          Text(
                            '${context.tr('Unlock')}：lv${learnableSkill.learnLevel}',
                            key: ValueKey('pet-skill-unlock-${skill.skillId}'),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _SkillMetric(
                            label: context.tr('Energy'),
                            value: energy,
                            valueKey: ValueKey(
                              'pet-skill-energy-${skill.skillId}',
                            ),
                          ),
                        ),
                        Expanded(
                          child: _SkillMetric(
                            label: context.tr('Category'),
                            assetPath: skillCategoryIconAsset(skillType),
                            semanticValue: skillType,
                            iconSize: 18,
                          ),
                        ),
                        Expanded(
                          child: _SkillMetric(
                            label: context.tr('Power'),
                            value: power,
                            valueKey: ValueKey(
                              'pet-skill-power-${skill.skillId}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (skill.description != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(skill.description!),
                    ],
                    if (additionalSource != null) ...<Widget>[
                      const SizedBox(height: 5),
                      Text(
                        additionalSource,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillMetric extends StatelessWidget {
  const _SkillMetric({
    required this.label,
    this.value,
    this.valueKey,
    this.assetPath,
    this.semanticValue,
    this.iconSize = 24,
  });

  final String label;
  final String? value;
  final Key? valueKey;
  final String? assetPath;
  final String? semanticValue;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final displayedValue = value ?? semanticValue ?? context.tr('Unknown');
    return Semantics(
      label: label,
      value: displayedValue,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '$label：',
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 3),
          if (assetPath != null)
            CatalogAssetImage(
              assetPath: assetPath,
              semanticLabel: displayedValue,
              width: iconSize,
              height: iconSize,
              fallbackIcon: Icons.circle_outlined,
            )
          else
            Text(
              displayedValue,
              key: valueKey,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }
}

class _SkillCategoryButtonContent extends StatelessWidget {
  const _SkillCategoryButtonContent({required this.category});

  final _PetSkillCategory category;

  @override
  Widget build(BuildContext context) {
    final label = context.tr(category.label);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        CatalogAssetImage(
          assetPath: skillSourceIconAsset(category.sourceKind),
          semanticLabel: label,
          width: 20,
          height: 20,
          fallbackIcon: Icons.bolt_rounded,
          borderRadius: BorderRadius.circular(10),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

ButtonStyle _skillCategoryButtonStyle() {
  return const ButtonStyle(
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 4, vertical: 10),
    ),
    minimumSize: WidgetStatePropertyAll(Size(0, 48)),
  );
}

String? _skillType(SkillSummary skill) {
  if (_skillTypeOrder.contains(skill.damageClass)) {
    return skill.damageClass;
  }
  if (_skillTypeOrder.contains(skill.category)) {
    return skill.category;
  }
  return null;
}

String _skillNumber(num? value, String? text) {
  if (value == null) {
    return text ?? '—';
  }
  return value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
}

String? _additionalSkillSource(BuildContext context, LearnableSkill skill) {
  final details = <String>[
    if (skill.bloodRaw != null) '${context.tr('Bloodline')}：${skill.bloodRaw}',
    if (skill.requirementText != null) skill.requirementText!,
  ];
  return details.isEmpty ? null : details.join(' · ');
}

class _CreaturePersonalData extends StatelessWidget {
  const _CreaturePersonalData({
    required this.userRepository,
    required this.datasetId,
    required this.detail,
  });

  final UserRepository userRepository;
  final String datasetId;
  final PetDetail detail;

  @override
  Widget build(BuildContext context) {
    final summary = detail.summary;
    final object = ObjectRef(
      datasetId: datasetId,
      objectType: UserObjectType.pet,
      objectId: summary.petId,
      nameSnapshot: summary.name,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StreamBuilder<List<CollectionMark>>(
          initialData: const <CollectionMark>[],
          stream: userRepository.watchCollectionMarks(datasetId),
          builder: (context, snapshot) {
            final collected =
                snapshot.data?.any(
                  (mark) => mark.handbookId == summary.handbookId,
                ) ??
                false;
            return CollectedControl(
              collected: collected,
              onChanged: (enabled) => userRepository.setCollected(
                datasetId: datasetId,
                handbookId: summary.handbookId,
                nameSnapshot: summary.name,
                collected: enabled,
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          context.tr(
            'The collection mark applies to this handbook entry, not to every form.',
          ),
        ),
        const SizedBox(height: 18),
        PersonalNotesSection(repository: userRepository, object: object),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.detail,
    required this.userRepository,
    required this.datasetId,
  });

  final PetDetail detail;
  final UserRepository userRepository;
  final String datasetId;

  @override
  Widget build(BuildContext context) {
    final summary = detail.summary;
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: CatalogAssetImage(
                assetPath: petIllustrationAsset(detail.illustrationKey),
                semanticLabel: summary.name,
                width: 280,
                height: 260,
                fallbackIcon: Icons.pets_outlined,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '#${summary.dexNo}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Wrap(
                    key: const ValueKey('pet-detail-name-and-types'),
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        summary.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      for (final type in summary.types)
                        Tooltip(
                          message: type,
                          child: CatalogAssetImage(
                            key: ValueKey('pet-detail-type-$type'),
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
                _CreatureFavoriteButton(
                  userRepository: userRepository,
                  datasetId: datasetId,
                  summary: summary,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(_stageLabel(context, detail)),
            if (detail.description != null) ...<Widget>[
              const SizedBox(height: 14),
              Text(detail.description!),
            ],
          ],
        ),
      ),
    );
  }
}

class _CreatureFavoriteButton extends StatelessWidget {
  const _CreatureFavoriteButton({
    required this.userRepository,
    required this.datasetId,
    required this.summary,
  });

  final UserRepository userRepository;
  final String datasetId;
  final PetSummary summary;

  @override
  Widget build(BuildContext context) {
    final object = ObjectRef(
      datasetId: datasetId,
      objectType: UserObjectType.pet,
      objectId: summary.petId,
      nameSnapshot: summary.name,
    );
    return StreamBuilder<List<FavoriteItem>>(
      initialData: const <FavoriteItem>[],
      stream: userRepository.watchFavorites(),
      builder: (context, snapshot) {
        final favorite =
            snapshot.data?.any(
              (item) =>
                  item.object.datasetId == datasetId &&
                  item.object.key == object.key,
            ) ??
            false;
        return FavoriteIconButton(
          favorite: favorite,
          objectLabel: summary.petId,
          onChanged: (enabled) => userRepository.setFavorite(object, enabled),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            ?trailing,
          ],
        ),
        const Divider(height: 16, thickness: 2),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      ],
    );
  }
}

class _BasicInformation extends StatelessWidget {
  const _BasicInformation({required this.detail});

  final PetDetail detail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final width = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: 12,
          children: <Widget>[
            _Fact(width: width, label: 'Class', value: detail.className),
            _Fact(
              width: width,
              label: 'Stage',
              value: detail.stage?.toString(),
            ),
            _Fact(
              width: width,
              label: 'Double ride',
              value: _yesNo(context, detail.canDoubleRide),
            ),
            _Fact(
              width: width,
              label: 'Shiny form',
              value: _yesNo(context, detail.hasShiny),
            ),
            _Fact(
              width: width,
              label: 'Lord evolution',
              value: _yesNo(context, detail.isLordEvolution == true),
            ),
          ],
        );
      },
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.width, required this.label, this.value});

  final double width;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('basic-fact-$label'),
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.tr(label),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 2),
          Text(value ?? context.tr('Not provided')),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.detail});

  final PetDetail detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Row(
            children: <Widget>[
              const Icon(Icons.calculate_outlined),
              const SizedBox(width: 10),
              Expanded(child: Text(context.tr('Total base stats'))),
              Text(
                detail.totalBaseStats?.toString() ?? context.tr('Unknown'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...detail.stats.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _StatBar(label: entry.key, value: entry.value),
          ),
        ),
        const SizedBox(height: 2),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _StatFactPill(
                  width: width,
                  label: 'Height',
                  value: detail.heightText,
                  assetPath: 'assets/wiki/v1/ui/info/height.png',
                ),
                _StatFactPill(
                  width: width,
                  label: 'Weight',
                  value: detail.weightText,
                  assetPath: 'assets/wiki/v1/ui/info/weight.png',
                ),
                _StatFactPill(
                  width: width,
                  label: 'Review gold',
                  value: detail.reviewGold?.toString(),
                  assetPath: 'assets/wiki/v1/ui/info/review-gold.png',
                ),
                _StatFactPill(
                  width: width,
                  label: 'Starlight',
                  value: detail.starlight?.toString(),
                  assetPath: 'assets/wiki/v1/ui/info/starlight.png',
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({required this.label, required this.value});

  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) {
    final progress = value == null ? 0.0 : (value! / 300).clamp(0.0, 1.0);
    return Row(
      children: <Widget>[
        CatalogAssetImage(
          assetPath: _statIconAsset(label),
          semanticLabel: context.tr(label),
          width: 24,
          height: 24,
          fallbackIcon: Icons.circle_outlined,
        ),
        const SizedBox(width: 7),
        SizedBox(
          width: 76,
          child: Text(
            context.tr(label),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            label: context.tr(label),
            value: value?.toString() ?? context.tr('Unknown'),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                minHeight: 12,
                value: progress,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 36,
          child: Text(
            value?.toString() ?? context.tr('Unknown'),
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _StatFactPill extends StatelessWidget {
  const _StatFactPill({
    required this.width,
    required this.label,
    required this.value,
    required this.assetPath,
  });

  final double width;
  final String label;
  final String? value;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: <Widget>[
          CatalogAssetImage(
            assetPath: assetPath,
            semanticLabel: context.tr(label),
            width: 24,
            height: 24,
            fallbackIcon: Icons.info_outline_rounded,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${context.tr(label)}：\n${value ?? context.tr('Unknown')}',
              maxLines: 2,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

String? _statIconAsset(String key) {
  const files = <String, String>{
    'HP': 'health',
    'Attack': 'physical-attack',
    'Defense': 'physical-defense',
    'Magic attack': 'magic-attack',
    'Magic defense': 'magic-defense',
    'Speed': 'speed',
  };
  final file = files[key];
  return file == null ? null : 'assets/wiki/v1/ui/stats/$file.png';
}

class _TypeRelationships extends StatelessWidget {
  const _TypeRelationships({required this.relationships});

  final PetTypeRelationships relationships;

  @override
  Widget build(BuildContext context) {
    final increased = relationships.incoming
        .where((item) => item.multiplier > 1)
        .toList(growable: false);
    final reduced = relationships.incoming
        .where((item) => item.multiplier < 1)
        .toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) {
        final panels = <Widget>[
          _IncomingRelationPanel(
            label: context.tr('Incoming damage increased'),
            values: increased,
            increased: true,
          ),
          _IncomingRelationPanel(
            label: context.tr('Incoming damage reduced'),
            values: reduced,
            increased: false,
          ),
        ];
        if (constraints.maxWidth < 280) {
          return Column(
            children: <Widget>[
              panels.first,
              const SizedBox(height: 12),
              panels.last,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: panels.first),
            const SizedBox(width: 12),
            Expanded(child: panels.last),
          ],
        );
      },
    );
  }
}

class _IncomingRelationPanel extends StatelessWidget {
  const _IncomingRelationPanel({
    required this.label,
    required this.values,
    required this.increased,
  });

  final String label;
  final List<IncomingTypeDamage> values;
  final bool increased;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = increased ? colors.error : Colors.green.shade700;
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        border: Border.all(color: accent.withValues(alpha: 0.72)),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            color: accent.withValues(alpha: 0.2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: values.isEmpty
                ? Text(context.tr('Normal damage'), textAlign: TextAlign.center)
                : Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 7,
                    runSpacing: 7,
                    children: values
                        .map(
                          (item) =>
                              _RelationPill(relation: item, accent: accent),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RelationPill extends StatelessWidget {
  const _RelationPill({required this.relation, required this.accent});

  final IncomingTypeDamage relation;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final typeName = '${relation.typeName}\u7cfb';
    return Semantics(
      label: '$typeName ×${_multiplier(relation.multiplier)}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 4, 9, 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CatalogAssetImage(
              assetPath: typeIconAsset(typeName),
              semanticLabel: typeName,
              width: 26,
              height: 26,
              fallbackIcon: Icons.circle_outlined,
              borderRadius: BorderRadius.circular(13),
            ),
            const SizedBox(width: 7),
            Text(
              _multiplier(relation.multiplier),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: accent, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

String _multiplier(double value) {
  if (value == 0.25) {
    return '¼';
  }
  if (value == 0.5) {
    return '½';
  }
  return value.toInt().toString();
}

class _EvolutionList extends StatelessWidget {
  const _EvolutionList({
    required this.graph,
    required this.currentPetId,
    required this.onOpenPet,
  });

  final EvolutionGraph graph;
  final String currentPetId;
  final ValueChanged<String> onOpenPet;

  @override
  Widget build(BuildContext context) {
    if (graph.nodes.isEmpty) {
      return Text(context.tr('No evolution group is provided.'));
    }
    final nodes = <String, PetSummary>{
      for (final node in graph.nodes) node.petId: node,
    };
    if (graph.edges.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(context.tr('Related group members; direction is not provided:')),
          const SizedBox(height: 8),
          ...graph.nodes.map(
            (node) => ListTile(
              key: ValueKey('evolution-member-${node.petId}'),
              contentPadding: EdgeInsets.zero,
              leading: CatalogAssetImage(
                assetPath: petIllustrationAsset(node.illustrationKey),
                semanticLabel: node.name,
                width: 48,
                height: 48,
                fallbackIcon: Icons.pets_outlined,
                borderRadius: BorderRadius.circular(10),
              ),
              title: Text(node.name),
              subtitle: Text('#${node.dexNo}'),
              trailing: node.petId == currentPetId
                  ? null
                  : const Icon(Icons.chevron_right_rounded),
              onTap: node.petId == currentPetId
                  ? null
                  : () => onOpenPet(node.petId),
            ),
          ),
        ],
      );
    }
    return Column(
      children: graph.edges.map((edge) {
        final destinationId = edge.toPetId == currentPetId
            ? edge.fromPetId
            : edge.toPetId;
        final destination = nodes[destinationId];
        return ListTile(
          key: ValueKey('evolution-edge-${edge.fromPetId}-${edge.toPetId}'),
          contentPadding: EdgeInsets.zero,
          leading: CatalogAssetImage(
            assetPath: petIllustrationAsset(destination?.illustrationKey),
            semanticLabel: destination?.name ?? destinationId,
            width: 48,
            height: 48,
            fallbackIcon: Icons.pets_outlined,
            borderRadius: BorderRadius.circular(10),
          ),
          title: Text(
            '${nodes[edge.fromPetId]?.name ?? edge.fromPetId} → '
            '${nodes[edge.toPetId]?.name ?? edge.toPetId}',
          ),
          subtitle: Text(_evolutionCondition(context, edge)),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => onOpenPet(destinationId),
        );
      }).toList(),
    );
  }
}

class _SourceList extends StatelessWidget {
  const _SourceList({required this.sources});

  final List<SourceReference> sources;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) {
      return Text(context.tr('Source reference not provided.'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sources
          .map(
            (source) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.strings.revision(
                      source.sourceName,
                      source.revisionId,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(source.licenseId),
                  SelectableText(source.sourceUrl),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DetailFailure extends StatelessWidget {
  const _DetailFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(context.tr('Creature details could not be loaded.')),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: Text(context.tr('Try again')),
          ),
        ],
      ),
    );
  }
}

final class _PetPageData {
  const _PetPageData({
    required this.detail,
    required this.skills,
    required this.evolution,
    required this.typeRelationships,
  });

  final PetDetail detail;
  final PetSkillBundle skills;
  final EvolutionGraph evolution;
  final PetTypeRelationships typeRelationships;
}

String _yesNo(BuildContext context, bool? value) {
  if (value == null) {
    return context.tr('Not provided');
  }
  return context.tr(value ? 'Yes' : 'No');
}

String _stageLabel(BuildContext context, PetDetail detail) {
  if (detail.isLordEvolution == true || detail.stage == 4) {
    return context.tr('Lord form');
  }
  return context.tr(switch (detail.stage) {
    1 => 'First stage',
    2 => 'Second stage',
    3 => 'Third stage',
    _ => 'Stage not provided',
  });
}

String _evolutionCondition(BuildContext context, EvolutionEdge edge) {
  final details = <String>[
    context.tr(
      edge.methodCode == 'lord_branch' ? 'Lord branch' : 'Evolution chain',
    ),
  ];
  if (edge.levelRequirement != null) {
    details.add('${context.tr('Level')} ${edge.levelRequirement}');
  }
  if (edge.conditionText != null) {
    details.add(edge.conditionText!);
  }
  return details.join(' · ');
}
