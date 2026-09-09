import 'package:flutter/material.dart';

import '../../catalog_app.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.session, super.key});

  final CatalogSession session;

  @override
  Widget build(BuildContext context) {
    final info = session.info;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: <Widget>[
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        const Card(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.brightness_auto_rounded),
                title: Text('Theme'),
                subtitle: Text('Follow device setting'),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.phone_iphone_rounded),
                title: Text('Personal data'),
                subtitle: Text(
                  'Favorites, collection marks, and notes stay on this device. Uninstalling the App may remove them.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('About', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: <Widget>[
              const ListTile(
                title: Text('App version'),
                subtitle: Text('0.1.0 (1)'),
              ),
              ListTile(
                title: const Text('Catalog'),
                subtitle: Text(
                  'Data ${info.dataVersion} · Schema ${info.schemaVersion}',
                ),
              ),
              ListTile(
                title: const Text('Personal database schema'),
                subtitle: Text('${session.userSchemaVersion}'),
              ),
              ListTile(
                title: const Text('Source revision range'),
                subtitle: Text(
                  '${info.earliestSourceRevisionUtc} — ${info.latestSourceRevisionUtc}',
                ),
              ),
              ListTile(
                title: const Text('Catalog built'),
                subtitle: Text(info.builtAtUtc),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Attribution', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(session.attribution),
          ),
        ),
      ],
    );
  }
}
