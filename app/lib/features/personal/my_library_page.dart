import 'package:flutter/material.dart';

import '../../domain/catalog_models.dart';
import '../../domain/catalog_repository.dart';
import '../../domain/user_models.dart';
import '../../domain/user_repository.dart';
import '../pets/pet_detail_page.dart';
import '../skills/skill_detail_page.dart';
import 'personal_controls.dart';
import '../../l10n/app_strings.dart';

class MyLibraryPage extends StatelessWidget {
  const MyLibraryPage({
    required this.catalogRepository,
    required this.userRepository,
    required this.datasetId,
    super.key,
  });

  final CatalogRepository catalogRepository;
  final UserRepository userRepository;
  final String datasetId;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          TabBar(
            tabs: <Tab>[
              Tab(
                text: context.tr('Favorites'),
                icon: const Icon(Icons.favorite_outline),
              ),
              Tab(
                text: context.tr('Collected'),
                icon: const Icon(Icons.task_alt_outlined),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _FavoritesList(
                  catalogRepository: catalogRepository,
                  userRepository: userRepository,
                  datasetId: datasetId,
                ),
                _CollectedList(
                  catalogRepository: catalogRepository,
                  userRepository: userRepository,
                  datasetId: datasetId,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesList extends StatelessWidget {
  const _FavoritesList({
    required this.catalogRepository,
    required this.userRepository,
    required this.datasetId,
  });

  final CatalogRepository catalogRepository;
  final UserRepository userRepository;
  final String datasetId;

  Future<void> _open(BuildContext context, FavoriteItem item) async {
    try {
      switch (item.object.objectType) {
        case UserObjectType.pet:
          await catalogRepository.getPetDetail(item.object.objectId);
          if (!context.mounted) {
            return;
          }
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => PetDetailPage(
                repository: catalogRepository,
                userRepository: userRepository,
                datasetId: datasetId,
                initialPetId: item.object.objectId,
              ),
            ),
          );
        case UserObjectType.skill:
          await catalogRepository.getSkillDetail(item.object.objectId);
          if (!context.mounted) {
            return;
          }
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => SkillDetailPage(
                repository: catalogRepository,
                userRepository: userRepository,
                datasetId: datasetId,
                skillId: item.object.objectId,
              ),
            ),
          );
        case UserObjectType.handbook:
          final forms = await catalogRepository.getFormsForHandbook(
            item.object.objectId,
          );
          if (!context.mounted) {
            return;
          }
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => PetDetailPage(
                repository: catalogRepository,
                userRepository: userRepository,
                datasetId: datasetId,
                initialPetId: forms.first.petId,
              ),
            ),
          );
      }
    } on CatalogNotFoundException {
      if (!context.mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => UnavailableSavedItemPage(
            object: item.object,
            userRepository: userRepository,
            favorite: true,
          ),
        ),
      );
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('The saved item could not be opened.')),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FavoriteItem>>(
      stream: userRepository.watchFavorites(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _LibraryMessage(
            icon: Icons.error_outline_rounded,
            text: 'Favorites could not be loaded.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.requireData
            .where((item) => item.object.datasetId == datasetId)
            .toList();
        if (items.isEmpty) {
          return const _LibraryMessage(
            icon: Icons.favorite_border_rounded,
            text: 'No favorites yet.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: ListTile(
                key: ValueKey('saved-${item.object.key}'),
                leading: Icon(_objectIcon(item.object.objectType)),
                title: Text(item.object.nameSnapshot),
                subtitle: Text(
                  '${context.tr(item.object.objectType.label)} · ${item.object.objectId}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _open(context, item),
              ),
            );
          },
        );
      },
    );
  }
}

class _CollectedList extends StatelessWidget {
  const _CollectedList({
    required this.catalogRepository,
    required this.userRepository,
    required this.datasetId,
  });

  final CatalogRepository catalogRepository;
  final UserRepository userRepository;
  final String datasetId;

