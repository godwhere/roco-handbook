import 'package:flutter/material.dart';

import '../../domain/catalog_models.dart';
import '../../domain/catalog_repository.dart';
import '../../domain/user_models.dart';
import '../../domain/user_repository.dart';
import '../pets/pet_detail_page.dart';
import '../personal/personal_controls.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/catalog_asset_image.dart';

class SkillDetailPage extends StatefulWidget {
  const SkillDetailPage({
    required this.repository,
    required this.userRepository,
    required this.datasetId,
    required this.skillId,
    super.key,
  });

  final CatalogRepository repository;
  final UserRepository userRepository;
  final String datasetId;
  final String skillId;

  @override
  State<SkillDetailPage> createState() => _SkillDetailPageState();
}

class _SkillDetailPageState extends State<SkillDetailPage> {
  late Future<_SkillPageData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_SkillPageData> _load() async {
    final detail = await widget.repository.getSkillDetail(widget.skillId);
    final values = await Future.wait<List<SkillUser>>(<Future<List<SkillUser>>>[
      if (detail.summary.isFeature)
        widget.repository.getSkillUsers(widget.skillId, feature: true)
      else
        Future<List<SkillUser>>.value(const <SkillUser>[]),
      widget.repository.getSkillUsers(widget.skillId, feature: false),
    ]);
    return _SkillPageData(
      detail: detail,
      featureUsers: values[0],
      learnableUsers: values[1],
    );
  }

  void _retry() {
    setState(() => _data = _load());
  }

  void _openPet(String petId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PetDetailPage(
          repository: widget.repository,
          userRepository: widget.userRepository,
          datasetId: widget.datasetId,
          initialPetId: petId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Skill details'))),
      body: FutureBuilder<_SkillPageData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(context.tr('Skill details could not be loaded.')),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _retry,
                    child: Text(context.tr('Try again')),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.requireData;
          return SelectionArea(
            child: ListView(
              key: ValueKey('skill-detail-${data.detail.summary.skillId}'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: <Widget>[
                _SkillHeader(detail: data.detail),
                const SizedBox(height: 18),
                _Section(
                  title: context.tr('Values'),
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 10,
                    children: <Widget>[
                      _Fact(
                        label: 'Element',
                        value: data.detail.summary.element,
                      ),
                      _Fact(
                        label: 'Category',
                        value: data.detail.summary.category,
                      ),
                      _Fact(
                        label: 'Energy',
                        value: _numericText(
                          data.detail.summary.energyValue,
                          data.detail.summary.energyText,
                        ),
                      ),
                      _Fact(
                        label: 'Power',
                        value: _numericText(
                          data.detail.summary.powerValue,
                          data.detail.summary.powerText,
                        ),
                      ),
                      _Fact(label: 'Target', value: data.detail.targetText),
                    ],
                  ),
                ),
                if (data.detail.descriptionNoteIds.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 18),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: Text(
                        context.tr('Glossary definitions are not included'),
                      ),
                      subtitle: Text(
                        context.tr(
                          'The original description is available, but referenced glossary definitions are not part of this Catalog.',
                        ),
                      ),
                    ),
                  ),
                ],
                if (data.featureUsers.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 18),
                  _Section(
                    title: context.tr('Creatures with this feature'),
                    child: _UserList(
                      users: data.featureUsers,
                      onOpen: _openPet,
                    ),
                  ),
                ],
                if (data.learnableUsers.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 18),
                  _Section(
                    title: context.tr('Creatures that can learn this skill'),
                    child: _UserList(
                      users: data.learnableUsers,
                      onOpen: _openPet,
                    ),
                  ),
                ],
                if (data.featureUsers.isEmpty &&
                    data.learnableUsers.isEmpty) ...<Widget>[
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        context.tr('No creature relationship is provided.'),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                _Section(
                  title: context.tr('My library'),
                  child: _SkillPersonalData(
                    userRepository: widget.userRepository,
                    datasetId: widget.datasetId,
                    detail: data.detail,
                  ),
                ),
                const SizedBox(height: 18),
                _Section(
                  title: context.tr('Source'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: data.detail.sourceReferences
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(source.licenseId),
                                SelectableText(source.sourceUrl),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SkillPersonalData extends StatelessWidget {
  const _SkillPersonalData({
    required this.userRepository,
    required this.datasetId,
    required this.detail,
  });

  final UserRepository userRepository;
  final String datasetId;
  final SkillDetail detail;

  @override
  Widget build(BuildContext context) {
    final object = ObjectRef(
      datasetId: datasetId,
      objectType: UserObjectType.skill,
      objectId: detail.summary.skillId,
      nameSnapshot: detail.summary.name,
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
                  objectLabel: detail.summary.skillId,
                  onChanged: (enabled) =>
                      userRepository.setFavorite(object, enabled),
                ),
                Text(
                  context.tr(
                    favorite ? 'Skill favorite' : 'Add skill favorite',
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        PersonalNotesSection(repository: userRepository, object: object),
      ],
    );
  }
}

class _SkillHeader extends StatelessWidget {
  const _SkillHeader({required this.detail});

  final SkillDetail detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CatalogAssetImage(
                  assetPath: skillIconAsset(detail.summary),
                  semanticLabel: detail.summary.name,
                  width: 58,
                  height: 58,
                  fallbackIcon: detail.summary.isFeature
                      ? Icons.auto_awesome_rounded
                      : Icons.bolt_rounded,
                  borderRadius: BorderRadius.circular(14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        context.tr(
                          detail.summary.isFeature ? 'Feature' : 'Skill',
                        ),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        detail.summary.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              ],
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

class _UserList extends StatelessWidget {
  const _UserList({required this.users, required this.onOpen});

  final List<SkillUser> users;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: users
          .map(
            (user) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CatalogAssetImage(
                assetPath: petHeadAsset(user.pet.headKey),
                semanticLabel: user.pet.name,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                fallbackIcon: Icons.pets_outlined,
                borderRadius: BorderRadius.circular(10),
              ),
              title: Text(user.pet.name),
              subtitle: Text(_relationshipText(context, user)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => onOpen(user.pet.petId),
            ),
          )
          .toList(),
    );
  }
}

final class _SkillPageData {
  const _SkillPageData({
    required this.detail,
    required this.featureUsers,
    required this.learnableUsers,
  });

  final SkillDetail detail;
  final List<SkillUser> featureUsers;
  final List<SkillUser> learnableUsers;
}

String? _numericText(num? value, String? text) {
  if (value != null) {
    return value.toString();
  }
  return text;
}

String _relationshipText(BuildContext context, SkillUser user) {
  final values = <String>[_sourceLabel(context, user.relationshipKind)];
  if (user.learnLevel != null) {
    values.add('${context.tr('Level')} ${user.learnLevel}');
  }
  if (user.sourceStage != null) {
    values.add('${context.tr('Source stage')} ${user.sourceStage}');
  }
  if (user.bloodRaw != null) {
    values.add('${context.tr('Bloodline')}：${user.bloodRaw}');
  }
  if (user.requirementText != null) {
    values.add(user.requirementText!);
  }
  return values.join(' · ');
}

String _sourceLabel(BuildContext context, String sourceKind) {
  return switch (sourceKind) {
    'feature' => context.tr('Feature relationship'),
    'native' => context.tr('Native'),
    'blood' => context.tr('Bloodline'),
    'stone' => context.tr('Skill stone'),
    'legendary' => context.tr('Legendary'),
    _ => context.tr('Unknown source'),
  };
}
