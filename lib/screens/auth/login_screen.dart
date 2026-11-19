import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

/// Log in (screen 4). Owner: Murad.
///
/// University email and password with inline validation, a Forgot password
/// link, and a Log in button that opens the main tabs.
///
/// UI only in Step 2: the button checks the form and waits briefly to show
/// the loading state. Firebase sign-in replaces [_signIn] in Step 3.
class LoginScreen extends StatefulWidget {
  /// How long the fake sign-in takes, so the loading spinner is visible.
  final Duration fakeDelay;

  const LoginScreen({
    super.key,
    this.fakeDelay = const Duration(milliseconds: 600),
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  // Errors appear only after the first Log in tap, then update while typing.
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }

    setState(() => _isLoading = true);
    await Future<void>.delayed(widget.fakeDelay);
    if (!mounted) return;

    // Clear the history so Back does not return to the log-in screen.
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
  }

  void _openForgotPassword() {
    // Pass the typed email along so the user does not type it twice.
    Navigator.pushNamed(
      context,
      AppRoutes.forgotPassword,
      arguments: _emailController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 2 * AppSpacing.screenPadding,
              ),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autovalidate,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Welcome back', style: AppTextStyles.title),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Log in with your Sabancı University email.',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppTextField(
                          label: 'University email',
                          hint: 'name@sabanciuniv.edu',
                          controller: _emailController,
                          validator: Validators.email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: 'Password',
                          hint: 'Your password',
                          controller: _passwordController,
                          validator: Validators.password,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) => _signIn(),
                          enabled: !_isLoading,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading ? null : _openForgotPassword,
                            child: const Text('Forgot password?'),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: AppSpacing.xl),
                        PrimaryButton(
                          label: 'Log in',
                          isLoading: _isLoading,
                          onPressed: _signIn,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Flexible(
                              child: Text(
                                'Don’t have an account?',
                                style: AppTextStyles.bodySmall,
                              ),
                            ),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.pushReplacementNamed(
                                      context,
                                      AppRoutes.signUp,
                                    ),
                              child: const Text('Sign up'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
