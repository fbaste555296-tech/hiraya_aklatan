import 'package:flutter/material.dart';

/// Extension methods for common operations

// String extensions
extension StringExtensions on String {
  /// Capitalizes first letter of string
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalizes first letter of each word
  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Checks if string is a valid email
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Truncates string with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }

  /// Removes all whitespace
  String removeWhitespace() {
    return replaceAll(RegExp(r'\s+'), '');
  }
}

// DateTime extensions
extension DateTimeExtensions on DateTime {
  /// Checks if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Checks if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Checks if date is in the future
  bool get isFuture {
    return isAfter(DateTime.now());
  }

  /// Checks if date is in the past
  bool get isPast {
    return isBefore(DateTime.now());
  }

  /// Checks if VIP expiry is still active
  bool get isVipActive {
    return isAfter(DateTime.now());
  }

  /// Gets the start of day (00:00:00)
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// Gets the end of day (23:59:59)
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59);
  }

  /// Adds months to the date
  DateTime addMonths(int months) {
    final totalMonths = (year * 12 + month - 1) + months;
    final newYear = totalMonths ~/ 12;
    final newMonth = (totalMonths % 12) + 1;
    return DateTime(newYear, newMonth, day, hour, minute, second);
  }
}

// BuildContext extensions
extension BuildContextExtensions on BuildContext {
  /// Gets the theme
  ThemeData get theme => Theme.of(this);

  /// Gets the text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Gets the color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Gets the media query
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Gets screen size
  Size get screenSize => mediaQuery.size;

  /// Gets screen width
  double get screenWidth => screenSize.width;

  /// Gets screen height
  double get screenHeight => screenSize.height;

  /// Checks if device is in dark mode
  bool get isDarkMode => mediaQuery.platformBrightness == Brightness.dark;

  /// Shows a snackbar
  void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
      ),
    );
  }

  /// Shows an error snackbar
  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Shows a success snackbar
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Hides the keyboard
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }

  /// Checks if keyboard is visible
  bool get isKeyboardVisible => mediaQuery.viewInsets.bottom > 0;
}

// List extensions
extension ListExtensions<T> on List<T> {
  /// Safely gets element at index or returns null
  T? getOrNull(int index) {
    if (index >= 0 && index < length) {
      return this[index];
    }
    return null;
  }

  /// Checks if list is null or empty
  bool get isNullOrEmpty => isEmpty;

  /// Checks if list is not null and not empty
  bool get isNotNullOrEmpty => isNotEmpty;
}

// Num extensions
extension NumExtensions on num {
  /// Converts number to currency format
  String toCurrency() {
    return '₱${toStringAsFixed(2)}';
  }

  /// Converts bytes to human-readable size
  String toFileSize() {
    if (this < 1024) {
      return '$this B';
    } else if (this < 1024 * 1024) {
      return '${(this / 1024).toStringAsFixed(1)} KB';
    } else if (this < 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
