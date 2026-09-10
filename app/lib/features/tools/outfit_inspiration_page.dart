import 'package:flutter/material.dart';

import '../../domain/tool_catalogs.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/catalog_asset_image.dart';

class OutfitInspirationPage extends StatefulWidget {
  const OutfitInspirationPage({required this.repository, super.key});

  final FashionCatalogRepository repository;

  @override
  State<OutfitInspirationPage> createState() => _OutfitInspirationPageState();
}

class _OutfitInspirationPageState extends State<OutfitInspirationPage> {
  final _searchController = TextEditingController();
  late final Future<FashionCatalog> _catalog = widget.repository.load();
  String _gender = 'female';
  String? _grade;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Outfit inspiration'))),
      body: FutureBuilder<FashionCatalog>(
        future: _catalog,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(context.tr('Outfit catalog could not be loaded.')),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildCatalog(context, snapshot.requireData);
        },
      ),
    );
  }

  Widget _buildCatalog(BuildContext context, FashionCatalog catalog) {
    final keyword = _searchController.text.trim().toLowerCase();
    final grades =
        catalog.entries.map((entry) => entry.gradeName).toSet().toList()
          ..sort();
    final entries = catalog.entries
        .where((entry) {
          final variant = entry.variantFor(_gender);
          return (_grade == null || entry.gradeName == _grade) &&
              (keyword.isEmpty ||
                  entry.name.toLowerCase().contains(keyword) ||
                  variant.name.toLowerCase().contains(keyword) ||
                  variant.acquisition.any(
                    (value) => value.toLowerCase().contains(keyword),
                  ));
        })
        .toList(growable: false);
    return Column(
      key: const ValueKey('outfit-inspiration-page'),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                key: const ValueKey('outfit-search'),
                controller: _searchController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
                autocorrect: false,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: context.tr('Search outfits'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  for (final gender in catalog.genderOrder) ...<Widget>[
                    ChoiceChip(
                      key: ValueKey('outfit-gender-$gender'),
                      avatar: Icon(
                        gender == 'female'
                            ? Icons.female_rounded
                            : Icons.male_rounded,
                        size: 18,
                      ),
                      label: Text(
                        context.tr(gender == 'female' ? 'Female' : 'Male'),
                      ),
                      selected: _gender == gender,
                      onSelected: (_) => setState(() => _gender = gender),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    ChoiceChip(
                      label: Text(context.tr('All')),
                      selected: _grade == null,
                      onSelected: (_) => setState(() => _grade = null),
                    ),
                    for (final grade in grades) ...<Widget>[
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(grade),
                        selected: _grade == grade,
                        onSelected: (_) => setState(
                          () => _grade = _grade == grade ? null : grade,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${entries.length} ${context.tr('outfits')}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text(context.tr('No outfits match these filters.')),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 800
                        ? 4
                        : constraints.maxWidth >= 560
                        ? 3
                        : 2;
                    return GridView.builder(
                      key: const ValueKey('outfit-grid'),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.77,
                      ),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final variant = entry.variantFor(_gender);
                        return _OutfitCard(
                          entry: entry,
                          variant: variant,
                          gender: _gender,
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _OutfitCard extends StatelessWidget {
  const _OutfitCard({
    required this.entry,
    required this.variant,
    required this.gender,
  });

  final FashionEntry entry;
  final FashionVariant variant;
  final String gender;

  @override
  Widget build(BuildContext context) {
    final color = _qualityColor(entry.quality);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        key: ValueKey('outfit-${entry.outfitId}'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) =>
                OutfitDetailPage(entry: entry, initialGender: gender),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: SizedBox.expand(
                  child: CatalogAssetImage(
                    assetPath: variant.imagePath,
                    semanticLabel: variant.name,
                    fit: BoxFit.contain,
                    borderRadius: BorderRadius.circular(14),
                    fallbackIcon: Icons.checkroom_rounded,
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                variant.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Icon(Icons.auto_awesome_rounded, size: 15, color: color),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      entry.gradeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: color),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OutfitDetailPage extends StatefulWidget {
  const OutfitDetailPage({
    required this.entry,
    required this.initialGender,
    super.key,
  });

  final FashionEntry entry;
  final String initialGender;

  @override
  State<OutfitDetailPage> createState() => _OutfitDetailPageState();
}

class _OutfitDetailPageState extends State<OutfitDetailPage> {
  late String _gender = widget.initialGender;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final variant = entry.variantFor(_gender);
    final description = variant.description ?? entry.description;
    return Scaffold(
      appBar: AppBar(title: Text(variant.name)),
      body: ListView(
        key: ValueKey('outfit-detail-${entry.outfitId}'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 280,
                    child: CatalogAssetImage(
                      assetPath: variant.imagePath,
                      semanticLabel: variant.name,
                      fit: BoxFit.contain,
                      borderRadius: BorderRadius.circular(18),
                      fallbackIcon: Icons.checkroom_rounded,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      for (final option in entry.variants)
                        ChoiceChip(
                          key: ValueKey(
                            'outfit-detail-gender-${option.gender}',
                          ),
                          label: Text(
                            context.tr(
                              option.gender == 'female' ? 'Female' : 'Male',
                            ),
                          ),
                          selected: _gender == option.gender,
                          onSelected: (_) =>
                              setState(() => _gender = option.gender),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    variant.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${entry.gradeName} · ${context.tr('Quality')} ${entry.quality} · ${variant.itemCount} ${context.tr('pieces')}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          if (description != null) ...<Widget>[
            const SizedBox(height: 16),
            _OutfitSection(
              title: context.tr('Outfit description'),
              child: Text(description),
            ),
          ],
          const SizedBox(height: 16),
          _OutfitSection(
            title: context.tr('How to obtain'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final value in variant.acquisition)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(Icons.arrow_right_rounded),
                        const SizedBox(width: 5),
                        Expanded(child: Text(value)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutfitSection extends StatelessWidget {
  const _OutfitSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

Color _qualityColor(int quality) => switch (quality) {
  5 => const Color(0xFFA45081),
  4 => const Color(0xFF6556A8),
  _ => const Color(0xFF367083),
};
