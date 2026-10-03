import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';

/// Widget for uploading comic chapter pages to Cloudinary.
///
/// Shows page thumbnails, upload progress, and handles multi-image selection.
class ComicPageUploadWidget extends ConsumerStatefulWidget {
  const ComicPageUploadWidget({
    super.key,
    required this.pages,
    required this.onPagesChanged,
    required this.uploadedUrls,
    required this.onUploadedUrlsChanged,
    required this.isUploading,
    required this.uploadProgress,
    required this.onUpload,
  });

  final List<File> pages;
  final ValueChanged<List<File>> onPagesChanged;
  final List<String> uploadedUrls;
  final ValueChanged<List<String>> onUploadedUrlsChanged;
  final bool isUploading;
  final double uploadProgress;
  final VoidCallback onUpload;

  @override
  ConsumerState<ComicPageUploadWidget> createState() =>
      _ComicPageUploadWidgetState();
}

class _ComicPageUploadWidgetState extends ConsumerState<ComicPageUploadWidget> {
  final _imagePicker = ImagePicker();

  Future<void> _pickPages() async {
    final pickedFiles = await _imagePicker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFiles.isEmpty) return;

    final newPages = List<File>.from(widget.pages);

    for (final file in pickedFiles) {
      final imageFile = File(file.path);
      final fileSize = await imageFile.length();
      if (fileSize > AppConstants.maxImageSizeBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${file.path.split('/').last} is too large. Maximum: ${AppConstants.maxImageSizeMB} MB.',
              ),
            ),
          );
        }
        continue;
      }
      newPages.add(imageFile);
    }

    widget.onPagesChanged(newPages);
  }

  void _removePage(int index) {
    final newPages = List<File>.from(widget.pages);
    newPages.removeAt(index);
    widget.onPagesChanged(newPages);
  }

  void _removeUploadedPage(int index) {
    final urls = List<String>.from(widget.uploadedUrls)..removeAt(index);
    widget.onUploadedUrlsChanged(urls);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Page thumbnails
        if (widget.pages.isNotEmpty || widget.uploadedUrls.isNotEmpty) ...[
          Text(
            'Chapter pages (${widget.uploadedUrls.length + widget.pages.length})',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.uploadedUrls.length + widget.pages.length,
              itemBuilder: (context, index) {
                final isUploaded = index < widget.uploadedUrls.length;
                final localIndex = index - widget.uploadedUrls.length;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                        child: isUploaded
                            ? Image.network(
                                widget.uploadedUrls[index],
                                width: 80,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox(
                                      width: 80,
                                      height: 120,
                                      child: Center(
                                        child: Icon(Icons.broken_image),
                                      ),
                                    ),
                              )
                            : Image.file(
                                widget.pages[localIndex],
                                width: 80,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: widget.isUploading
                              ? null
                              : () => isUploaded
                                    ? _removeUploadedPage(index)
                                    : _removePage(localIndex),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Page number badge
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull,
                            ),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Add pages button
        if (!widget.isUploading)
          OutlinedButton.icon(
            onPressed: _pickPages,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Add Pages'),
          ),

        // Upload progress
        if (widget.isUploading) ...[
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(value: widget.uploadProgress),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Uploading... ${(widget.uploadProgress * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],

        // Upload button (when new pages selected)
        if (widget.pages.isNotEmpty && !widget.isUploading) ...[
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: widget.onUpload,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Upload New Pages'),
          ),
        ],
      ],
    );
  }
}
