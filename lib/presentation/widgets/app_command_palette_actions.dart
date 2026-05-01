// lib/presentation/widgets/app_command_palette_actions.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/format_minutes.dart';
import '../../state/providers.dart';
import '../clients/clients_list_screen.dart' show clientsAsyncProvider;
import '../tours/tours_list_screen.dart' show toursAsyncProvider;
import 'app_command_palette.dart';

/// Builds palette items and opens [AppCommandPalette] as a bottom sheet.
///
/// Reads providers synchronously (values are typically already cached) and
/// captures [context] in the onSelect closures for navigation.
Future<void> showAppCommandPalette(BuildContext context, WidgetRef ref) {
  final clients =
      ref.read(clientsAsyncProvider).value?.map((r) => r.$1).toList() ?? [];
  final tours = ref.read(toursAsyncProvider).value ?? [];
  final prestations = ref.read(activePrestationsProvider).value ?? [];

  final items = <AppCommandItem>[
    // ── Clients ──────────────────────────────────────────────────────────────
    for (final c in clients)
      AppCommandItem(
        icon: FIcons.user,
        label: c.name,
        subtitle: c.city,
        onSelect: () => context.push('/clients/${c.id}'),
      ),

    // ── Tournées ─────────────────────────────────────────────────────────────
    for (final t in tours)
      AppCommandItem(
        icon: FIcons.route,
        label: 'Tournée du ${DateFormat('d MMM yyyy', 'fr').format(t.plannedDate)}',
        subtitle: t.status.name == 'completed' ? 'Terminée' : 'Planifiée',
        onSelect: () => context.push('/tours/${t.id}'),
      ),

    // ── Prestations actives ───────────────────────────────────────────────────
    for (final p in prestations)
      AppCommandItem(
        icon: FIcons.tag,
        label: p.name,
        subtitle: [
          if (p.priceCents != null) formatEuros(p.priceCents!),
          if (p.minutes != null) formatDuration(p.minutes!),
        ].join(' · '),
        onSelect: () => context.push('/settings/prestations/${p.id}'),
      ),

    // ── Navigation paramètres ─────────────────────────────────────────────────
    AppCommandItem(
      icon: FIcons.tag,
      label: 'Catalogue de prestations',
      onSelect: () => context.go('/settings/prestations'),
    ),
    AppCommandItem(
      icon: FIcons.pawPrint,
      label: 'Espèces & catégories',
      onSelect: () => context.go('/settings/species'),
    ),
    AppCommandItem(
      icon: FIcons.settings,
      label: 'Paramètres',
      onSelect: () => context.go('/settings'),
    ),
  ];

  return AppCommandPalette.show(context, items: items, hint: 'Rechercher…');
}
