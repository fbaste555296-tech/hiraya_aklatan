import 'package:flutter/material.dart';

import '../config/app_constants.dart';
import '../../data/models/chapter_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/formatters.dart';

/// List tile for a chapter in the book details screen.
///
/// Shows chapter number, title, release date, and a status indicator
/// (Free, Early Access with price, or Locked).
class ChapterListTile extends StatelessWidget {
  const ChapterListTile({
    super.key,
    required this.chapter,
    this.onTap,
  });

  final ChapterModel chapter;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Chapter number circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${chapter.number}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Chapter info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.title,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(),
                          size: 14,
                          color: _getStatusColor(),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _getStatusLabel(),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: _getStatusColor(),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          Formatters.date(chapter.releaseDate),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Trailing icon
              Icon(
                _getTrailingIcon(),
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (chapter.isFree) return AppColors.statusApproved;
    if (chapter.isEarlyAccess) return AppColors.statusPending;
    return AppColors.textSecondary;
  }

  IconData _getStatusIcon() {
    if (chapter.isFree) return Icons.lock_open;
    if (chapter.isEarlyAccess) return Icons.lock_clock;
    return Icons.lock;
  }

  IconData _getTrailingIcon() {
    if (chapter.isFree) return Icons.arrow_forward_ios;
    return Icons.chevron_right;
  }

  String _getStatusLabel() {
    if (chapter.isFree) return 'Free';
    if (chapter.isEarlyAccess) {
      return '${AppConstants.chapterTypeText == chapter.type ? "Early Access" : "Comic"} - ${Formatters.currency(chapter.price)}';
    }
    return 'Locked';
  }
}
