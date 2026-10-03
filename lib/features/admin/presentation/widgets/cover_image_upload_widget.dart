import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/providers/service_providers.dart';

/// Widget for uploading book cover images to Cloudinary.
class CoverImageUploadWidget extends ConsumerStatefulWidget {
  const CoverImageUploadWidget({
    super.key,
    required this.coverUrl,
    required this.onCoverUploaded,
  });

  final String? coverUrl;
  final ValueChanged<String> onCoverUploaded;

  @override
  ConsumerState<CoverImageUploadWidget> createState() =>
      _CoverImageUploadWidgetState();
}

class _CoverImageUploadWidgetState
    extends ConsumerState<CoverImageUploadWidget> {
  File? _selectedImage;
  bool _isUploading = false;
  double _uploadProgress = 0;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    final file = File(pickedFile.path);

    // Validate file size
    final fileSize = await file.length();
    if (fileSize > AppConstants.maxImageSizeBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Image too large (${fileSize / (1024 * 1024)} MB). Maximum: ${AppConstants.maxImageSizeMB} MB.',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _selectedImage = file);
    await _uploadCover();
  }

  Future<void> _uploadCover() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final cloudinary = ref.read(cloudinaryServiceProvider);
      final url = await cloudinary.uploadImage(
        _selectedImage!,
        AppConstants.cloudinaryCoversFolder,
        onProgress: (transferred, total) {
          if (mounted && total > 0) {
            setState(() => _uploadProgress = transferred / total);
          }
        },
      );

      widget.onCoverUploaded(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _isUploading ? null : _pickImage,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.divider),
            ),
            child: _buildPreview(),
          ),
        ),
        if (_isUploading) ...[
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(value: _uploadProgress),
        ],
      ],
    );
  }

  Widget _buildPreview() {
    if (_selectedImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Image.file(_selectedImage!, fit: BoxFit.cover),
          ),
          if (_isUploading)
            Container(
              color: Colors.black38,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      );
    }

    if (widget.coverUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Image.network(widget.coverUrl!, fit: BoxFit.cover),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_photo_alternate,
            size: 48, color: AppColors.textDisabled),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Tap to upload cover',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
