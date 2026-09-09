import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';

import 'app_version.dart';
import 'data/catalog/catalog_installer.dart';
import 'data/catalog/catalog_update_service.dart';
import 'data/catalog/catalog_update_source.dart';
import 'data/catalog/remote_catalog_manifest.dart';
import 'data/catalog/sqlite_catalog_repository.dart';
import 'data/user/sqlite_user_repository.dart';
import 'data/user/user_database_migrator.dart';
import 'domain/catalog_models.dart';
import 'domain/catalog_repository.dart';
import 'domain/user_models.dart';
import 'domain/user_repository.dart';
import 'features/catalog/catalog_home_page.dart';
import 'l10n/app_strings.dart';

final class CatalogSession {
  const CatalogSession({
    required this.repository,
    required this.info,
    required this.attribution,
    required this.installed,
    required this.userRepository,
    required this.userDatabaseCreated,
    required this.userSchemaVersion,
    this.catalogOutcome = CatalogOpenOutcome.reused,
  });

  final CatalogRepository repository;
  final CatalogInfo info;
  final String attribution;
  final bool installed;
  final UserRepository userRepository;
  final bool userDatabaseCreated;
  final int userSchemaVersion;
  final CatalogOpenOutcome catalogOutcome;
}

final class ProductionCatalogBootstrap {
  const ProductionCatalogBootstrap();

  Future<CatalogSession> load() => _load(restoreBundled: false);

  Future<CatalogSession> restoreBundledCatalog() => _load(restoreBundled: true);

  Future<CatalogUpdateCheckResult> checkForCatalogUpdate(
    CatalogSession session,
    CatalogUpdateCancellationToken cancellation,
  ) async {
    final service = await _updateService();
    return service.check(
      currentAppVersion: AppVersion.name,
      currentDataVersion: session.info.dataVersion,
      cancellation: cancellation,
    );
  }

  Future<CatalogSession> installCatalogUpdate(
    CatalogSession session,
    CatalogUpdateCandidate candidate,
    CatalogUpdateCancellationToken cancellation,
    void Function(CatalogUpdateProgress progress) onProgress,
  ) async {
    final service = await _updateService();
    final open = await service.downloadAndInstall(
      currentAppVersion: AppVersion.name,
      currentDataVersion: session.info.dataVersion,
      candidate: candidate,
      cancellation: cancellation,
      onProgress: onProgress,
    );
    final repository = SqliteCatalogRepository(open.databasePath);
    final info = await repository.getCatalogInfo();
    return CatalogSession(
      repository: repository,
      info: info,
      attribution: open.attributionText,
      installed: open.installed,
      userRepository: session.userRepository,
      userDatabaseCreated: session.userDatabaseCreated,
      userSchemaVersion: session.userSchemaVersion,
      catalogOutcome: open.outcome,
    );
  }

  Future<CatalogUpdateService> _updateService() async {
    try {
      final support = await getApplicationSupportDirectory();
      final trustStoreText = await rootBundle.loadString(
        'assets/catalog/catalog_trust_store.json',
      );
      final verifier = RemoteCatalogManifestVerifier(
        CatalogManifestTrustStore.fromJsonText(trustStoreText),
      );
      return CatalogUpdateService(
        source: GitHubReleaseCatalogSource(verifier: verifier),
        verifier: verifier,
        installer: LocalCatalogInstaller(support.path),
      );
    } on RemoteCatalogManifestException catch (error) {
      throw CatalogUpdateException(
        'trust_${error.code}',
        'The bundled Catalog update trust configuration is invalid.',
      );
    } on CatalogUpdateException {
      rethrow;
    } on Object {
      throw const CatalogUpdateException(
        'update_setup',
        'The Catalog update service could not be prepared.',
      );
    }
  }

  Future<CatalogSession> _load({required bool restoreBundled}) async {
    const source = AssetBundledCatalogSource();
    final bundle = await source.load();
    final support = await getApplicationSupportDirectory();
    final installer = LocalCatalogInstaller(support.path);
    final open = restoreBundled
        ? await installer.restoreBundledCatalog(bundle)
        : await installer.prepareBundledCatalog(bundle);
    final repository = SqliteCatalogRepository(open.databasePath);
    final info = await repository.getCatalogInfo();
    const userSchemaSource = AssetUserSchemaSource();
    final userSchema = await userSchemaSource.loadVersionOne();
    final userOpen = await UserDatabaseMigrator(support.path)
        .prepare(userSchema);
    return CatalogSession(
      repository: repository,
      info: info,
      attribution: open.attributionText,
      installed: open.installed,
      userRepository: SqliteUserRepository(userOpen.databasePath),
      userDatabaseCreated: userOpen.created,
      userSchemaVersion: userOpen.schemaVersion,
      catalogOutcome: open.outcome,
    );
  }
}

