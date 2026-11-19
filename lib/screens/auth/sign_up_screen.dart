import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

/// Sign up. Owner: Bassam.
///
/// Screen 2 (the graded form): university email, password, confirm password
/// and a terms checkbox. Every field shows its error inline under itself.
/// When the whole form is valid, a confirmation dialog asks the user to
/// check their email, then the app opens Verify email.
///
/// UI only in Step 2: no account is really created yet.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _acceptedTerms = false;

  /// Errors are shown only after the first Create account tap, so the user
  /// is not greeted by red text before typing anything. After that, each
  /// field re-checks itself as the user types.
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim().toLowerCase();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create your account?'),
        content: Text(
          'We will send a verification link to $email. '
          'Make sure this is your university email.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Edit email'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pushNamed(context, AppRoutes.verifyEmail, arguments: email);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidate,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Create your account', style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Only Sabanci University students can join.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  key: const ValueKey('signUpEmail'),
                  label: 'University email',
                  hint: 'name${Validators.universityDomain}',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  key: const ValueKey('signUpPassword'),
                  label: 'Password',
                  hint: 'At least ${Validators.minPasswordLength} characters',
                  controller: _passwordCtrl,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  validator: Validators.password,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  key: const ValueKey('signUpConfirm'),
                  label: 'Confirm password',
                  controller: _confirmCtrl,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: Validators.confirmPassword(
                    () => _passwordCtrl.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _TermsField(
                  value: _acceptedTerms,
                  onChanged: (v) => setState(() => _acceptedTerms = v),
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(label: 'Create account', onPressed: _submit),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Already have an account?',
                      style: AppTextStyles.bodySmall,
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.login,
                      ),
                      child: const Text('Log in'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The terms checkbox as a form field, so it shows an inline error like the
/// text fields when the form is submitted without it ticked.
class _TermsField extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _TermsField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return FormField<bool>(
      initialValue: value,
      validator: (_) =>
          value ? null : 'You must accept the terms to create an account',
      builder: (field) {
        void toggle() {
          onChanged(!value);
          field.didChange(!value);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: toggle,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              child: Row(
                children: [
                  Checkbox(
                    key: const ValueKey('signUpTerms'),
                    value: value,
                    onChanged: (_) => toggle(),
                  ),
                  const Expanded(
                    child: Text(
                      'I accept the Terms of Use and the Privacy Policy',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.md),
                child: Text(
                  field.errorText!,
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
              ),
          ],
        );
      },
    );
  }
}
