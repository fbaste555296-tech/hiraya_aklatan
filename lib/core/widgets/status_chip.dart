import 'package:flutter/material.dart';
import '../config/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Status chip widget for displaying payment and other statuses
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    this.showIcon = true,
  });

  final String status;
  final bool showIcon;

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case AppConstants.paymentStatusApproved:
        return AppColors.statusApproved;
      case AppConstants.paymentStatusPending:
        return AppColors.statusPending;
      case AppConstants.paymentStatusRejected:
        return AppColors.statusRejected;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon() {
    switch (status.toLowerCase()) {
      case AppConstants.paymentStatusApproved:
        return Icons.check_circle;
      case AppConstants.paymentStatusPending:
        return Icons.schedule;
      case AppConstants.paymentStatusRejected:
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusLabel() {
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _getStatusIcon(),
              size: 16,
              color: color,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            _getStatusLabel(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
