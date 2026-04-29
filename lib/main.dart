import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Hide the Android navigation bar (3 buttons) — swipe up from the bottom
  // edge reveals it temporarily as a transparent overlay, then it re-hides.
  // The status bar (top) stays visible.
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [SystemUiOverlay.top],
  );
  await Env.load();
  final container = ProviderContainer();
  // Fire-and-forget; UI banner will show pending recomputes.
  unawaited(container.read(consistencyCheckProvider).run());
  runApp(UncontrolledProviderScope(
    container: container,
    child: const CoupeLaineApp(),
  ));
}
