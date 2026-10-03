import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../providers/auth_providers.dart';

/// Login screen for user authentication
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo/Title section
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Welcome to\nHiraya Aklatan',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Sign in to continue reading',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppSpacing.xxxl),

                // Email field
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                  prefixIcon: Icons.email_outlined,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Password field
                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) => Validators.required(value, fieldName: 'Password'),
                  prefixIcon: Icons.lock_outlined,
                  onSubmitted: (_) => _signIn(authNotifier),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Sign in button
                AppButton(
                  onPressed: authState.isLoading ? null : () => _signIn(authNotifier),
                  text: 'Sign In',
                  isLoading: authState.isLoading,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text(
                        'or',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Google Sign-In button
                AppButton(
                  onPressed: authState.isLoading
                      ? null
                      : () => _signInWithGoogle(authNotifier),
                  text: 'Sign in with Google',
                  icon: Icons.g_mobiledata,
                  isLoading: authState.isLoading,
                  isOutlined: true,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () => context.push(RouteNames.register),
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),

                // Forgot password link
                TextButton(
                  onPressed: () => context.push(RouteNames.forgotPassword),
                  child: const Text('Forgot Password?'),
                ),

                const Spacer(),

                // Error message
                if (authState.hasError)
                  _MessageBanner(
                    message: _friendlyError(authState.error),
                    isError: true,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn(AuthNotifier authNotifier) async {
    if (!_formKey.currentState!.validate()) return;

    // On success the router redirect navigates to the library automatically.
    await authNotifier.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  Future<void> _signInWithGoogle(AuthNotifier authNotifier) async {
    // On success the router redirect navigates to the library automatically.
    await authNotifier.signInWithGoogle();
  }

  /// Strips the "Exception: " prefix so messages read naturally.
  /// Also handles FirebaseAuthException directly with user-friendly messages.
  String _friendlyError(Object? error) {
    if (error == null) return 'An unknown error occurred';
    
    // If it's a FirebaseAuthException, extract the code and provide friendly message
    if (error is FirebaseAuthException) {
      return _getFriendlyAuthError(error.code);
    }
    
    final message = error.toString();
    // Handle both "Exception: message" and raw message strings
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }
  
  /// Returns user-friendly error message for Firebase auth error codes.
  String _getFriendlyAuthError(String code) {
    switch (code) {
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Contact support.';
      default:
        return 'Authentication failed: ${code.replaceAll('-', ' ')}';
    }
  }
}

/// Inline banner for form-level error feedback.
class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
        textAlign: TextAlign.center,
      ),
    );
  }
}