class CatalogBootstrapApp extends StatefulWidget {
  const CatalogBootstrapApp({
    required this.bootstrap,
    this.restoreBundledCatalog,
    this.checkForCatalogUpdate,
    this.installCatalogUpdate,
    super.key,
  });

  final Future<CatalogSession> Function() bootstrap;
  final Future<CatalogSession> Function()? restoreBundledCatalog;
  final Future<CatalogUpdateCheckResult> Function(
    CatalogSession session,
    CatalogUpdateCancellationToken cancellation,
  )?
  checkForCatalogUpdate;
  final Future<CatalogSession> Function(
    CatalogSession session,
    CatalogUpdateCandidate candidate,
    CatalogUpdateCancellationToken cancellation,
    void Function(CatalogUpdateProgress progress) onProgress,
  )?
  installCatalogUpdate;

  @override
  State<CatalogBootstrapApp> createState() => _CatalogBootstrapAppState();
}

class _CatalogBootstrapAppState extends State<CatalogBootstrapApp> {
  late Future<CatalogSession> _session;
  CatalogSession? _openedSession;

  @override
  void initState() {
    super.initState();
    _session = _load(widget.bootstrap);
  }

  void _retry() {
    setState(() {
      _session = _load(widget.bootstrap);
    });
  }

  Future<CatalogSession> _load(Future<CatalogSession> Function() loader) async {
    final session = await loader();
    _openedSession = session;
    return session;
  }

  Future<void> _restoreBundledCatalog() async {
    final loader = widget.restoreBundledCatalog;
    if (loader == null) {
      throw const CatalogInstallException(
        'catalog_restore_unavailable',
        'Bundled Catalog recovery is not available in this build.',
      );
    }
    final previous = _openedSession;
    _openedSession = null;
    final replacement = () async {
      await previous?.userRepository.close();
      return _load(loader);
    }();
    setState(() {
      _session = replacement;
    });
    await replacement;
  }

  Future<CatalogUpdateCheckResult> _checkForCatalogUpdate(
    CatalogUpdateCancellationToken cancellation,
  ) {
    final checker = widget.checkForCatalogUpdate;
    final session = _openedSession;
    if (checker == null || session == null) {
      throw const CatalogUpdateException(
        'update_unavailable',
        'Catalog updates are not available in this build.',
      );
    }
    return checker(session, cancellation);
  }

  Future<void> _installCatalogUpdate(
    CatalogUpdateCandidate candidate,
    CatalogUpdateCancellationToken cancellation,
    void Function(CatalogUpdateProgress progress) onProgress,
  ) async {
    final installer = widget.installCatalogUpdate;
    final current = _openedSession;
    if (installer == null || current == null) {
      throw const CatalogUpdateException(
        'update_unavailable',
        'Catalog updates are not available in this build.',
      );
    }
    final replacement = await installer(
      current,
      candidate,
      cancellation,
      onProgress,
    );
    if (!mounted) {
      return;
    }
    _openedSession = replacement;
    setState(() {
      _session = Future<CatalogSession>.value(replacement);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF146FC7),
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF68B6FF),
      brightness: Brightness.dark,
    );
    return MaterialApp(
      title: 'Roco World Handbook',
      onGenerateTitle: (context) => context.tr('Roco World Handbook'),
      debugShowCheckedModeBanner: false,
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
            return CatalogHomePage(
              session: snapshot.requireData,
              onRestoreBundledCatalog: widget.restoreBundledCatalog == null
                  ? null
                  : _restoreBundledCatalog,
              onCheckCatalogUpdate: widget.checkForCatalogUpdate == null
                  ? null
                  : _checkForCatalogUpdate,
              onInstallCatalogUpdate: widget.installCatalogUpdate == null
                  ? null
                  : _installCatalogUpdate,
            );
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
            label: context.tr('Preparing the offline Catalog'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(context.tr('Preparing the offline Catalog...')),
                const SizedBox(height: 8),
                Text(context.tr('No download is required.')),
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
      appBar: AppBar(title: Text(context.tr('Roco World Handbook'))),
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
                        ? context.tr(
                            'Your personal library could not be opened.',
                          )
                        : context.tr(
                            'The offline Catalog could not be opened.',
                          ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    personalFailure
                        ? context.tr(
                            'The existing personal database was preserved. Correct the storage problem, then try again.',
                          )
                        : context.tr(
                            'Your personal data was not changed. Try preparing the bundled Catalog again.',
                          ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(context.strings.errorCode(code)),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.tr('Try again')),
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
