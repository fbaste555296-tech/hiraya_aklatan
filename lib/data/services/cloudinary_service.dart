import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../../core/config/env_config.dart';
import '../../core/config/app_constants.dart';

/// Cloudinary service for image uploads and optimization
/// Uses UNSIGNED uploads only (no API secret in app)
class CloudinaryService {
  CloudinaryService._();

  static final CloudinaryService instance = CloudinaryService._();

  late final CloudinaryPublic _cloudinary;
  bool _initialized = false;

  /// Initializes the Cloudinary service
  void initialize() {
    if (_initialized) return;

    _cloudinary = CloudinaryPublic(
      EnvConfig.cloudinaryCloudName,
      EnvConfig.cloudinaryUploadPreset,
      cache: false,
    );

    _initialized = true;
  }

  /// Uploads an image to Cloudinary
  /// Returns the secure URL of the uploaded image
  Future<String> uploadImage(
    File file,
    String folder, {
    void Function(int transferred, int total)? onProgress,
  }) async {
    if (!_initialized) {
      throw Exception('CloudinaryService not initialized. Call initialize() first.');
    }

    // Validate file size
    final fileSize = await file.length();
    if (fileSize > AppConstants.maxImageSizeBytes) {
      throw Exception(
        'File size (${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB) '
        'exceeds maximum allowed size (${AppConstants.maxImageSizeMB} MB)',
      );
    }

    // Validate file extension
    final extension = file.path.split('.').last.toLowerCase();
    if (!AppConstants.allowedImageExtensions.contains(extension)) {
      throw Exception(
        'Invalid file type. Allowed types: ${AppConstants.allowedImageExtensions.join(", ")}',
      );
    }

    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: folder,
          resourceType: CloudinaryResourceType.Image,
        ),
        onProgress: onProgress,
      );

      return response.secureUrl;
    } catch (e) {
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  /// Uploads multiple images
  Future<List<String>> uploadMultipleImages(
    List<File> files,
    String folder, {
    void Function(int currentIndex, int total)? onProgressPerFile,
  }) async {
    final urls = <String>[];

    for (var i = 0; i < files.length; i++) {
      onProgressPerFile?.call(i + 1, files.length);
      final url = await uploadImage(files[i], folder);
      urls.add(url);
    }

    return urls;
  }

  /// Builds an optimized image URL with transformations
  /// Useful for thumbnails and responsive images
  String getOptimizedUrl(
    String imageUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    if (!imageUrl.contains('cloudinary.com')) {
      return imageUrl;
    }

    // Parse the Cloudinary URL
    final uri = Uri.parse(imageUrl);
    final pathSegments = uri.pathSegments;

    // Find the upload segment index
    final uploadIndex = pathSegments.indexOf('upload');
    if (uploadIndex == -1) return imageUrl;

    // Build transformation string
    final transformations = <String>[];
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    transformations.add('q_$quality');
    transformations.add('f_$format');

    // Insert transformations after 'upload/'
    final newPathSegments = List<String>.from(pathSegments);
    newPathSegments.insert(uploadIndex + 1, transformations.join(','));

    // Rebuild URL
    final newUri = uri.replace(pathSegments: newPathSegments);
    return newUri.toString();
  }

  /// Gets a thumbnail URL (optimized for small display)
  String getThumbnailUrl(String imageUrl, {int width = 200}) {
    return getOptimizedUrl(
      imageUrl,
      width: width,
      quality: 'auto',
      format: 'auto',
    );
  }

  /// Gets a cover image URL (optimized for book covers)
  String getCoverUrl(String imageUrl, {int width = 400}) {
    return getOptimizedUrl(
      imageUrl,
      width: width,
      quality: 'auto',
      format: 'auto',
    );
  }

  /// Validates if a file is a valid image
  bool isValidImage(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return AppConstants.allowedImageExtensions.contains(extension);
  }

  /// Validates if file size is within limits
  Future<bool> isValidFileSize(File file) async {
    final fileSize = await file.length();
    return fileSize <= AppConstants.maxImageSizeBytes;
  }

  /// Gets human-readable file size
  Future<String> getFileSize(File file) async {
    final bytes = await file.length();
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
