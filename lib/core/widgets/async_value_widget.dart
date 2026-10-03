// lib/core/widgets/async_value_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error_banner.dart';
import 'loading_view.dart';

/// A widget that renders different UI based on an [AsyncValue] state.
///
/// Provides a consistent way to handle loading, error, and data states
/// across the application without repeating boilerplate.
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget Function()? loading;
  final Widget Function(Object error, StackTrace stack)? error;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: loading ?? () => const LoadingView(message: 'Loading...'),
      error: error ??
          (Object err, StackTrace stack) {
            return ErrorBanner(
              message: 'Error: ${err.toString()}',
              onRetry: () {},
            );
          },
      data: data,
    );
  }
}

/// A widget that renders different UI based on an [AsyncValue] state,
/// with a builder that receives the [WidgetRef] for interactive error handling.
class AsyncValueConsumer<T> extends ConsumerWidget {
  const AsyncValueConsumer({
    super.key,
    required this.value,
    required this.builder,
    this.loading,
    this.error,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext, WidgetRef, T data) builder;
  final Widget Function()? loading;
  final Widget Function(BuildContext, WidgetRef, Object error, StackTrace stack)? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget Function(Object, StackTrace) defaultError =
        (Object err, StackTrace stack) => ErrorBanner(
              message: 'Error: ${err.toString()}',
              onRetry: () {},
            );

    return value.when(
      loading: loading ?? () => const LoadingView(message: 'Loading...'),
      error: error != null
          ? (Object err, StackTrace stack) => error!(context, ref, err, stack)
          : defaultError,
      data: (data) => builder(context, ref, data),
    );
  }
}