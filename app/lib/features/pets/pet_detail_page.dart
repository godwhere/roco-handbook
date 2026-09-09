import 'package:flutter/material.dart';

import '../../domain/catalog_models.dart';
import '../../domain/catalog_repository.dart';
import '../../domain/user_models.dart';
import '../../domain/user_repository.dart';
import '../personal/personal_controls.dart';
import '../skills/skill_detail_page.dart';

class PetDetailPage extends StatefulWidget {
  const PetDetailPage({
    required this.repository,
    required this.userRepository,
    required this.datasetId,
    required this.initialPetId,
    super.key,
  });

  final CatalogRepository repository;
  final UserRepository userRepository;
  final String datasetId;
  final String initialPetId;

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
    final values = await Future.wait<Object>(<Future<Object>>[
      widget.repository.getPetDetail(petId),
      widget.repository.getSkillsForPet(petId),
      widget.repository.getEvolutionGraph(petId),
    ]);
    final detail = values[0] as PetDetail;
    final forms = await widget.repository.getFormsForHandbook(
      detail.summary.handbookId,
    );
    return _PetPageData(
      detail: detail,
      forms: forms,
      skills: values[1] as PetSkillBundle,
      evolution: values[2] as EvolutionGraph,
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
      appBar: AppBar(title: const Text('Creature details')),
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
                    decoration: const InputDecoration(
                      labelText: 'Displayed form',
                      prefixIcon: Icon(Icons.layers_outlined),
                    ),
                    items: data.forms
                        .map(
                          (form) => DropdownMenuItem<String>(
                            value: form.petId,
                            child: Text(
                              '${form.name} — ${form.form ?? 'Default form'}',
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
                  title: 'Basic information',
                  child: _BasicInformation(detail: data.detail),
                ),
                const SizedBox(height: 18),
                _Section(
                  title: 'Base stats',
                  child: _Stats(stats: data.detail.stats),
                ),
                const SizedBox(height: 18),
                _Section(
                  title: 'Feature',
                  child: data.skills.featureSkill == null
                      ? const Text('Not provided')
                      : ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.auto_awesome_rounded),
                          title: Text(data.skills.featureSkill!.name),
                          subtitle: const Text('Feature relationship'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () =>
                              _openSkill(data.skills.featureSkill!.skillId),
                        ),
                ),
                const SizedBox(height: 18),
                _Section(
                  title: 'Learnable skills',
                  child: data.skills.learnableSkills.isEmpty
                      ? const Text('No learning source is provided.')
                      : Column(
                          children: data.skills.learnableSkills
                              .map(
                                (skill) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(skill.skill.name),
                                  subtitle: Text(_skillCondition(skill)),
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
                  title: 'Evolution',
                  child: _EvolutionList(graph: data.evolution),
                ),
                const SizedBox(height: 18),
                _Section(
                  title: 'My library',
                  child: _CreaturePersonalData(
                    userRepository: widget.userRepository,
                    datasetId: widget.datasetId,
                    detail: data.detail,
                  ),
                ),
                const SizedBox(height: 18),
                _Section(
                  title: 'Source',
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
                Text(favorite ? 'Creature favorite' : 'Add creature favorite'),
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
        const Text(
          'The collection mark applies to this handbook entry, not to every form.',
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
            Text(summary.form ?? 'Default form'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 6,
              children: summary.types
                  .map((type) => Chip(label: Text(type)))
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
        _Fact(label: 'Double ride', value: _yesNo(detail.canDoubleRide)),
        _Fact(label: 'Shiny form', value: _yesNo(detail.hasShiny)),
        _Fact(label: 'Lord evolution', value: _yesNo(detail.isLordEvolution)),
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
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(value ?? 'Not provided'),
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
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: stats.entries
          .map(
            (entry) => Container(
              width: 138,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(entry.key),
                  const SizedBox(height: 4),
                  Text(
                    entry.value?.toString() ?? 'Unknown',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _EvolutionList extends StatelessWidget {
  const _EvolutionList({required this.graph});

  final EvolutionGraph graph;

  @override
  Widget build(BuildContext context) {
    if (graph.nodes.isEmpty) {
      return const Text('No evolution group is provided.');
    }
    final names = <String, String>{
      for (final node in graph.nodes) node.petId: node.name,
    };
    if (graph.edges.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Related group members; direction is not provided:'),
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
              subtitle: Text(_evolutionCondition(edge)),
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
      return const Text('Source reference not provided.');
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
                    '${source.sourceName} — revision ${source.revisionId}',
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
          const Text('Creature details could not be loaded.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
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
  });

  final PetDetail detail;
  final List<PetSummary> forms;
  final PetSkillBundle skills;
  final EvolutionGraph evolution;
}

String _yesNo(bool? value) {
  if (value == null) {
    return 'Not provided';
  }
  return value ? 'Yes' : 'No';
}

String _skillCondition(LearnableSkill skill) {
  final details = <String>[_sourceLabel(skill.sourceKind)];
  if (skill.learnLevel != null) {
    details.add('level ${skill.learnLevel}');
  }
  if (skill.sourceStage != null) {
    details.add('source stage ${skill.sourceStage}');
  }
  if (skill.bloodRaw != null) {
    details.add('bloodline: ${skill.bloodRaw}');
  }
  if (skill.requirementText != null) {
    details.add(skill.requirementText!);
  }
  return details.join(' · ');
}

String _sourceLabel(String sourceKind) {
  return switch (sourceKind) {
    'native' => 'Native',
    'blood' => 'Bloodline',
    'stone' => 'Skill stone',
    'legendary' => 'Legendary',
    _ => 'Unknown source',
  };
}

String _evolutionCondition(EvolutionEdge edge) {
  final details = <String>[
    edge.methodCode == 'lord_branch' ? 'Lord branch' : 'Evolution chain',
  ];
  if (edge.levelRequirement != null) {
    details.add('level ${edge.levelRequirement}');
  }
  if (edge.conditionText != null) {
    details.add(edge.conditionText!);
  }
  return details.join(' · ');
}
