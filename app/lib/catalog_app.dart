import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'data/catalog/catalog_installer.dart';
import 'data/catalog/sqlite_catalog_repository.dart';
import 'data/user/sqlite_user_repository.dart';
import 'data/user/user_database_migrator.dart';
import 'domain/catalog_models.dart';
import 'domain/catalog_repository.dart';
import 'domain/user_models.dart';
import 'domain/user_repository.dart';
import 'features/catalog/catalog_home_page.dart';

final class CatalogSession {
  const CatalogSession({
    required this.repository,
    required this.info,
    required this.attribution,
    required this.installed,
    required this.userRepository,
    required this.userDatabaseCreated,
    required this.userSchemaVersion,
  });

  final CatalogRepository repository;
  final CatalogInfo info;
  final String attribution;
  final bool installed;
  final UserRepository userRepository;
  final bool userDatabaseCreated;
  final int userSchemaVersion;
}

final class ProductionCatalogBootstrap {
  const ProductionCatalogBootstrap();

  Future<CatalogSession> load() async {
    const source = AssetBundledCatalogSource();
    final bundle = await source.load();
    final support = await getApplicationSupportDirectory();
    final open = await LocalCatalogInstaller(support.path)
        .prepareBundledCatalog(bundle);
    final repository = SqliteCatalogRepository(open.databasePath);
    final info = await repository.getCatalogInfo();
    const userSchemaSource = AssetUserSchemaSource();
    final userSchema = await userSchemaSource.loadVersionOne();
    final userOpen = await UserDatabaseMigrator(support.path)
        .prepare(userSchema);
    return CatalogSession(
      repository: repository,
      info: info,
      attribution: bundle.attributionText,
      installed: open.installed,
      userRepository: SqliteUserRepository(userOpen.databasePath),
      userDatabaseCreated: userOpen.created,
      userSchemaVersion: userOpen.schemaVersion,
    );
  }
}

class CatalogBootstrapApp extends StatefulWidget {
  const CatalogBootstrapApp({required this.bootstrap, super.key});

  final Future<CatalogSession> Function() bootstrap;

  @override
  State<CatalogBootstrapApp> createState() => _CatalogBootstrapAppState();
}

class _CatalogBootstrapAppState extends State<CatalogBootstrapApp> {
  late Future<CatalogSession> _session;

  @override
  void initState() {
    super.initState();
    _session = widget.bootstrap();
  }

  void _retry() {
    setState(() {
      _session = widget.bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2D6A4F),
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF74C69D),
      brightness: Brightness.dark,
    );
    return MaterialApp(
      title: 'Roco Handbook',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: lightScheme,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(filled: true),
        cardTheme: const CardThemeData(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: darkScheme,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(filled: true),
        cardTheme: const CardThemeData(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
        ),
      ),
      home: FutureBuilder<CatalogSession>(
        future: _session,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return CatalogHomePage(session: snapshot.requireData);
          }
          if (snapshot.hasError) {
            return _CatalogFailureScreen(
              error: snapshot.error!,
              onRetry: _retry,
            );
          }
          return const _CatalogPreparingScreen();
        },
      ),
    );
  }
}

class _CatalogPreparingScreen extends StatelessWidget {
  const _CatalogPreparingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Semantics(
            liveRegion: true,
            label: 'Preparing the offline Catalog',
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Preparing the offline Catalog...'),
                SizedBox(height: 8),
                Text('No download is required.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogFailureScreen extends StatelessWidget {
  const _CatalogFailureScreen({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final code = switch (error) {
      CatalogInstallException value => value.code,
      UserDataException value => value.code,
      _ => 'app_startup',
    };
    final personalFailure = error is UserDataException;
    return Scaffold(
      appBar: AppBar(title: const Text('Roco Handbook')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.storage_rounded,
                    size: 56,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    personalFailure
                        ? 'Your personal library could not be opened.'
                        : 'The offline Catalog could not be opened.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    personalFailure
                        ? 'The existing personal database was preserved. Correct the storage problem, then try again.'
                        : 'Your personal data was not changed. Try preparing the bundled Catalog again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text('Error code: $code'),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
