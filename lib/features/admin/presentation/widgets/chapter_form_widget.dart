import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/chapter_content_model.dart';
import '../../../../data/models/chapter_model.dart';
import '../../../../data/providers/service_providers.dart';
import 'comic_page_upload_widget.dart';

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
  final _textContentController = TextEditingController();
  late TextEditingController _numberController;
  late TextEditingController _priceController;

  DateTime _releaseDate = DateTime.now();
  bool _isEarlyAccess = false;
  String _type = AppConstants.chapterTypeText;
  List<File> _comicPages = [];
  final List<String> _uploadedPageUrls = [];
  bool _isUploadingPages = false;
  double _pageUploadProgress = 0;
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
      _type = widget.existingChapter!.type;
      _loadExistingContent();
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
        _textContentController.text = content.textContent ?? '';
        _uploadedPageUrls
          ..clear()
          ..addAll(content.pageUrls ?? const []);
        if (content.isComic) {
          _type = AppConstants.chapterTypeComic;
        } else if (content.isText) {
          _type = AppConstants.chapterTypeText;
        }
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
    _textContentController.dispose();
    _numberController.dispose();
    _priceController.dispose();
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

  Future<void> _uploadComicPages() async {
    if (_comicPages.isEmpty) return;

    setState(() {
      _isUploadingPages = true;
      _pageUploadProgress = 0;
    });

    try {
      final cloudinary = ref.read(cloudinaryServiceProvider);
      final total = _comicPages.length;

      final uploadedUrls = <String>[];
      for (var i = 0; i < total; i++) {
        final url = await cloudinary.uploadImage(
          _comicPages[i],
          AppConstants.cloudinaryComicPagesFolder,
          onProgress: (transferred, totalBytes) {
            if (mounted && totalBytes > 0) {
              final fileProgress = transferred / totalBytes;
              setState(() {
                _pageUploadProgress = (i + fileProgress) / total;
              });
            }
          },
        );
        uploadedUrls.add(url);
      }

      setState(() {
        _uploadedPageUrls.addAll(uploadedUrls);
        _comicPages = [];
        _isUploadingPages = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPages = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _saveChapter() async {
    if (_isLoadingContent || _contentLoadError != null) return;
    if (!_formKey.currentState!.validate()) return;

    if (_type == AppConstants.chapterTypeText &&
        _textContentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter text content.')),
      );
      return;
    }
    if (_type == AppConstants.chapterTypeComic && _comicPages.isNotEmpty) {
      await _uploadComicPages();
      if (!mounted) return;
      if (_isUploadingPages || _comicPages.isNotEmpty) return;
    }
    if (_type == AppConstants.chapterTypeComic && _uploadedPageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload comic pages.')),
      );
      return;
    }

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
      type: _type,
    );

    try {
      final chapterRepository = ref.read(chapterRepositoryProvider);

      final chapterId = chapter.id.isEmpty
          ? await chapterRepository.createChapter(widget.bookId, chapter)
          : chapter.id;

      // Save content before updating existing metadata so a content write
      // failure does not leave the edit looking successfully completed.
      if (_type == AppConstants.chapterTypeText) {
        final content = ChapterContentModel(
          chapterId: chapterId,
          bookId: widget.bookId,
          textContent: _textContentController.text.trim(),
        );
        await chapterRepository.setChapterContent(content);
      } else {
        final content = ChapterContentModel(
          chapterId: chapterId,
          bookId: widget.bookId,
          pageUrls: _uploadedPageUrls,
        );
        await chapterRepository.setChapterContent(content);
      }

      if (chapter.id.isNotEmpty) {
        await chapterRepository.updateChapter(
          widget.bookId,
          chapter.id,
          chapter.toMap(),
        );
      }

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

            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: AppConstants.chapterTypeText,
                  label: Text('Text'),
                  icon: Icon(Icons.article),
                ),
                ButtonSegment(
                  value: AppConstants.chapterTypeComic,
                  label: Text('Comic'),
                  icon: Icon(Icons.image),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selected) {
                setState(() => _type = selected.first);
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            if (_type == AppConstants.chapterTypeText)
              AppTextField(
                controller: _textContentController,
                label: 'Chapter Content',
                maxLines: 15,
                hint: 'Enter the full text of this chapter...',
                validator: (value) => Validators.textLength(
                  value,
                  min: 1,
                  max: 100000,
                  fieldName: 'Content',
                ),
                textInputAction: TextInputAction.newline,
              )
            else
              ComicPageUploadWidget(
                pages: _comicPages,
                onPagesChanged: (pages) => setState(() => _comicPages = pages),
                uploadedUrls: _uploadedPageUrls,
                onUploadedUrlsChanged: (urls) => setState(() {
                  _uploadedPageUrls
                    ..clear()
                    ..addAll(urls);
                }),
                isUploading: _isUploadingPages,
                uploadProgress: _pageUploadProgress,
                onUpload: _uploadComicPages,
              ),
            const SizedBox(height: AppSpacing.xl),

            AppButton(
              onPressed: _saveChapter,
              text: widget.existingChapter == null
                  ? 'Create Chapter'
                  : 'Save Changes',
              icon: Icons.save,
            ),
          ],
        ),
      ),
    );
  }
}
