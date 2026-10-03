import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/book_model.dart';
import '../../../../data/providers/service_providers.dart';
import '../../providers/admin_providers.dart';
import 'cover_image_upload_widget.dart';

/// Form widget for creating or editing a book.
class BookFormWidget extends ConsumerStatefulWidget {
  const BookFormWidget({
    super.key,
    this.existingBook,
  });

  final BookModel? existingBook;

  @override
  ConsumerState<BookFormWidget> createState() => _BookFormWidgetState();
}

class _BookFormWidgetState extends ConsumerState<BookFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _summaryController = TextEditingController();

  String? _coverUrl;
  String _status = AppConstants.bookStatusOngoing;
  final List<String> _selectedGenres = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingBook != null) {
      _titleController.text = widget.existingBook!.title;
      _authorController.text = widget.existingBook!.author;
      _summaryController.text = widget.existingBook!.summary;
      _coverUrl = widget.existingBook!.coverUrl;
      _status = widget.existingBook!.status;
      _selectedGenres.addAll(widget.existingBook!.genres);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;
    if (_coverUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a cover image.')),
      );
      return;
    }

    final book = BookModel(
      id: widget.existingBook?.id ?? '',
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      summary: _summaryController.text.trim(),
      genres: _selectedGenres,
      coverUrl: _coverUrl!,
      rating: widget.existingBook?.rating ?? 0,
      status: _status,
      createdAt: widget.existingBook?.createdAt ?? DateTime.now(),
    );

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saving book...')),
        );
      }

      final repository = ref.read(bookRepositoryProvider);
      if (book.id.isEmpty) {
        await repository.createBook(book);
      } else {
        await repository.updateBook(book.id, book.toMap());
      }
      ref.invalidate(adminBooksProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book saved successfully.')),
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
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Cover Image', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            CoverImageUploadWidget(
              coverUrl: _coverUrl,
              onCoverUploaded: (url) => setState(() => _coverUrl = url),
            ),
            const SizedBox(height: AppSpacing.lg),

            AppTextField(
              controller: _titleController,
              label: 'Title',
              validator: (value) =>
                  Validators.textLength(value, min: 1, max: AppConstants.maxTitleLength, fieldName: 'Title'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),

            AppTextField(
              controller: _authorController,
              label: 'Author',
              validator: (value) =>
                  Validators.textLength(value, min: 1, max: 100, fieldName: 'Author'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),

            AppTextField(
              controller: _summaryController,
              label: 'Summary',
              maxLines: 4,
              validator: (value) =>
                  Validators.textLength(value, min: 1, max: AppConstants.maxSummaryLength, fieldName: 'Summary'),
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: AppSpacing.md),

            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: AppConstants.bookStatusOngoing, child: Text('Ongoing')),
                DropdownMenuItem(value: AppConstants.bookStatusCompleted, child: Text('Completed')),
                DropdownMenuItem(value: AppConstants.bookStatusHiatus, child: Text('Hiatus')),
              ],
              onChanged: (value) => setState(() => _status = value!),
            ),
            const SizedBox(height: AppSpacing.md),

            Text('Genres', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final genre in AppConstants.genres)
                  FilterChip(
                    label: Text(genre),
                    selected: _selectedGenres.contains(genre),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedGenres.add(genre);
                        } else {
                          _selectedGenres.remove(genre);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            AppButton(
              onPressed: _saveBook,
              text: widget.existingBook == null ? 'Create Book' : 'Save Changes',
              icon: Icons.save,
            ),
          ],
        ),
      ),
    );
  }
}
