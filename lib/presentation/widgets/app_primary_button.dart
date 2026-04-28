import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

/// A primary CTA button with consistent height (56), generous horizontal
/// padding, and Inter 600 weight. Optionally loading — shows a small
/// circular progress in place of the label and disables the press.
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? prefixIcon;
  final VoidCallback? onPress;
  final bool loading;
  final FButtonVariant variant;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPress,
    this.prefixIcon,
    this.loading = false,
    this.variant = FButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.primaryButtonHeight,
      child: FButton(
        variant: variant,
        prefix: prefixIcon == null ? null : Icon(prefixIcon),
        onPress: loading ? null : onPress,
        child: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: FCircularProgress(size: FCircularProgressSizeVariant.sm),
              )
            : Text(label),
      ),
    );
  }
}
