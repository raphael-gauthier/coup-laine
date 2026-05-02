import 'dart:typed_data';

import 'package:coup_laine/domain/models/backup_meta.dart';
import 'package:coup_laine/infra/cloud/backups_repository.dart';

/// In-memory fake of [BackupsRepository] for orchestration tests.
///
/// Modélise une RLS naïve par `userId` (passe via [setUserId]). Le contenu
/// gzippé est stocké tel quel dans [_storage] et restitué par [download].
/// Les hooks `throwOnUpload` / `throwOnDelete` permettent de simuler des
/// échecs réseau / Storage.
class FakeBackupsRepository implements BackupsRepository {
  final List<BackupMeta> _backups = [];
  final Map<String, Uint8List> _storage = {};
  int _nextId = 1;
  String _userId = 'test-user';

  // Compteur incrémental pour garantir un createdAt strictement croissant
  // entre deux appels successifs à create() — DateTime.now() peut renvoyer
  // la même valeur sur Windows à la milliseconde près.
  int _createCounter = 0;

  /// Si non-null, force le `createdAt` du prochain `create()`. Utile pour
  /// les tests de rotation qui veulent un ordre déterministe.
  DateTime? nextCreatedAt;

  /// Si vrai, le prochain `create()` lance un StateError au lieu d'écrire.
  bool throwOnUpload = false;

  /// Si vrai, le prochain `delete()` lance un StateError.
  bool throwOnDelete = false;

  void setUserId(String id) => _userId = id;

  /// Vue lecture seule (toutes lignes confondues, indépendamment du userId).
  List<BackupMeta> get all => List.unmodifiable(_backups);

  /// Bytes stockés pour un path donné, pour les assertions de tests.
  Uint8List? bytesAt(String path) => _storage[path];

  @override
  Future<List<BackupMeta>> listForCurrentUser() async {
    final mine = _backups.where((b) => b.userId == _userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine;
  }

  @override
  Future<int> countForCurrentUser() async {
    return _backups.where((b) => b.userId == _userId).length;
  }

  @override
  Future<BackupMeta> create({
    required Uint8List gzippedBytes,
    required int schemaVersion,
  }) async {
    if (throwOnUpload) throw StateError('simulated upload failure');
    final timestamp = nextCreatedAt ??
        DateTime.now()
            .toUtc()
            .add(Duration(microseconds: _createCounter++));
    nextCreatedAt = null;
    final iso = timestamp.toIso8601String().replaceAll(':', '-');
    final id = _nextId++;
    final path = '$_userId/$iso-${id.toString().padLeft(3, '0')}.json.gz';
    _storage[path] = gzippedBytes;
    final meta = BackupMeta(
      id: '$id',
      userId: _userId,
      storagePath: path,
      createdAt: timestamp,
      schemaVersion: schemaVersion,
      sizeBytes: gzippedBytes.length,
    );
    _backups.add(meta);
    return meta;
  }

  @override
  Future<Uint8List> download(String storagePath) async {
    final bytes = _storage[storagePath];
    if (bytes == null) {
      throw StateError('No such backup: $storagePath');
    }
    return bytes;
  }

  @override
  Future<void> delete(BackupMeta meta) async {
    if (throwOnDelete) throw StateError('simulated delete failure');
    _storage.remove(meta.storagePath);
    _backups.removeWhere((b) => b.id == meta.id);
  }
}
