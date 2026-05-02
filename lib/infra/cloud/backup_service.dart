import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/cloud/gzip_codec.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/models/backup_meta.dart';
import '../services/json_export_service.dart';
import 'backups_repository.dart';

/// Pure helper — extrait pour testabilité.
///
/// Renvoie `true` ssi un auto-backup doit être déclenché à `now`.
/// - cloudOptIn : session non-anonyme active.
/// - lastBackupAt : `null` si jamais sauvegardé.
/// - hasNetwork : best-effort (cf. note dans BackupScheduler).
bool shouldRunAutoBackup({
  required DateTime now,
  required bool cloudOptIn,
  required DateTime? lastBackupAt,
  required bool hasNetwork,
}) {
  if (!cloudOptIn || !hasNetwork) return false;
  if (lastBackupAt == null) return true;
  return now.difference(lastBackupAt) >= const Duration(hours: 24);
}

class BackupService {
  static const int _historyWindow = 3;

  final BackupsRepository _repo;
  final JsonExportService _exporter;
  final SettingsRepository _settings;

  bool _inProgress = false;

  BackupService({
    required BackupsRepository repo,
    required JsonExportService exporter,
    required SettingsRepository settings,
  })  : _repo = repo,
        _exporter = exporter,
        _settings = settings;

  /// Crée un snapshot de la base, le compresse, l'upload et fait
  /// la rotation des anciens. Idempotent : un appel concurrent retourne
  /// immédiatement sans rien faire.
  Future<BackupMeta?> runBackup() async {
    if (_inProgress) {
      debugPrint('BackupService.runBackup: already in progress, skipping');
      return null;
    }
    _inProgress = true;
    try {
      final json = await _exporter.exportToJsonString();
      final compressed = gzipString(json);
      final created = await _repo.create(
        gzippedBytes: compressed,
        schemaVersion: JsonExportService.schemaVersion,
      );
      await _settings.setLastBackupAt(DateTime.now());
      await _rotate();
      return created;
    } finally {
      _inProgress = false;
    }
  }

  /// Liste les backups disponibles pour le user courant.
  Future<List<BackupMeta>> listAvailable() {
    return _repo.listForCurrentUser();
  }

  /// Restaure un backup donné : download → gunzip → import.
  /// Lance [JsonImportException] si schema futur, ou autre erreur.
  Future<void> restore(BackupMeta meta) async {
    final compressed = await _repo.download(meta.storagePath);
    final json = gunzipString(compressed);
    await _exporter.importFromJsonString(json);
    // On NE met PAS à jour lastBackupAt — il reflète la date du
    // dernier backup, pas du restore.
  }

  /// Si le user vient de devenir non-anonyme et n'a aucun backup sur
  /// le compte cloud, push automatiquement l'état local. Sinon, le
  /// caller (UI) est responsable d'afficher la modal de choix.
  /// Retourne `true` ssi un push automatique a été fait.
  Future<bool> resolveInitialStateAfterOptIn() async {
    final count = await _repo.countForCurrentUser();
    if (count == 0) {
      await runBackup();
      return true;
    }
    return false;
  }

  Future<void> _rotate() async {
    final all = await _repo.listForCurrentUser();
    if (all.length <= _historyWindow) return;
    final toDelete = all.sublist(_historyWindow);
    for (final old in toDelete) {
      await _repo.delete(old);
    }
  }
}
