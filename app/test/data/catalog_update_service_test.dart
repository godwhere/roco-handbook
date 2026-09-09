import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:roco_handbook/data/catalog/catalog_installer.dart';
import 'package:roco_handbook/data/catalog/catalog_update_service.dart';
import 'package:roco_handbook/data/catalog/catalog_update_source.dart';
import 'package:roco_handbook/data/catalog/remote_catalog_manifest.dart';

void main() {
  late RemoteCatalogManifestVerifier verifier;

  setUp(() {
    verifier = RemoteCatalogManifestVerifier(
      CatalogManifestTrustStore.fromJsonText(
        File('assets/catalog/catalog_trust_store.json').readAsStringSync(),
      ),
    );
  });

  test('uses persisted replay state for a foreground check', () async {
    final source = _RecordingSource();
    final service = CatalogUpdateService(
      source: source,
      verifier: verifier,
      installer: _ReplayInstaller(7),
    );

    final result = await service.check(
      currentAppVersion: '1.1.0',
      currentDataVersion: 3,
      cancellation: CatalogUpdateCancellationToken(),
    );

    expect(result, isA<CatalogUpdateCurrent>());
    expect(source.context?.currentAppVersion, '1.1.0');
    expect(source.context?.currentDataVersion, 3);
    expect(source.context?.highestAcceptedReleaseSequence, 7);
    expect(source.context?.allowedHosts, const <String>{'github.com'});
  });

  test('maps an unreadable replay state without contacting the host', () async {
    final source = _RecordingSource();
    final service = CatalogUpdateService(
      source: source,
      verifier: verifier,
      installer: const _ReplayInstaller(
        0,
        error: CatalogInstallException(
          'remote_state_shape',
          'Forced test failure.',
        ),
      ),
    );

    await expectLater(
      service.check(
        currentAppVersion: '1.1.0',
        currentDataVersion: 1,
        cancellation: CatalogUpdateCancellationToken(),
      ),
      throwsA(
        isA<CatalogUpdateException>().having(
          (error) => error.code,
          'code',
          'install_remote_state_shape',
        ),
      ),
    );
    expect(source.checkCalls, 0);
  });
}

final class _RecordingSource implements CatalogPackageSource {
  RemoteCatalogValidationContext? context;
  var checkCalls = 0;

  @override
  Future<CatalogUpdateCheckResult> check({
    required RemoteCatalogValidationContext context,
    required CatalogUpdateCancellationToken cancellation,
  }) async {
    cancellation.throwIfCancelled();
    checkCalls += 1;
    this.context = context;
    return const CatalogUpdateCurrent();
  }

  @override
  Future<Uint8List> downloadCompletePackage({
    required CatalogUpdateCandidate candidate,
    required CatalogUpdateCancellationToken cancellation,
    required void Function(CatalogUpdateProgress progress) onProgress,
  }) => throw UnsupportedError('This test source does not download.');
}

final class _ReplayInstaller implements CatalogInstaller {
  const _ReplayInstaller(this.sequence, {this.error});

  final int sequence;
  final CatalogInstallException? error;

  @override
  Future<int> readHighestAcceptedRemoteReleaseSequence() async {
    if (error case final failure?) {
      throw failure;
    }
    return sequence;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
