import 'package:flutter/material.dart' show Material, MaterialType, Slider;
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_tokens.dart';
import '../../state/proximity_controller.dart';
import '../../state/providers.dart';
import '../../state/tour_draft_controller.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';

class TourOptimizedConfigScreen extends ConsumerStatefulWidget {
  const TourOptimizedConfigScreen({super.key});

  @override
  ConsumerState<TourOptimizedConfigScreen> createState() =>
      _TourOptimizedConfigScreenState();
}

class _TourOptimizedConfigScreenState
    extends ConsumerState<TourOptimizedConfigScreen> {
  String? _commune;
  int _targetMinutes = 8 * 60;
  bool _proposing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tourSelectionProvider.notifier).clear();
    });
  }

  Future<void> _propose() async {
    if (_commune == null) return;
    setState(() => _proposing = true);
    try {
      final proposal = await ref.read(optimizedProposalProvider(
        OptimizedRequest(
            communeName: _commune!, targetMinutes: _targetMinutes),
      ).future);
      if (!mounted) return;
      if (proposal.selectedClientIds.isEmpty) {
        setState(() => _proposing = false);
        return;
      }
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      ref.read(tourDraftInputProvider.notifier).state = TourDraftInput(
        pivotId: null,
        selectedIds: proposal.selectedClientIds,
        plannedDate: tomorrow,
        startTimeMinutes: 8 * 60,
        overrideOrder: proposal.selectedClientIds, // already optimal
      );
      final notifier = ref.read(tourSelectionProvider.notifier);
      notifier.clear();
      for (final id in proposal.selectedClientIds) {
        notifier.toggle(id);
      }
      context.push('/tours/draft');
    } finally {
      if (mounted) setState(() => _proposing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final communesAsync = ref.watch(waitingCommunesProvider);
    return SafeArea(
      child: FScaffold(
        header: FHeader.nested(title: Text(l.optimizedConfigTitle)),
        footer: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.colors.border)),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: AppPrimaryButton(
            label: l.optimizedConfigPropose,
            onPress: (_commune == null || _proposing) ? null : _propose,
            prefixIcon: FIcons.route,
          ),
        ),
        child: communesAsync.when(
          loading: () => const Center(child: FCircularProgress()),
          error: (e, _) => Center(child: Text('$e')),
          data: (communes) {
            if (communes.isEmpty) {
              return AppEmptyState(
                illustrationAsset: 'assets/illustrations/empty-clients.svg',
                title: l.optimizedConfigEmptyTitle,
                body: l.optimizedConfigEmptyBody,
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
              children: [
                AppSectionCard(
                  icon: FIcons.mapPin,
                  title: l.optimizedConfigCommuneTitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final c in communes)
                        FTile(
                          title: Text(c.name),
                          details: Text(
                              l.optimizedConfigCommuneOptionFmt(c.name, c.count)),
                          suffix: _commune == c.name
                              ? Icon(FIcons.check,
                                  color: theme.colors.primary, size: 18)
                              : null,
                          onPress: () =>
                              setState(() => _commune = c.name),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppSectionCard(
                  icon: FIcons.clock,
                  title: l.optimizedConfigDurationTitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${(_targetMinutes / 60).toStringAsFixed(1)} h',
                        style: theme.typography.xl2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colors.foreground,
                        ),
                      ),
                      Material(
                        type: MaterialType.transparency,
                        child: Slider(
                          min: 5 * 60,
                          max: 10 * 60,
                          divisions: 10, // 30 min steps
                          value: _targetMinutes.toDouble(),
                          label: '${(_targetMinutes / 60).toStringAsFixed(1)} h',
                          onChanged: (v) =>
                              setState(() => _targetMinutes = v.round()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
