import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/settings_repository.dart';
import '../../state/providers.dart';
import 'backup_service.dart';

class BackupScheduler with WidgetsBindingObserver {
  final BackupService _service;
  final SettingsRepository _settings;
  final Ref _ref;

  BackupScheduler(this._service, this._settings, this._ref);

  void start() {
    WidgetsBinding.instance.addObserver(this);
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_maybeRunBackup());
    }
  }

  Future<void> _maybeRunBackup() async {
    try {
      final cloudOptIn = _ref.read(isCloudOptedInProvider);
      final settings = await _settings.read();
      final lastBackupAt = settings?.lastBackupAt;
      if (!shouldRunAutoBackup(
        now: DateTime.now(),
        cloudOptIn: cloudOptIn,
        lastBackupAt: lastBackupAt,
        hasNetwork: true,
      )) {
        return;
      }
      await _service.runBackup();
    } catch (e, st) {
      debugPrint('BackupScheduler: auto-backup failed: $e\n$st');
    }
  }
}
