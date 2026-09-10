import 'package:flutter/material.dart';

import '../../domain/tool_catalogs.dart';
import '../../l10n/app_strings.dart';
import '../../theme/catalog_theme.dart';
import '../../widgets/catalog_asset_image.dart';

class ActivityTimelinePage extends StatefulWidget {
  const ActivityTimelinePage({required this.repository, super.key});

  final ActivityTimelineRepository repository;

  @override
  State<ActivityTimelinePage> createState() => _ActivityTimelinePageState();
}

class _ActivityTimelinePageState extends State<ActivityTimelinePage> {
  late final Future<ActivityTimelineCatalog> _catalog = widget.repository
      .load();
  DateTime? _selectedMonth;
  String? _category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Event timeline'))),
      body: FutureBuilder<ActivityTimelineCatalog>(
        future: _catalog,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(context.tr('Activity timeline could not be loaded.')),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildTimeline(context, snapshot.requireData);
        },
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, ActivityTimelineCatalog catalog) {
    _selectedMonth ??= _initialMonth(catalog.entries);
    final month = _selectedMonth!;
    final entries = catalog.entries
        .where(
          (entry) =>
              (_category == null || entry.category == _category) &&
              _intersectsMonth(entry, month),
        )
        .toList(growable: false);
    return Column(
      key: const ValueKey('activity-timeline-page'),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton.outlined(
                    key: const ValueKey('activity-previous-month'),
                    tooltip: context.tr('Previous month'),
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      MaterialLocalizations.of(context).formatMonthYear(month),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton.outlined(
                    key: const ValueKey('activity-next-month'),
                    tooltip: context.tr('Next month'),
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: () {
                      final now = DateTime.now();
                      setState(
                        () => _selectedMonth = DateTime(now.year, now.month),
                      );
                    },
                    child: Text(context.tr('This month')),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    ChoiceChip(
                      label: Text(context.tr('All')),
                      selected: _category == null,
                      onSelected: (_) => setState(() => _category = null),
                    ),
                    for (final category in catalog.categoryOrder) ...<Widget>[
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(catalog.categoryLabels[category]!),
                        avatar: Icon(_categoryIcon(category), size: 18),
                        selected: _category == category,
                        onSelected: (_) => setState(
                          () => _category = _category == category
                              ? null
                              : category,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${entries.length} ${context.tr('activities')}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text(
                    context.tr('No activities are scheduled for this month.'),
                  ),
                )
              : ListView.separated(
                  key: const ValueKey('activity-timeline-list'),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _ActivityTimelineCard(
                      entry: entry,
                      now: DateTime.now(),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _changeMonth(int offset) {
    final month = _selectedMonth!;
    setState(() => _selectedMonth = DateTime(month.year, month.month + offset));
  }
}

class _ActivityTimelineCard extends StatelessWidget {
  const _ActivityTimelineCard({required this.entry, required this.now});

  final ActivityTimelineEntry entry;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final status = _activityStatus(entry, now);
    final color = _statusColor(status);
    final anchor = entry.startAt ?? entry.endAt;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 50,
            child: anchor == null
                ? const SizedBox.shrink()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        '${_sourceTime(anchor).day}',
                        style: CatalogTypography.numbers(
                          Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        context.tr('day'),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
          ),
          Container(
            width: 3,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
              child: InkWell(
                key: ValueKey('activity-${entry.activityId}'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) =>
                        ActivityDetailPage(entry: entry, now: now),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Row(
                    children: <Widget>[
                      CatalogAssetImage(
                        assetPath: entry.iconPath,
                        semanticLabel: entry.name,
                        width: 52,
                        height: 52,
                        borderRadius: BorderRadius.circular(14),
                        fallbackIcon: _categoryIcon(entry.category),
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
                                    entry.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                _StatusChip(status: status, color: color),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _windowLabel(context, entry),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (entry.summary case final summary?) ...<Widget>[
                              const SizedBox(height: 3),
                              Text(
                                summary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityDetailPage extends StatelessWidget {
  const ActivityDetailPage({required this.entry, required this.now, super.key});

  final ActivityTimelineEntry entry;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final status = _activityStatus(entry, now);
    final color = _statusColor(status);
    return Scaffold(
      appBar: AppBar(title: Text(entry.name)),
      body: ListView(
        key: ValueKey('activity-detail-${entry.activityId}'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          Card(
            color: Color.alphaBlend(
              color.withValues(alpha: 0.12),
              Theme.of(context).colorScheme.surfaceContainerLow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      CatalogAssetImage(
                        assetPath: entry.iconPath,
                        semanticLabel: entry.name,
                        width: 72,
                        height: 72,
                        borderRadius: BorderRadius.circular(20),
                        fallbackIcon: _categoryIcon(entry.category),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              entry.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 6),
                            _StatusChip(status: status, color: color),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _DetailRow(
                    icon: Icons.schedule_rounded,
                    label: context.tr('Activity time'),
                    value: _windowLabel(context, entry),
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: _categoryIcon(entry.category),
                    label: context.tr('Activity category'),
                    value: entry.kindLabel.isEmpty
                        ? context.tr('Not announced')
                        : entry.kindLabel,
                  ),
                ],
              ),
            ),
          ),
          if (entry.summary case final summary?) ...<Widget>[
            const SizedBox(height: 16),
            _TextSection(title: context.tr('Summary'), body: summary),
          ],
          if (entry.description case final description?) ...<Widget>[
            const SizedBox(height: 16),
            _TextSection(
              title: context.tr('Activity details'),
              body: description,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          context.tr(status),
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 20),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 2),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }
}

class _TextSection extends StatelessWidget {
  const _TextSection({required this.title, required this.body});

  final String title;
  final String body;

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
            const SizedBox(height: 8),
            Text(body),
          ],
        ),
      ),
    );
  }
}

DateTime _initialMonth(List<ActivityTimelineEntry> entries) {
  final now = DateTime.now();
  final current = DateTime(now.year, now.month);
  if (entries.any((entry) => _intersectsMonth(entry, current))) {
    return current;
  }
  final dated = entries
      .map((entry) => entry.startAt ?? entry.endAt)
      .whereType<DateTime>()
      .toList(growable: false);
  if (dated.isEmpty) {
    return current;
  }
  dated.sort();
  final latest = _sourceTime(dated.last);
  return DateTime(latest.year, latest.month);
}

bool _intersectsMonth(ActivityTimelineEntry entry, DateTime month) {
  if (entry.startAt == null && entry.endAt == null) {
    return false;
  }
  final startBoundary = DateTime.utc(
    month.year,
    month.month,
  ).subtract(const Duration(hours: 8));
  final endBoundary = DateTime.utc(
    month.year,
    month.month + 1,
  ).subtract(const Duration(hours: 8));
  final start = entry.startAt?.toUtc();
  final end = entry.endAt?.toUtc();
  return (end == null || !end.isBefore(startBoundary)) &&
      (start == null || start.isBefore(endBoundary));
}

DateTime _sourceTime(DateTime value) =>
    value.toUtc().add(const Duration(hours: 8));

String _activityStatus(ActivityTimelineEntry entry, DateTime now) {
  final moment = now.toUtc();
  final start = entry.startAt?.toUtc();
  final end = entry.endAt?.toUtc();
  if (start == null && end == null) {
    return 'Undated';
  }
  if (start != null && moment.isBefore(start)) {
    return 'Upcoming';
  }
  if (end != null && moment.isAfter(end)) {
    return 'Ended';
  }
  return 'Active';
}

String _windowLabel(BuildContext context, ActivityTimelineEntry entry) {
  String format(DateTime value) {
    final source = _sourceTime(value);
    final date = MaterialLocalizations.of(context).formatMediumDate(source);
    final hour = source.hour.toString().padLeft(2, '0');
    final minute = source.minute.toString().padLeft(2, '0');
    return '$date $hour:$minute';
  }

  final start = entry.startAt;
  final end = entry.endAt;
  if (start == null && end == null) {
    return context.tr('Date not announced');
  }
  if (start == null) {
    return '${context.tr('Until')} ${format(end!)}';
  }
  if (end == null) {
    return '${context.tr('From')} ${format(start)}';
  }
  return '${format(start)} — ${format(end)}';
}

Color _statusColor(String status) => switch (status) {
  'Active' => const Color(0xFF2F7C61),
  'Upcoming' => const Color(0xFF886A2C),
  'Ended' => const Color(0xFF737373),
  _ => const Color(0xFF6A6279),
};

IconData _categoryIcon(String category) => switch (category) {
  'gifts' => Icons.redeem_rounded,
  'pets' => Icons.pets_rounded,
  'challenge' => Icons.sports_martial_arts_rounded,
  'fashion' => Icons.checkroom_rounded,
  _ => Icons.celebration_rounded,
};
