import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../screens/onboarding/basic_profile_screen.dart';
import '../../services/app_services.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/profile/profile_avatar.dart';

/// Profile. Owner: Bassam.
///
/// Screen 14 (tab): my photo, name, program, year and bio, plus buttons to
/// Edit profile, Edit answers and Settings. Updates by itself after the
/// profile is edited, because it listens to the user service.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Created once, so rebuilding the tab does not restart the stream.
  late final Stream<AppUser?> _user = AppServices.users.watchCurrentUser();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My profile')),
      body: SafeArea(
        child: StreamBuilder<AppUser?>(
          stream: _user,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final user = snapshot.data;
            if (user == null) return const _NoProfile();
            return _ProfileBody(user: user);
          },
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final AppUser user;

  const _ProfileBody({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        Center(
          child: ProfileAvatar(
            name: user.name,
            photoUrl: user.photoUrl,
            localPhotoPath: user.localPhotoPath,
            size: 112,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          user.name,
          style: AppTextStyles.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${user.program} · ${AppUser.yearLabel(user.year)}',
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('About me', style: AppTextStyles.heading),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  user.bio.isEmpty
                      ? 'Add a short bio so matches know you better.'
                      : user.bio,
                  style: user.bio.isEmpty
                      ? AppTextStyles.bodySmall
                      : AppTextStyles.body,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: ListTile(
            leading: const Icon(Icons.lock_outline, color: AppColors.primary),
            title: Text(
              'Student ID ${user.studentId}',
              style: AppTextStyles.body,
            ),
            subtitle: const Text(
              'Private: only your confirmed roommate sees it',
              style: AppTextStyles.caption,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.basicProfile,
            arguments: BasicProfileScreen.editArgument,
          ),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit profile'),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.questionnaire),
          icon: const Icon(Icons.checklist),
          label: const Text('Edit answers'),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          icon: const Icon(Icons.settings_outlined),
          label: const Text('Settings'),
        ),
      ],
    );
  }
}

/// Shown if the student has not created a profile yet.
class _NoProfile extends StatelessWidget {
  const _NoProfile();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.person_outline,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'No profile yet',
              style: AppTextStyles.heading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Create your profile so other students can find you.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.basicProfile),
              child: const Text('Create profile'),
            ),
          ],
        ),
      ),
    );
  }
}
