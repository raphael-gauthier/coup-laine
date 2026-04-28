import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

class AppEmptyState extends StatelessWidget {
  final String illustrationAsset;
  final String title;
  final String body;
  final Widget? action;
  final double illustrationHeight;

  const AppEmptyState({
    super.key,
    required this.illustrationAsset,
    required this.title,
    required this.body,
    this.action,
    this.illustrationHeight = 160,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxl + AppSpacing.md, // 64
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            illustrationAsset,
            height: illustrationHeight,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.typography.xl2.copyWith(
              color: theme.colors.foreground,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.typography.md.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.xl),
            action!,
          ],
        ],
      ),
    );
  }
}
