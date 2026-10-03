import 'package:intl/intl.dart';

/// Formatting utilities for dates, currency, and numbers
class Formatters {
  Formatters._();

  // Date formatters
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('MMM dd, yyyy h:mm a');
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _shortDateFormat = DateFormat('MM/dd/yyyy');
  static final DateFormat _longDateFormat = DateFormat('MMMM dd, yyyy');
  static final DateFormat _yearMonthFormat = DateFormat('MMMM yyyy');

  // Currency formatter (Philippine Peso)
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₱',
    decimalDigits: 2,
  );

  // Number formatter
  static final NumberFormat _numberFormat = NumberFormat('#,##0.##');

  /// Formats date to "MMM dd, yyyy" (e.g., "Jan 01, 2024")
  static String date(DateTime dateTime) {
    return _dateFormat.format(dateTime);
  }

  /// Formats date and time to "MMM dd, yyyy h:mm a"
  static String dateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  /// Formats time to "h:mm a" (e.g., "3:30 PM")
  static String time(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }

  /// Formats date to "MM/dd/yyyy"
  static String shortDate(DateTime dateTime) {
    return _shortDateFormat.format(dateTime);
  }

  /// Formats date to "MMMM dd, yyyy" (e.g., "January 01, 2024")
  static String longDate(DateTime dateTime) {
    return _longDateFormat.format(dateTime);
  }

  /// Formats date to "MMMM yyyy" (e.g., "January 2024")
  static String yearMonth(DateTime dateTime) {
    return _yearMonthFormat.format(dateTime);
  }

  /// Formats currency with peso sign (e.g., "₱100.00")
  static String currency(num amount) {
    return _currencyFormat.format(amount);
  }

  /// Formats number with thousand separators
  static String number(num value) {
    return _numberFormat.format(value);
  }

  /// Formats relative time (e.g., "2 hours ago", "just now")
  static String relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Generates reference code for payments (HA-YYYYMMDD-XXXX)
  static String generateReferenceCode() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final randomStr = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return 'HA-$dateStr-$randomStr';
  }

  /// Formats file size (bytes to human-readable)
  static String fileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Formats duration (e.g., "5 min read")
  static String readingTime(int wordCount) {
    // Average reading speed: 200 words per minute
    final minutes = (wordCount / 200).ceil();
    return '$minutes min read';
  }
}
