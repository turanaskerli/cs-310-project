import '../models/app_user.dart';

/// The signed-in student's own profile.
///
/// Screens depend on this interface only. Use `MockUserService` until the
/// Firebase version exists.
abstract class UserService {
  /// The current profile, or null before the student creates one. Emits
  /// again whenever the profile is saved.
  Stream<AppUser?> watchCurrentUser();

  /// The current profile once, e.g. to fill the Edit profile form.
  Future<AppUser?> getCurrentUser();

  /// Creates or updates the current profile.
  Future<void> saveProfile(AppUser user);
}
