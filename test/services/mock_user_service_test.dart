import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/models/app_user.dart';
import 'package:roommate_finder/services/mock/mock_user_service.dart';

void main() {
  test('starts signed in as the fake user', () async {
    final service = MockUserService(delay: Duration.zero);

    expect(await service.getCurrentUser(), MockUserService.fakeUser);
  });

  test('can start with no profile', () async {
    final service = MockUserService(delay: Duration.zero, startEmpty: true);

    expect(await service.getCurrentUser(), isNull);
  });

  test('saveProfile updates getCurrentUser and the stream', () async {
    final service = MockUserService(delay: Duration.zero);
    final updated = MockUserService.fakeUser.copyWith(name: 'New Name');

    final emitted = service.watchCurrentUser().take(2).toList();
    await Future<void>.delayed(Duration.zero);
    await service.saveProfile(updated);

    expect(await emitted, [MockUserService.fakeUser, updated]);
    expect(await service.getCurrentUser(), updated);
  });

  test('AppUser round-trips through a map without the local photo', () {
    final user = MockUserService.fakeUser.copyWith(localPhotoPath: '/tmp/a');
    final restored = AppUser.fromMap(user.uid, user.toMap());

    expect(restored, MockUserService.fakeUser);
    expect(AppUser.yearLabel(0), 'Prep');
    expect(AppUser.yearLabel(2), 'Year 2');
  });
}
