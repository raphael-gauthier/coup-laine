import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  final container = ProviderContainer();
  // Fire-and-forget; UI banner will show pending recomputes.
  unawaited(container.read(consistencyCheckProvider).run());
  runApp(UncontrolledProviderScope(
    container: container,
    child: const CoupeLaineApp(),
  ));
}
