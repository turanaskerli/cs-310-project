import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/app_user.dart';
import '../../services/app_services.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/validators.dart';
import '../../widgets/profile/profile_avatar.dart';

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
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildForm()),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.surface,
                              ),
                            )
                          : Text(_isEditing ? 'Save' : 'Continue'),
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
            TextFormField(
              key: const ValueKey('profileName'),
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: Validators.required('Name'),
              // Rebuild so the initials in the photo circle follow the name.
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              key: const ValueKey('profileGender'),
              initialValue: _gender,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: [
                for (final g in AppUser.genders)
                  DropdownMenuItem(
                    value: g,
                    child: Text(g, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _gender = v),
              validator: (v) => v == null ? 'Please choose your gender' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              key: const ValueKey('profileProgram'),
              initialValue: _program,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Program'),
              items: [
                for (final p in AppUser.programs)
                  DropdownMenuItem(
                    value: p,
                    child: Text(p, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _program = v),
              validator: (v) => v == null ? 'Please choose your program' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<int>(
              key: const ValueKey('profileYear'),
              initialValue: _year,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Year'),
              items: [
                for (final y in AppUser.years)
                  DropdownMenuItem(value: y, child: Text(AppUser.yearLabel(y))),
              ],
              onChanged: (v) => setState(() => _year = v),
              validator: (v) => v == null ? 'Please choose your year' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              key: const ValueKey('profileBio'),
              controller: _bioCtrl,
              minLines: 3,
              maxLines: 5,
              maxLength: BasicProfileScreen.maxBioLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Bio (optional)',
                hintText: 'Your habits, hobbies, what you look for',
                alignLabelWithHint: true,
              ),
              validator: Validators.maxLength(
                BasicProfileScreen.maxBioLength,
                fieldName: 'Bio',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              key: const ValueKey('profileStudentId'),
              controller: _studentIdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Student ID',
                prefixIcon: Icon(Icons.lock_outline),
                helperText: 'Private: only your confirmed roommate sees it',
              ),
              validator: Validators.studentId,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
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
