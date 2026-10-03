import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../data/providers/service_providers.dart';
import '../../../../data/services/cloudinary_service.dart';

/// Widget for uploading payment receipt images to Cloudinary.
///
/// Shows image preview, upload progress, and validation errors.
class ReceiptUploadWidget extends ConsumerStatefulWidget {
  const ReceiptUploadWidget({
    super.key,
    required this.onUploaded,
  });

  /// Called with the Cloudinary URL when upload succeeds.
  final void Function(String url) onUploaded;

  @override
  ConsumerState<ReceiptUploadWidget> createState() => _ReceiptUploadWidgetState();
}

class _ReceiptUploadWidgetState extends ConsumerState<ReceiptUploadWidget> {
  File? _selectedImage;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _errorMessage;

  final _imagePicker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);

      // Validate file size
      final fileSize = await file.length();
      if (fileSize > AppConstants.maxImageSizeBytes) {
        setState(() {
          _errorMessage =
              'Image too large (${fileSize.toFileSize()}). Maximum: ${AppConstants.maxImageSizeMB} MB.';
        });
        return;
      }

      // Validate file type
      if (!CloudinaryService.instance.isValidImage(file)) {
        setState(() {
          _errorMessage =
              'Invalid file type. Allowed: ${AppConstants.allowedImageExtensions.join(', ')}';
        });
        return;
      }

      setState(() {
        _selectedImage = file;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: ${e.toString()}';
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _errorMessage = null;
    });

    try {
      final cloudinary = ref.read(cloudinaryServiceProvider);
      final url = await cloudinary.uploadImage(
        _selectedImage!,
        AppConstants.cloudinaryProofsFolder,
        onProgress: (transferred, total) {
          if (mounted && total > 0) {
            setState(() => _uploadProgress = transferred / total);
          }
        },
      );

      widget.onUploaded(url);
    } catch (e) {
      setState(() {
        _errorMessage = 'Upload failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _uploadProgress = 0;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image preview or placeholder
        if (_selectedImage != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Image.file(
                  _selectedImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _isUploading ? null : _removeImage,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
              if (_isUploading)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: Colors.black38,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accent,
                    ),
                  ),
                ),
            ],
          )
        else
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppColors.divider,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.receipt_long,
                  size: 48,
                  color: AppColors.textDisabled,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Upload receipt screenshot',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),

        const SizedBox(height: AppSpacing.md),

        // Image source buttons
        if (_selectedImage == null && !_isUploading)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),

        // Upload button
        if (_selectedImage != null && !_isUploading)
          ElevatedButton.icon(
            onPressed: _uploadImage,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Upload Receipt'),
          ),

        // Uploading indicator
        if (_isUploading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: AppSpacing.sm),
                  Text('Uploading...'),
                ],
              ),
            ),
          ),

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}
