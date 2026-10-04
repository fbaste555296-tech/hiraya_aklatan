import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/chapter_content_model.dart';
import '../../../../data/models/chapter_model.dart';
import '../../../../data/providers/service_providers.dart';
import '../../providers/admin_providers.dart';

/// Form widget for creating or editing a chapter.
class ChapterFormWidget extends ConsumerStatefulWidget {
  const ChapterFormWidget({
    super.key,
    required this.bookId,
    this.existingChapter,
  });

  final String bookId;
  final ChapterModel? existingChapter;

  @override
  ConsumerState<ChapterFormWidget> createState() => _ChapterFormWidgetState();
}

class _ChapterFormWidgetState extends ConsumerState<ChapterFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _imagePicker = ImagePicker();
  final List<_EditableChapterBlock> _contentBlocks = [];
  late TextEditingController _numberController;
  late TextEditingController _priceController;

  DateTime _releaseDate = DateTime.now();
  bool _isEarlyAccess = false;
  bool _isSaving = false;
  double _uploadProgress = 0;
  bool _isLoadingContent = false;
  Object? _contentLoadError;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(
      text: widget.existingChapter?.number.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: widget.existingChapter?.isEarlyAccess == true
          ? widget.existingChapter!.price.toString()
          : '',
    );

    if (widget.existingChapter != null) {
      _titleController.text = widget.existingChapter!.title;
      _releaseDate = widget.existingChapter!.releaseDate;
      _isEarlyAccess = widget.existingChapter!.isEarlyAccess;
      _loadExistingContent();
    } else {
      _contentBlocks.add(_EditableChapterBlock.text());
    }
  }

  Future<void> _loadExistingContent() async {
    setState(() {
      _isLoadingContent = true;
      _contentLoadError = null;
    });
    try {
      final content = await ref
          .read(chapterRepositoryProvider)
          .getChapterContent(widget.existingChapter!.id);
      if (!mounted) return;
      if (content != null) {
        for (final block in content.orderedContent) {
          if (block.type == 'text' && block.text != null) {
            _contentBlocks.add(_EditableChapterBlock.text(block.text!));
          } else if (block.type == 'image' && block.imageUrl != null) {
            _contentBlocks.add(_EditableChapterBlock.image(block.imageUrl!));
          }
        }
      }
      if (_contentBlocks.isEmpty) {
        _contentBlocks.add(_EditableChapterBlock.text());
      }
      setState(() => _isLoadingContent = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _contentLoadError = error;
        _isLoadingContent = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _numberController.dispose();
    _priceController.dispose();
    for (final block in _contentBlocks) {
      block.dispose();
    }
    super.dispose();
  }

  Future<void> _pickReleaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _releaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _releaseDate = picked);
    }
  }

  Future<void> _pickContentImages() async {
    final pickedFiles = await _imagePicker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (pickedFiles.isEmpty) return;

    final newBlocks = <_EditableChapterBlock>[];
    for (final pickedFile in pickedFiles) {
      final file = File(pickedFile.path);
      if (await file.length() > AppConstants.maxImageSizeBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${pickedFile.name} is too large. Maximum: '
                '${AppConstants.maxImageSizeMB} MB.',
              ),
            ),
          );
        }
        continue;
      }
      newBlocks.add(_EditableChapterBlock.imageFile(file));
    }

    if (mounted && newBlocks.isNotEmpty) {
      setState(() => _contentBlocks.addAll(newBlocks));
    }
  }

  void _moveBlock(int index, int offset) {
    final targetIndex = index + offset;
    if (targetIndex < 0 || targetIndex >= _contentBlocks.length) return;
    setState(() {
      final block = _contentBlocks.removeAt(index);
      _contentBlocks.insert(targetIndex, block);
    });
  }

  void _removeBlock(int index) {
    setState(() => _contentBlocks.removeAt(index).dispose());
  }

  Future<void> _uploadPendingImages() async {
    final pendingBlocks = _contentBlocks
        .where((block) => block.imageFile != null)
        .toList();
    if (pendingBlocks.isEmpty) return;

    final cloudinary = ref.read(cloudinaryServiceProvider);
    for (var i = 0; i < pendingBlocks.length; i++) {
      final block = pendingBlocks[i];
      final imageFile = block.imageFile!;
      final url = await cloudinary.uploadImage(
        imageFile,
        AppConstants.cloudinaryComicPagesFolder,
        onProgress: (transferred, totalBytes) {
          if (mounted && totalBytes > 0) {
            setState(() {
              _uploadProgress =
                  (i + transferred / totalBytes) / pendingBlocks.length;
            });
          }
        },
      );
      block.imageUrl = url;
      block.imageFile = null;
      if (mounted) setState(() {});
    }
  }

  Future<void> _saveChapter() async {
    if (_isLoadingContent || _contentLoadError != null) return;
    if (!_formKey.currentState!.validate()) return;

    final hasText = _contentBlocks.any(
      (block) => block.textController?.text.trim().isNotEmpty ?? false,
    );
    final hasImages = _contentBlocks.any(
      (block) => block.imageFile != null || block.imageUrl != null,
    );
    if (!hasText && !hasImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one text section or image.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _uploadProgress = 0;
    });

    try {
      await _uploadPendingImages();
      if (!mounted) return;

      final contentBlocks = <ChapterContentBlock>[
        for (final block in _contentBlocks)
          if (block.textController != null &&
              block.textController!.text.trim().isNotEmpty)
            ChapterContentBlock.text(block.textController!.text.trim())
          else if (block.imageUrl != null)
            ChapterContentBlock.image(block.imageUrl!),
      ];
      final savedHasText = contentBlocks.any((block) => block.type == 'text');
      final savedHasImages = contentBlocks.any(
        (block) => block.type == 'image',
      );

    final number = int.tryParse(_numberController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;

    final chapter = ChapterModel(
      id: widget.existingChapter?.id ?? '',
      bookId: widget.bookId,
      number: number,
      title: _titleController.text.trim(),
      releaseDate: _releaseDate,
      isEarlyAccess: _isEarlyAccess,
      price: price,
      type: savedHasText && savedHasImages
          ? AppConstants.chapterTypeMixed
          : savedHasImages
          ? AppConstants.chapterTypeComic
          : AppConstants.chapterTypeText,
    );

      final chapterRepository = ref.read(chapterRepositoryProvider);

      final chapterId = chapter.id.isEmpty
          ? await chapterRepository.createChapter(widget.bookId, chapter)
          : chapter.id;

      final content = ChapterContentModel(
        chapterId: chapterId,
        bookId: widget.bookId,
        textContent: savedHasText
            ? contentBlocks
                  .where((block) => block.type == 'text')
                  .map((block) => block.text!)
                  .join('\n\n')
            : null,
        pageUrls: savedHasImages
            ? contentBlocks
                  .where((block) => block.type == 'image')
                  .map((block) => block.imageUrl!)
                  .toList()
            : null,
        contentBlocks: contentBlocks,
      );
      await chapterRepository.setChapterContent(content);

      if (chapter.id.isNotEmpty) {
        await chapterRepository.updateChapter(
          widget.bookId,
          chapter.id,
          chapter.toMap(),
        );
      }

      ref.invalidate(adminChaptersProvider(widget.bookId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chapter saved successfully.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingContent) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_contentLoadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load the saved chapter content.'),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: _loadExistingContent,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _numberController,
              label: 'Chapter Number',
              keyboardType: TextInputType.number,
              validator: Validators.chapterNumber,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),

            AppTextField(
              controller: _titleController,
              label: 'Title',
              validator: (value) => Validators.textLength(
                value,
                min: 1,
                max: 200,
                fieldName: 'Title',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),

            InkWell(
              onTap: _pickReleaseDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Release Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_releaseDate.year}-${_releaseDate.month.toString().padLeft(2, '0')}-${_releaseDate.day.toString().padLeft(2, '0')}',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            SwitchListTile(
              title: const Text('Early Access'),
              subtitle: const Text(
                'Enable to require payment or VIP. Free chapters need no price.',
              ),
              value: _isEarlyAccess,
              onChanged: (value) {
                setState(() {
                  _isEarlyAccess = value;
                  if (!value) _priceController.clear();
                });
              },
            ),

            if (_isEarlyAccess) ...[
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _priceController,
                label: 'Price (₱)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.price,
                textInputAction: TextInputAction.next,
              ),
            ],
            const SizedBox(height: AppSpacing.md),

            Text(
              'Chapter Content',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add text sections and images, then use the arrows to arrange '
              'them in reading order.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            for (var index = 0; index < _contentBlocks.length; index++)
              _buildContentBlock(index),
            OutlinedButton.icon(
              onPressed: _isSaving
                  ? null
                  : () => setState(
                      () => _contentBlocks.add(_EditableChapterBlock.text()),
                    ),
              icon: const Icon(Icons.add),
              label: const Text('Add Text Section'),
            ),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _pickContentImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Images'),
            ),
            if (_isSaving && _uploadProgress > 0) ...[
              const SizedBox(height: AppSpacing.md),
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Uploading images... '
                '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),

            AppButton(
              onPressed: _saveChapter,
              text: widget.existingChapter == null
                  ? 'Create Chapter'
                  : 'Save Changes',
              icon: Icons.save,
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentBlock(int index) {
    final block = _contentBlocks[index];
    final isText = block.textController != null;

    return Card(
      key: ObjectKey(block),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(isText ? Icons.article : Icons.image),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${isText ? 'Text Section' : 'Image'} ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Move up',
                  onPressed: _isSaving || index == 0
                      ? null
                      : () => _moveBlock(index, -1),
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  tooltip: 'Move down',
                  onPressed: _isSaving || index == _contentBlocks.length - 1
                      ? null
                      : () => _moveBlock(index, 1),
                  icon: const Icon(Icons.arrow_downward),
                ),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: _isSaving ? null : () => _removeBlock(index),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            if (isText)
              TextField(
                controller: block.textController,
                enabled: !_isSaving,
                minLines: 3,
                maxLines: 15,
                maxLength: 100000,
                decoration: const InputDecoration(
                  hintText: 'Enter this section of the chapter...',
                  border: OutlineInputBorder(),
                ),
              )
            else if (block.imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Image.file(
                  block.imageFile!,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              )
            else if (block.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Image.network(
                  block.imageUrl!,
                  height: 220,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(
                        height: 220,
                        child: Center(child: Icon(Icons.broken_image)),
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EditableChapterBlock {
  _EditableChapterBlock.text([String text = ''])
    : textController = TextEditingController(text: text),
      imageFile = null,
      imageUrl = null;

  _EditableChapterBlock.image(String url)
    : textController = null,
      imageFile = null,
      imageUrl = url;

  _EditableChapterBlock.imageFile(File file)
    : textController = null,
      imageFile = file,
      imageUrl = null;

  final TextEditingController? textController;
  File? imageFile;
  String? imageUrl;

  void dispose() => textController?.dispose();
}
