import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration wrapper for accessing .env variables
class EnvConfig {
  EnvConfig._();

  /// Initializes the environment configuration
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
  }

  /// Gets the Cloudinary cloud name
  static String get cloudinaryCloudName {
    final value = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    if (value == null || value.isEmpty) {
      throw Exception(
        'CLOUDINARY_CLOUD_NAME not found in .env file. '
        'Please configure your .env file.',
      );
    }
    return value;
  }

  /// Gets the Cloudinary upload preset
  static String get cloudinaryUploadPreset {
    final value = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];
    if (value == null || value.isEmpty) {
      throw Exception(
        'CLOUDINARY_UPLOAD_PRESET not found in .env file. '
        'Please configure your .env file.',
      );
    }
    return value;
  }

  /// Checks if environment is configured
  static bool get isConfigured {
    try {
      return cloudinaryCloudName.isNotEmpty &&
          cloudinaryUploadPreset.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
