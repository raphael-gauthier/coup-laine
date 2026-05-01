import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

class AppStepper extends StatelessWidget {
  final int currentIndex;
  final List<String> labels;
  const AppStepper({
    super.key,
    required this.currentIndex,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: i <= currentIndex ? theme.colors.primary : null,
                      shape: BoxShape.circle,
                      border: i <= currentIndex
                          ? null
                          : Border.all(color: theme.colors.border, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: theme.typography.sm.copyWith(
                        color: i <= currentIndex
                            ? theme.colors.primaryForeground
                            : theme.colors.mutedForeground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: theme.typography.xs.copyWith(
                      color: i == currentIndex
                          ? theme.colors.foreground
                          : theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            if (i < labels.length - 1)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: SizedBox(
                  width: 24,
                  child: Container(
                    height: AppSizes.hairlineBorder,
                    color: i < currentIndex
                        ? theme.colors.primary
                        : theme.colors.border,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
