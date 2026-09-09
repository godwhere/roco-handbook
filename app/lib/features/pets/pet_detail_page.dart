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

  @override
  void initState() {
    super.initState();
    _petId = widget.initialPetId;
    _data = _load(_petId);
  }

  Future<_PetPageData> _load(String petId) async {
    final detail = await widget.repository.getPetDetail(petId);
    final values = await Future.wait<Object>(<Future<Object>>[
      widget.repository.getSkillsForPet(petId),
      widget.repository.getEvolutionGraph(petId),
      widget.typeRelationRepository.forCreatureTypes(detail.summary.types),
    ]);
    final forms = await widget.repository.getFormsForHandbook(
      detail.summary.handbookId,
    );
    return _PetPageData(
      detail: detail,
      forms: forms,
      skills: values[0] as PetSkillBundle,
      evolution: values[1] as EvolutionGraph,
      typeRelationships: values[2] as PetTypeRelationships,
    );
  }

  void _selectForm(String petId) {
    if (petId == _petId) {
      return;
    }
    setState(() {
      _petId = petId;
      _data = _load(petId);
    });
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
          return SelectionArea(
            child: ListView(
              key: ValueKey('pet-detail-${data.detail.summary.petId}'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: <Widget>[
                _Header(detail: data.detail),
                if (data.forms.length > 1) ...<Widget>[
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    key: ValueKey('form-selector-$_petId'),
                    initialValue: _petId,
                    decoration: InputDecoration(
                      labelText: context.tr('Displayed form'),
                      prefixIcon: const Icon(Icons.layers_outlined),
                    ),
                    items: data.forms
                        .map(
                          (form) => DropdownMenuItem<String>(
                            value: form.petId,
                            child: Text(
                              '${form.name} — ${form.form ?? context.tr('Default form')}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _selectForm(value);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 24),
                _Section(
                  title: context.tr('Basic information'),
                  child: _BasicInformation(detail: data.detail),
                ),
                const SizedBox(height: 18),
                _Section(
                  title: context.tr('Base stats'),
                  child: _Stats(stats: data.detail.stats),
                ),
                const SizedBox(height: 18),
                _Section(
                  title: context.tr('Type relationships'),
                  child: _TypeRelationships(
                    relationships: data.typeRelationships,
                  ),
                ),
                const SizedBox(height: 18),
                _Section(
                  title: context.tr('Feature'),
                  child: data.skills.featureSkill == null
                      ? Text(context.tr('Not provided'))
                      : ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CatalogAssetImage(
                            assetPath: skillIconAsset(
                              data.skills.featureSkill!,
                            ),
                            semanticLabel: data.skills.featureSkill!.name,
                            width: 44,
                            height: 44,
                            fallbackIcon: Icons.auto_awesome_rounded,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          title: Text(data.skills.featureSkill!.name),
                          subtitle: Text(context.tr('Feature relationship')),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () =>
                              _openSkill(data.skills.featureSkill!.skillId),
                        ),
                ),
                const SizedBox(height: 18),
                _Section(
                  title: context.tr('Learnable skills'),
                  child: data.skills.learnableSkills.isEmpty
                      ? Text(context.tr('No learning source is provided.'))
                      : Column(
                          children: data.skills.learnableSkills
                              .map(
                                (skill) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CatalogAssetImage(
                                    assetPath: skillIconAsset(skill.skill),
                                    semanticLabel: skill.skill.name,
                                    width: 40,
                                    height: 40,
                                    fallbackIcon: Icons.bolt_rounded,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  title: Text(skill.skill.name),
                                  subtitle: Text(
                                    _skillCondition(context, skill),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: () => _openSkill(skill.skill.skillId),
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 18),
                _Section(
                  title: context.tr('Evolution'),
                  child: _EvolutionList(graph: data.evolution),
                ),
                const SizedBox(height: 18),
                _Section(
                  title: context.tr('My library'),
                  child: _CreaturePersonalData(
                    userRepository: widget.userRepository,
                    datasetId: widget.datasetId,
                    detail: data.detail,
                  ),
                ),
                const SizedBox(height: 18),
                _Section(
                  title: context.tr('Source'),
                  child: _SourceList(sources: data.detail.sourceReferences),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
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
        StreamBuilder<List<FavoriteItem>>(
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
            return Row(
              children: <Widget>[
                FavoriteIconButton(
                  favorite: favorite,
                  objectLabel: summary.petId,
                  onChanged: (enabled) =>
                      userRepository.setFavorite(object, enabled),
                ),
                Text(
                  context.tr(
                    favorite ? 'Creature favorite' : 'Add creature favorite',
                  ),
                ),
              ],
            );
          },
        ),
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
  const _Header({required this.detail});

  final PetDetail detail;

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
            Text(
              summary.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(summary.form ?? context.tr('Default form')),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 6,
              children: summary.types
                  .map((type) => Chip(label: TypeIconLabel(typeName: type)))
                  .toList(),
            ),
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
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
    return Wrap(
      spacing: 24,
      runSpacing: 10,
      children: <Widget>[
        _Fact(label: 'Class', value: detail.className),
        _Fact(label: 'Stage', value: detail.stage?.toString()),
        _Fact(label: 'Height', value: detail.heightText),
        _Fact(label: 'Weight', value: detail.weightText),
        _Fact(label: 'Starlight', value: detail.starlight?.toString()),
        _Fact(label: 'Review gold', value: detail.reviewGold?.toString()),
        _Fact(
          label: 'Double ride',
          value: _yesNo(context, detail.canDoubleRide),
        ),
        _Fact(label: 'Shiny form', value: _yesNo(context, detail.hasShiny)),
        _Fact(
          label: 'Lord evolution',
          value: _yesNo(context, detail.isLordEvolution),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
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
  const _Stats({required this.stats});

  final Map<String, int?> stats;

  @override
  Widget build(BuildContext context) {
    const requiredStats = <String>[
      'HP',
      'Attack',
      'Defense',
      'Magic attack',
      'Magic defense',
      'Speed',
    ];
    final values = requiredStats
        .map((key) => stats[key])
        .toList(growable: false);
    final total = values.every((value) => value != null)
        ? values.fold<int>(0, (sum, value) => sum + value!)
        : null;
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
                total?.toString() ?? context.tr('Unknown'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: stats.entries
              .map(
                (entry) => Container(
                  width: 138,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          CatalogAssetImage(
                            assetPath: _statIconAsset(entry.key),
                            semanticLabel: context.tr(entry.key),
                            width: 22,
                            height: 22,
                            fallbackIcon: Icons.circle_outlined,
                          ),
                          const SizedBox(width: 6),
                          Expanded(child: Text(context.tr(entry.key))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.value?.toString() ?? context.tr('Unknown'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _IncomingRelations(
          label: context.tr('Incoming damage increased'),
          values: increased,
        ),
        const SizedBox(height: 14),
        _IncomingRelations(
          label: context.tr('Incoming damage reduced'),
          values: reduced,
        ),
        const Divider(height: 28),
        ...relationships.outgoing.map(
          (relation) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TypeIconLabel(typeName: '${relation.typeName}\u7cfb'),
                const SizedBox(height: 8),
                _TypeNameList(
                  label: context.tr('Strong against'),
                  typeNames: relation.strongAgainst,
                ),
                const SizedBox(height: 6),
                _TypeNameList(
                  label: context.tr('Resisted by'),
                  typeNames: relation.resistedBy,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IncomingRelations extends StatelessWidget {
  const _IncomingRelations({required this.label, required this.values});

  final String label;
  final List<IncomingTypeDamage> values;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 7),
        if (values.isEmpty)
          Text(context.tr('Normal damage'))
        else
          Wrap(
            spacing: 8,
            runSpacing: 7,
            children: values
                .map(
                  (item) => Chip(
                    avatar: CatalogAssetImage(
                      assetPath: typeIconAsset('${item.typeName}\u7cfb'),
                      semanticLabel: item.typeName,
                      width: 22,
                      height: 22,
                      fallbackIcon: Icons.circle_outlined,
                    ),
                    label: Text(
                      '${item.typeName}\u7cfb ×${_multiplier(item.multiplier)}',
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _TypeNameList extends StatelessWidget {
  const _TypeNameList({required this.label, required this.typeNames});

  final String label;
  final List<String> typeNames;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 7,
      runSpacing: 6,
      children: <Widget>[
        Text('$label：'),
        if (typeNames.isEmpty)
          Text(context.tr('None'))
        else
          ...typeNames.map(
            (name) => TypeIconLabel(typeName: '$name\u7cfb', compact: true),
          ),
      ],
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
  const _EvolutionList({required this.graph});

  final EvolutionGraph graph;

  @override
  Widget build(BuildContext context) {
    if (graph.nodes.isEmpty) {
      return Text(context.tr('No evolution group is provided.'));
    }
    final names = <String, String>{
      for (final node in graph.nodes) node.petId: node.name,
    };
    if (graph.edges.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(context.tr('Related group members; direction is not provided:')),
          const SizedBox(height: 8),
          Text(graph.nodes.map((node) => node.name).join(', ')),
        ],
      );
    }
    return Column(
      children: graph.edges
          .map(
            (edge) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.arrow_forward_rounded),
              title: Text(
                '${names[edge.fromPetId] ?? edge.fromPetId} → '
                '${names[edge.toPetId] ?? edge.toPetId}',
              ),
              subtitle: Text(_evolutionCondition(context, edge)),
            ),
          )
          .toList(),
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
    required this.forms,
    required this.skills,
    required this.evolution,
    required this.typeRelationships,
  });

  final PetDetail detail;
  final List<PetSummary> forms;
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

String _skillCondition(BuildContext context, LearnableSkill skill) {
  final details = <String>[_sourceLabel(context, skill.sourceKind)];
  if (skill.learnLevel != null) {
    details.add('${context.tr('Level')} ${skill.learnLevel}');
  }
  if (skill.sourceStage != null) {
    details.add('${context.tr('Source stage')} ${skill.sourceStage}');
  }
  if (skill.bloodRaw != null) {
    details.add('${context.tr('Bloodline')}：${skill.bloodRaw}');
  }
  if (skill.requirementText != null) {
    details.add(skill.requirementText!);
  }
  return details.join(' · ');
}

String _sourceLabel(BuildContext context, String sourceKind) {
  return switch (sourceKind) {
    'native' => context.tr('Native'),
    'blood' => context.tr('Bloodline'),
    'stone' => context.tr('Skill stone'),
    'legendary' => context.tr('Legendary'),
    _ => context.tr('Unknown source'),
  };
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
