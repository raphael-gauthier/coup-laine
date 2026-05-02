import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/backup_meta.dart';

/// Interface des opérations cloud sur les backups (index DB + Storage).
/// Permet de fournir une fake en mémoire pour les tests sans avoir
/// besoin d'instancier un client Supabase.
abstract class BackupsRepository {
  /// Liste les backups du user courant, triés par `created_at desc`.
  Future<List<BackupMeta>> listForCurrentUser();

  /// Compte les backups du user courant.
  Future<int> countForCurrentUser();

  /// Upload un blob gzippé vers Storage et insère la ligne d'index.
  /// Retourne la `BackupMeta` créée.
  Future<BackupMeta> create({
    required Uint8List gzippedBytes,
    required int schemaVersion,
  });

  /// Télécharge le contenu d'un backup. Retourne les bytes gzippés.
  Future<Uint8List> download(String storagePath);

  /// Supprime une ligne d'index ET le fichier Storage associé.
  Future<void> delete(BackupMeta meta);
}

/// Implémentation Supabase de [BackupsRepository].
class BackupsRepositoryImpl implements BackupsRepository {
  static const String _bucketName = 'backups';
  static const String _tableName = 'backups';

  final SupabaseClient _supabase;

  BackupsRepositoryImpl(this._supabase);

  @override
  Future<List<BackupMeta>> listForCurrentUser() async {
    final userId = _requireUserId();
    final rows = await _supabase
        .from(_tableName)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return [for (final r in rows as List) _toDomain(r as Map<String, dynamic>)];
  }

  @override
  Future<int> countForCurrentUser() async {
    final userId = _requireUserId();
    final rows = await _supabase
        .from(_tableName)
        .select('id')
        .eq('user_id', userId);
    return (rows as List).length;
  }

  @override
  Future<BackupMeta> create({
    required Uint8List gzippedBytes,
    required int schemaVersion,
  }) async {
    final userId = _requireUserId();
    final timestamp = DateTime.now().toUtc();
    final iso = timestamp.toIso8601String().replaceAll(':', '-');
    // Suffixe hex aléatoire (Random.secure) entre timestamp et .json.gz pour
    // éviter une collision théorique en Phase 2 multi-device (deux uploads
    // à la même ms). Le suffixe est dans le nom de fichier — la RLS Storage
    // sur `(storage.foldername(name))[1]` (= userId) reste inchangée.
    final suffix = _randomSuffix(6);
    final storagePath = '$userId/$iso-$suffix.json.gz';

    await _supabase.storage.from(_bucketName).uploadBinary(
          storagePath,
          gzippedBytes,
          fileOptions: const FileOptions(
            contentType: 'application/gzip',
            upsert: false,
          ),
        );

    final inserted = await _supabase
        .from(_tableName)
        .insert({
          'user_id': userId,
          'storage_path': storagePath,
          'schema_version': schemaVersion,
          'size_bytes': gzippedBytes.length,
        })
        .select()
        .single();

    return _toDomain(inserted);
  }

  @override
  Future<Uint8List> download(String storagePath) async {
    return _supabase.storage.from(_bucketName).download(storagePath);
  }

  /// Supprime une ligne d'index ET le fichier Storage associé.
  /// Best-effort : si la suppression Storage échoue mais la row existe
  /// encore, on la supprime quand même pour ne pas laisser d'incohérence.
  @override
  Future<void> delete(BackupMeta meta) async {
    try {
      await _supabase.storage.from(_bucketName).remove([meta.storagePath]);
    } catch (_) {
      // Continue malgré l'erreur — l'orphelin Storage sera nettoyé
      // manuellement si besoin.
    }
    await _supabase.from(_tableName).delete().eq('id', meta.id);
  }

  String _randomSuffix(int chars) {
    const alphabet = '0123456789abcdef';
    final rng = Random.secure();
    return String.fromCharCodes(List.generate(
      chars,
      (_) => alphabet.codeUnitAt(rng.nextInt(alphabet.length)),
    ));
  }

  String _requireUserId() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No active session — cannot access backups');
    }
    return userId;
  }

  BackupMeta _toDomain(Map<String, dynamic> row) {
    return BackupMeta(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      storagePath: row['storage_path'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      schemaVersion: row['schema_version'] as int,
      sizeBytes: row['size_bytes'] as int,
    );
  }
}
