class BackupMeta {
  final String id;
  final String userId;
  final String storagePath;
  final DateTime createdAt;
  final int schemaVersion;
  final int sizeBytes;

  const BackupMeta({
    required this.id,
    required this.userId,
    required this.storagePath,
    required this.createdAt,
    required this.schemaVersion,
    required this.sizeBytes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupMeta &&
          other.id == id &&
          other.userId == userId &&
          other.storagePath == storagePath &&
          other.createdAt == createdAt &&
          other.schemaVersion == schemaVersion &&
          other.sizeBytes == sizeBytes;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        storagePath,
        createdAt,
        schemaVersion,
        sizeBytes,
      );
}
