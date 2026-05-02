import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  // Si pas de session existante (premier lancement, ou sign-out),
  // ouvrir une session anonyme pour permettre les appels à
  // l'Edge Function ors-proxy. Cf. spec §3.1, §6.4.
  final supabase = Supabase.instance.client;
  if (supabase.auth.currentSession == null) {
    try {
      await supabase.auth.signInAnonymously();
    } catch (e) {
      // Si l'anonymous sign-in échoue (réseau hors-ligne au premier lancement,
      // ou config Supabase qui désactive ce mode), on poursuit quand même —
      // l'app reste fonctionnelle en local, ORS échouera et tombera sur
      // le fallback straight-line existant.
      debugPrint('Anonymous sign-in failed: $e');
    }
  }

  final container = ProviderContainer();
  // Fire-and-forget; UI banner will show pending recomputes.
  unawaited(container.read(consistencyCheckProvider).run());
  runApp(UncontrolledProviderScope(
    container: container,
    child: const CoupeLaineApp(),
  ));
}
