import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../data/models/app_settings_model.dart';
import '../../../../data/providers/service_providers.dart';
import '../../providers/admin_providers.dart';

/// Admin screen for editing app settings.
class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gcashController = TextEditingController();
  final _mayaController = TextEditingController();
  final _qrUrlController = TextEditingController();
  final _vipMonthlyController = TextEditingController();
  final _vipYearlyController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _gcashController.dispose();
    _mayaController.dispose();
    _qrUrlController.dispose();
    _vipMonthlyController.dispose();
    _vipYearlyController.dispose();
    super.dispose();
  }

  void _loadSettings(AppSettingsModel? settings) {
    if (settings != null) {
      _gcashController.text = settings.gcashNumber;
      _mayaController.text = settings.mayaNumber;
      _qrUrlController.text = settings.qrUrl;
      _vipMonthlyController.text = settings.vipMonthlyPrice.toString();
      _vipYearlyController.text = settings.vipYearlyPrice.toString();
    } else {
      _vipMonthlyController.text = AppConstants.defaultVipMonthlyPrice
          .toStringAsFixed(2);
      _vipYearlyController.text = AppConstants.defaultVipYearlyPrice
          .toStringAsFixed(2);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final settings = AppSettingsModel(
      gcashNumber: _gcashController.text.trim(),
      mayaNumber: _mayaController.text.trim(),
      qrUrl: _qrUrlController.text.trim(),
      vipMonthlyPrice: double.parse(_vipMonthlyController.text),
      vipYearlyPrice: double.parse(_vipYearlyController.text),
    );

    try {
      final repository = ref.read(settingsRepositoryProvider);
      await repository.updateAppSettings(settings);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(adminSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('App Settings')),
      body: settingsAsync.when(
        loading: () => const LoadingView(message: 'Loading settings...'),
        error: (error, _) => ErrorView(
          message: _friendlyError(error),
          onRetry: () => ref.invalidate(adminSettingsProvider),
        ),
        data: (settings) {
          _loadSettings(settings);

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Payment Methods',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _gcashController,
                    label: 'GCash Number',
                    validator: Validators.required,
                    prefixIcon: Icons.account_balance_wallet,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _mayaController,
                    label: 'Maya Number',
                    validator: Validators.required,
                    prefixIcon: Icons.account_balance_wallet,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _qrUrlController,
                    label: 'QR Code URL',
                    validator: (value) => value == null || value.trim().isEmpty
                        ? null
                        : Validators.url(value),
                    prefixIcon: Icons.qr_code,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    'VIP Pricing',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _vipMonthlyController,
                    label: 'Monthly Price (₱)',
                    keyboardType: TextInputType.number,
                    validator: Validators.price,
                    prefixIcon: Icons.star,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _vipYearlyController,
                    label: 'Yearly Price (₱)',
                    keyboardType: TextInputType.number,
                    validator: Validators.price,
                    prefixIcon: Icons.star,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  AppButton(
                    onPressed: _isSaving ? null : _saveSettings,
                    text: 'Save Settings',
                    icon: Icons.save,
                    isLoading: _isSaving,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('Exception:')) {
      return message.substring(message.indexOf('Exception:') + 11).trim();
    }
    return AppConstants.errorGeneric;
  }
}
