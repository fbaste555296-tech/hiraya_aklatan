import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Custom button widget with consistent styling
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.isOutlined = false,
    this.isText = false,
    this.icon,
    this.fullWidth = true,
  });

  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool isOutlined;
  final bool isText;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final content = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(text),
            ],
          );

    Widget button;

    if (isText) {
      button = TextButton(
        onPressed: isLoading ? null : onPressed,
        child: content,
      );
    } else if (isOutlined) {
      button = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: content,
      );
    } else {
      button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: content,
      );
    }

    return fullWidth
        ? SizedBox(
            width: double.infinity,
            child: button,
          )
        : button;
  }
}
