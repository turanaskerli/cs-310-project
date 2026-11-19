import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/app_user.dart';
import '../../services/app_services.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/profile/profile_avatar.dart';
import '../../widgets/state_views.dart';

/// Basic profile. Owner: Bassam.
///
/// Screen 6: photo (picked from the gallery, previewed locally), name,
/// gender, program, year, a bio of at most 300 characters and the private
/// student ID, all with inline validation.
///
/// The same screen is Edit profile: open it with
/// `Navigator.pushNamed(context, AppRoutes.basicProfile,
/// arguments: BasicProfileScreen.editArgument)`. In edit mode the form is
/// filled with the current profile and Save goes back; in sign-up mode
/// Continue goes on to the questionnaire.
class BasicProfileScreen extends StatefulWidget {
  const BasicProfileScreen({super.key});

  /// Route argument that opens the screen as Edit profile.
  static const String editArgument = 'edit';

  static const int maxBioLength = 300;

  @override
  State<BasicProfileScreen> createState() => _BasicProfileScreenState();
}

class _BasicProfileScreenState extends State<BasicProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();

  bool _isEditing = false;
  bool _started = false;
  bool _loading = true;
  bool _saving = false;
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  /// The profile this form started from, if the student already has one.
  AppUser? _existing;
  String? _gender;
  String? _program;
  int? _year;
  String? _localPhotoPath;

  @override
  void initState() {
    super.initState();
    // Rebuild as the name changes, so the initials in the photo circle
    // follow what the student types.
    _nameCtrl.addListener(_onNameChanged);
  }

  void _onNameChanged() => setState(() {});

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The route argument is only readable once the widget is in the tree,
    // so the mode is decided here instead of in initState.
    if (_started) return;
    _started = true;
    _isEditing =
        ModalRoute.of(context)?.settings.arguments ==
        BasicProfileScreen.editArgument;
    _load();
  }

  Future<void> _load() async {
    final user = await AppServices.users.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _existing = user;
      if (_isEditing && user != null) {
        _nameCtrl.text = user.name;
        _bioCtrl.text = user.bio;
        _studentIdCtrl.text = user.studentId;
        _gender = AppUser.genders.contains(user.gender) ? user.gender : null;
        _program = AppUser.programs.contains(user.program)
            ? user.program
            : null;
        _year = AppUser.years.contains(user.year) ? user.year : null;
        _localPhotoPath = user.localPhotoPath;
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onNameChanged);
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _studentIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _localPhotoPath = picked.path);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open your photos')),
      );
    }
  }

  Future<void> _save() async {
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!_formKey.currentState!.validate()) return;

    final base = _existing;
    final user = AppUser(
      uid: base?.uid ?? '',
      email: base?.email ?? '',
      name: _nameCtrl.text.trim(),
      gender: _gender!,
      program: _program!,
      year: _year!,
      bio: _bioCtrl.text.trim(),
      studentId: _studentIdCtrl.text.trim(),
      // Keep the uploaded photo only when editing; a new student has none.
      photoUrl: _isEditing ? base?.photoUrl : null,
      localPhotoPath: _localPhotoPath,
    );

    setState(() => _saving = true);
    await AppServices.users.saveProfile(user);
    if (!mounted) return;
    setState(() => _saving = false);

    if (_isEditing) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved')));
      Navigator.pop(context);
    } else {
      Navigator.pushNamed(context, AppRoutes.honestyIntro);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit profile' : 'Create your profile'),
      ),
      body: SafeArea(
        child: _loading
            ? const LoadingView()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildForm()),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    child: PrimaryButton(
                      label: _isEditing ? 'Save' : 'Continue',
                      isLoading: _saving,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Form(
        key: _formKey,
        autovalidateMode: _autovalidate,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isEditing) ...[
              Text(
                'This is what your matches will see.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _PhotoPicker(
              name: _nameCtrl.text,
              photoUrl: _isEditing ? _existing?.photoUrl : null,
              localPhotoPath: _localPhotoPath,
              onPick: _pickPhoto,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              key: const ValueKey('profileName'),
              label: 'Full name',
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              validator: Validators.required('Name'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _LabeledDropdown<String>(
              fieldKey: const ValueKey('profileGender'),
              label: 'Gender',
              value: _gender,
              options: {for (final g in AppUser.genders) g: g},
              onChanged: (v) => setState(() => _gender = v),
              emptyError: 'Please choose your gender',
            ),
            const SizedBox(height: AppSpacing.lg),
            _LabeledDropdown<String>(
              fieldKey: const ValueKey('profileProgram'),
              label: 'Program',
              value: _program,
              options: {for (final p in AppUser.programs) p: p},
              onChanged: (v) => setState(() => _program = v),
              emptyError: 'Please choose your program',
            ),
            const SizedBox(height: AppSpacing.lg),
            _LabeledDropdown<int>(
              fieldKey: const ValueKey('profileYear'),
              label: 'Year',
              value: _year,
              options: {for (final y in AppUser.years) y: AppUser.yearLabel(y)},
              onChanged: (v) => setState(() => _year = v),
              emptyError: 'Please choose your year',
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              key: const ValueKey('profileBio'),
              label: 'Bio (optional)',
              hint: 'Your habits, hobbies, what you look for',
              controller: _bioCtrl,
              maxLines: 4,
              maxLength: BasicProfileScreen.maxBioLength,
              validator: Validators.maxLength(
                BasicProfileScreen.maxBioLength,
                fieldName: 'Bio',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              key: const ValueKey('profileStudentId'),
              label: 'Student ID',
              hint: 'e.g. 36035',
              controller: _studentIdCtrl,
              keyboardType: TextInputType.number,
              validator: Validators.studentId,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Private: only your confirmed roommate sees it',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// A dropdown with its label above it, matching the shared [AppTextField],
/// and an inline error when nothing is chosen.
class _LabeledDropdown<T> extends StatelessWidget {
  final Key fieldKey;
  final String label;
  final T? value;
  final Map<T, String> options;
  final ValueChanged<T?> onChanged;
  final String emptyError;

  const _LabeledDropdown({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.emptyError,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.xs + 2),
        DropdownButtonFormField<T>(
          key: fieldKey,
          initialValue: value,
          isExpanded: true,
          hint: Text(
            'Choose',
            style: AppTextStyles.body.copyWith(color: AppColors.disabled),
          ),
          style: AppTextStyles.body,
          items: [
            for (final entry in options.entries)
              DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
          validator: (v) => v == null ? emptyError : null,
        ),
      ],
    );
  }
}

/// The round photo with a button to choose one from the gallery.
class _PhotoPicker extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final String? localPhotoPath;
  final VoidCallback onPick;

  const _PhotoPicker({
    required this.name,
    required this.photoUrl,
    required this.localPhotoPath,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null || localPhotoPath != null;
    return Column(
      children: [
        GestureDetector(
          onTap: onPick,
          child: Stack(
            children: [
              ProfileAvatar(
                name: name.trim().isEmpty ? '?' : name,
                photoUrl: photoUrl,
                localPhotoPath: localPhotoPath,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs + 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: const Icon(
                    Icons.photo_camera_outlined,
                    size: 16,
                    color: AppColors.surface,
                  ),
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onPick,
          child: Text(hasPhoto ? 'Change photo' : 'Add photo'),
        ),
      ],
    );
  }
}
