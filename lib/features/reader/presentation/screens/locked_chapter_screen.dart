import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../data/models/chapter_model.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../providers/reader_providers.dart';

/// Screen shown when a chapter is locked.
///
/// Displays the chapter info, price, and unlock options.
class LockedChapterScreen extends ConsumerWidget {
  const LockedChapterScreen({
    super.key,
    required this.bookId,
    required this.chapter,
  });

  final String bookId;
  final ChapterModel chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(firebaseUserProvider).value?.uid ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Chapter Locked')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock,
                  size: 48,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Chapter title
              Text(
                chapter.title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Chapter number
              Text(
                'Chapter ${chapter.number}',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Price
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  Formatters.currency(chapter.price),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              Text(
                'Unlock this chapter to start reading',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),

              OutlinedButton.icon(
                onPressed: () => ref.invalidate(
                  chapterAccessProvider((
                    bookId: bookId,
                    chapterId: chapter.id,
                    userId: userId,
                  )),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Already approved? Check access'),
              ),
              const SizedBox(height: AppSpacing.md),

              // Unlock button
              AppButton(
                onPressed: () => context.push(
                  RouteNames.getPaymentInstructionsRoute(
                    AppConstants.paymentTypeChapter,
                    chapter.id,
                    bookId: bookId,
                  ),
                ),
                text: 'Unlock Chapter',
                icon: Icons.lock_open,
              ),
              const SizedBox(height: AppSpacing.md),

              // VIP button
              AppButton(
                onPressed: () => context.go(RouteNames.vip),
                text: 'Go VIP',
                icon: Icons.star,
                isOutlined: true,
              ),
              const SizedBox(height: AppSpacing.sm),

              Text(
                'VIP unlocks all early-access chapters',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