  Future<void> _open(BuildContext context, CollectionMark mark) async {
    final object = ObjectRef(
      datasetId: mark.datasetId,
      objectType: UserObjectType.handbook,
      objectId: mark.handbookId,
      nameSnapshot: mark.nameSnapshot,
    );
    try {
      final forms = await catalogRepository.getFormsForHandbook(
        mark.handbookId,
      );
      if (!context.mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => PetDetailPage(
            repository: catalogRepository,
            userRepository: userRepository,
            datasetId: datasetId,
            initialPetId: forms.first.petId,
          ),
        ),
      );
    } on CatalogNotFoundException {
      if (!context.mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => UnavailableSavedItemPage(
            object: object,
            userRepository: userRepository,
            favorite: false,
            collected: true,
          ),
        ),
      );
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr('The collected entry could not be opened.'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CollectionMark>>(
      stream: userRepository.watchCollectionMarks(datasetId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _LibraryMessage(
            icon: Icons.error_outline_rounded,
            text: 'Collection marks could not be loaded.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final marks = snapshot.requireData;
        if (marks.isEmpty) {
          return const _LibraryMessage(
            icon: Icons.task_alt_rounded,
            text: 'No handbook entries are marked as collected.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          itemCount: marks.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final mark = marks[index];
            return Card(
              child: ListTile(
                key: ValueKey('collected-${mark.handbookId}'),
                leading: const Icon(Icons.task_alt_rounded),
                title: Text(mark.nameSnapshot),
                subtitle: Text(context.strings.handbookEntry(mark.handbookId)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _open(context, mark),
              ),
            );
          },
        );
      },
    );
  }
}

class UnavailableSavedItemPage extends StatefulWidget {
  const UnavailableSavedItemPage({
    required this.object,
    required this.userRepository,
    required this.favorite,
    this.collected = false,
    super.key,
  });

  final ObjectRef object;
  final UserRepository userRepository;
  final bool favorite;
  final bool collected;

  @override
  State<UnavailableSavedItemPage> createState() =>
      _UnavailableSavedItemPageState();
}

class _UnavailableSavedItemPageState extends State<UnavailableSavedItemPage> {
  late bool _favorite = widget.favorite;
  late bool _collected = widget.collected;

  Future<void> _setFavorite(bool enabled) async {
    await widget.userRepository.setFavorite(widget.object, enabled);
    if (mounted) {
      setState(() => _favorite = enabled);
    }
  }

  Future<void> _setCollected(bool enabled) async {
    await widget.userRepository.setCollected(
      datasetId: widget.object.datasetId,
      handbookId: widget.object.objectId,
      nameSnapshot: widget.object.nameSnapshot,
      collected: enabled,
    );
    if (mounted) {
      setState(() => _collected = enabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Saved item'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: <Widget>[
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.object.nameSnapshot,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${context.tr(widget.object.objectType.label)} · ${widget.object.objectId}',
                  ),
                  const SizedBox(height: 12),
                  Text(context.tr('Currently unavailable in this Catalog.')),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      if (widget.favorite)
                        FavoriteIconButton(
                          favorite: _favorite,
                          objectLabel: widget.object.key,
                          onChanged: _setFavorite,
                        ),
                      if (widget.object.objectType == UserObjectType.handbook)
                        FilterChip(
                          selected: _collected,
                          label: Text(context.tr('Handbook entry collected')),
                          onSelected: _setCollected,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            context.tr('Personal notes'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          PersonalNotesSection(
            repository: widget.userRepository,
            object: widget.object,
          ),
        ],
      ),
    );
  }
}

class _LibraryMessage extends StatelessWidget {
  const _LibraryMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(context.tr(text), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

IconData _objectIcon(UserObjectType type) {
  return switch (type) {
    UserObjectType.pet => Icons.pets_rounded,
    UserObjectType.skill => Icons.auto_awesome_rounded,
    UserObjectType.handbook => Icons.menu_book_rounded,
  };
}
