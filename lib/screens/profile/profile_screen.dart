import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../screens/onboarding/basic_profile_screen.dart';
import '../../services/app_services.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/profile/profile_avatar.dart';
import '../../widgets/state_views.dart';

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
              return const LoadingView();
            }
            final user = snapshot.data;
            if (user == null) {
              return EmptyView(
                icon: Icons.person_outline,
                title: 'No profile yet',
                message: 'Create your profile so other students can find you.',
                actionLabel: 'Create profile',
                onAction: () =>
                    Navigator.pushNamed(context, AppRoutes.basicProfile),
              );
            }
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
    // A short, fixed set of widgets, so a scrolling Column (not a lazy
    // ListView) keeps the buttons built even when they are off screen.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          AppCard(
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
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student ID ${user.studentId}',
                        style: AppTextStyles.body,
                      ),
                      const Text(
                        'Private: only your confirmed roommate sees it',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Edit profile',
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.basicProfile,
              arguments: BasicProfileScreen.editArgument,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: 'Edit answers',
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.questionnaire),
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: 'Settings',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
    );
  }
}
