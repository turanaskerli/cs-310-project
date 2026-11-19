import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

/// Forgot password (screen 4b). Owner: Murad.
///
/// Two states: an email field with a Send reset link button, then a
/// confirmation message once the link is "sent". The email typed on the
/// Log in screen arrives as the route argument and is filled in.
///
/// UI only in Step 2: Firebase's password reset replaces [_sendLink] in
/// Step 3.
class ForgotPasswordScreen extends StatefulWidget {
  /// How long the fake request takes, so the loading spinner is visible.
  final Duration fakeDelay;

  const ForgotPasswordScreen({
    super.key,
    this.fakeDelay = const Duration(milliseconds: 600),
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  /// The address the link was sent to; null until it is sent.
  String? _sentTo;

  bool _readArgument = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Route arguments are only available once the context is attached.
    if (!_readArgument) {
      _readArgument = true;
      final email = ModalRoute.of(context)?.settings.arguments;
      if (email is String) _emailController.text = email;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendLink() async {
    FocusScope.of(context).unfocus();
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }

    setState(() => _isLoading = true);
    await Future<void>.delayed(widget.fakeDelay);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _sentTo = _emailController.text.trim();
    });
  }

  Future<void> _resend() async {
    setState(() => _isLoading = true);
    await Future<void>.delayed(widget.fakeDelay);
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('We sent you another reset link.')),
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
                child: _sentTo == null ? _buildForm() : _buildSent(_sentTo!),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      autovalidateMode: _autovalidate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Reset your password', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Enter your university email and we’ll send you a link to set '
            'a new password.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: 'University email',
            hint: 'name@sabanciuniv.edu',
            controller: _emailController,
            validator: Validators.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            autofillHints: const [AutofillHints.email],
            onSubmitted: (_) => _sendLink(),
            enabled: !_isLoading,
          ),
          const Spacer(),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Send reset link',
            isLoading: _isLoading,
            onPressed: _sendLink,
          ),
        ],
      ),
    );
  }

  Widget _buildSent(String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xxl),
        const Center(
          child: CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.success,
            child: Icon(
              Icons.mark_email_read_outlined,
              size: 40,
              color: AppColors.surface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text(
          'Check your inbox',
          style: AppTextStyles.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'We sent a reset link to $email. Open it to choose a new password.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Back to log in',
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: TextButton(
            onPressed: _isLoading ? null : _resend,
            child: Text(
              _isLoading ? 'Sending…' : 'Didn’t get it? Resend email',
            ),
          ),
        ),
      ],
    );
  }
}
