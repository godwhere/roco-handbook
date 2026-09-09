import 'dart:typed_data';

import 'catalog_installer.dart';
import 'catalog_update_source.dart';
import 'remote_catalog_archive.dart';
import 'remote_catalog_manifest.dart';

final class CatalogUpdateService {
  const CatalogUpdateService({
    required this.source,
    required this.verifier,
    required this.installer,
    this.packagePipeline = const RemoteCatalogPackagePipeline(),
  });

  final CatalogPackageSource source;
  final RemoteCatalogManifestVerifier verifier;
  final CatalogInstaller installer;
  final RemoteCatalogPackagePipeline packagePipeline;

  Future<CatalogUpdateCheckResult> check({
    required String currentAppVersion,
    required int currentDataVersion,
    required CatalogUpdateCancellationToken cancellation,
  }) async {
    try {
      cancellation.throwIfCancelled();
      final highestSequence = await installer
          .readHighestAcceptedRemoteReleaseSequence();
      cancellation.throwIfCancelled();
      return await source.check(
        context: _context(
          currentAppVersion: currentAppVersion,
          currentDataVersion: currentDataVersion,
          highestAcceptedReleaseSequence: highestSequence,
        ),
        cancellation: cancellation,
      );
    } on CatalogUpdateException {
      rethrow;
    } on CatalogInstallException catch (error) {
      throw CatalogUpdateException(
        'install_${error.code}',
        'The Catalog update state could not be read.',
      );
    }
  }

  Future<CatalogOpenResult> downloadAndInstall({
    required String currentAppVersion,
    required int currentDataVersion,
    required CatalogUpdateCandidate candidate,
    required CatalogUpdateCancellationToken cancellation,
    required void Function(CatalogUpdateProgress progress) onProgress,
  }) async {
    final Uint8List archiveBytes;
    try {
      archiveBytes = await source.downloadCompletePackage(
        candidate: candidate,
        cancellation: cancellation,
        onProgress: onProgress,
      );
      onProgress(
        CatalogUpdateProgress(
          phase: CatalogUpdatePhase.verifyingAndInstalling,
          receivedBytes: archiveBytes.length,
          totalBytes: candidate.manifest.package.archiveBytes,
        ),
      );
      return await packagePipeline.verifyAndInstall(
        envelopeText: candidate.envelopeText,
        archiveBytes: archiveBytes,
        context: _context(
          currentAppVersion: currentAppVersion,
          currentDataVersion: currentDataVersion,
          highestAcceptedReleaseSequence: 0,
        ),
        verifier: verifier,
        installer: installer,
      );
    } on CatalogUpdateException {
      rethrow;
    } on RemoteCatalogManifestException catch (error) {
      throw CatalogUpdateException(
        'manifest_${error.code}',
        'The downloaded Catalog manifest was rejected.',
      );
    } on RemoteCatalogArchiveException catch (error) {
      throw CatalogUpdateException(
        'archive_${error.code}',
        'The downloaded Catalog archive was rejected.',
      );
    } on CatalogInstallException catch (error) {
      throw CatalogUpdateException(
        'install_${error.code}',
        'The downloaded Catalog could not be installed.',
      );
    }
  }

  RemoteCatalogValidationContext _context({
    required String currentAppVersion,
    required int currentDataVersion,
    required int highestAcceptedReleaseSequence,
  }) => RemoteCatalogValidationContext(
    currentAppVersion: currentAppVersion,
    currentDataVersion: currentDataVersion,
    highestAcceptedReleaseSequence: highestAcceptedReleaseSequence,
    allowedHosts: const <String>{GitHubReleaseCatalogSource.initialHost},
  );
}
