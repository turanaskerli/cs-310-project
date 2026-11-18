import 'dart:async';

import '../../models/app_user.dart';
import '../user_service.dart';

/// A fake signed-in student, so the Profile tab and Edit profile work
/// without Firebase. Changes live in memory only.
class MockUserService implements UserService {
  static const myUid = 'mock_me';

  static const fakeUser = AppUser(
    uid: myUid,
    email: 'bassam.khoja@sabanciuniv.edu',
    name: 'Bassam Khoja',
    gender: 'Male',
    program: 'Computer Science and Engineering',
    year: 2,
    bio:
        'Early riser, tidy, and usually studying in the library until '
        'dinner. I like cooking on weekends and keeping the room quiet at '
        'night.',
    studentId: '36035',
    photoUrl: 'https://i.pravatar.cc/300?img=12',
  );

  /// Simulated network delay, so screens show their loading state.
  final Duration delay;

  AppUser? _user;
  final _changes = StreamController<AppUser?>.broadcast();

  /// Starts signed in as [initialUser] (default [fakeUser]). Pass
  /// `startEmpty: true` to simulate a student who has no profile yet.
  MockUserService({
    this.delay = const Duration(milliseconds: 300),
    AppUser? initialUser,
    bool startEmpty = false,
  }) : _user = startEmpty ? null : (initialUser ?? fakeUser);

  @override
  Stream<AppUser?> watchCurrentUser() async* {
    await Future<void>.delayed(delay);
    yield _user;
    yield* _changes.stream;
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    await Future<void>.delayed(delay);
    return _user;
  }

  @override
  Future<void> saveProfile(AppUser user) async {
    await Future<void>.delayed(delay);
    _user = user;
    _changes.add(user);
  }
}
