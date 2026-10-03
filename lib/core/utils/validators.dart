/// Input validation utilities
class Validators {
  Validators._();

  /// Validates email format
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validates password strength
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }

  /// Validates password confirmation
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  /// Validates required field
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates name (at least 2 characters, letters and spaces)
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Name can only contain letters and spaces';
    }
    
    return null;
  }

  /// Validates positive number
  static String? positiveNumber(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    
    if (number <= 0) {
      return '$fieldName must be greater than zero';
    }
    
    return null;
  }

  /// Validates price format
  static String? price(String? value) {
    return positiveNumber(value, fieldName: 'Price');
  }

  /// Validates reference number format
  static String? referenceNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Reference number is required';
    }
    
    if (value.trim().length < 5) {
      return 'Please enter a valid reference number';
    }
    
    return null;
  }

  /// Validates chapter number
  static String? chapterNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Chapter number is required';
    }
    
    final number = int.tryParse(value);
    if (number == null || number < 1) {
      return 'Please enter a valid chapter number (1 or greater)';
    }
    
    return null;
  }

  /// Validates URL format
  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'URL is required';
    }
    
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    
    if (!urlRegex.hasMatch(value.trim())) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }

  /// Validates text length with min and max
  static String? textLength(
    String? value, {
    required int min,
    required int max,
    String fieldName = 'Text',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final length = value.trim().length;
    
    if (length < min) {
      return '$fieldName must be at least $min characters';
    }
    
    if (length > max) {
      return '$fieldName must not exceed $max characters';
    }
    
    return null;
  }
}
