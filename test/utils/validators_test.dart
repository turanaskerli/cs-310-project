import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/utils/validators.dart';

void main() {
  group('Validators.required', () {
    final validate = Validators.required('Name');

    test('rejects null, empty and blank values', () {
      expect(validate(null), 'Name is required');
      expect(validate(''), 'Name is required');
      expect(validate('   '), 'Name is required');
    });

    test('accepts text', () {
      expect(validate('Bassam'), isNull);
    });
  });

  group('Validators.email', () {
    test('rejects an empty email', () {
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email(null), 'Email is required');
    });

    test('rejects a malformed email', () {
      expect(Validators.email('not-an-email'), 'Enter a valid email address');
    });

    test('rejects a non-university email', () {
      expect(
        Validators.email('someone@gmail.com'),
        'Use your university email (@sabanciuniv.edu)',
      );
    });

    test('accepts a university email, ignoring case and spaces', () {
      expect(Validators.email('bassam@sabanciuniv.edu'), isNull);
      expect(Validators.email('  Bassam@SabanciUniv.edu '), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects an empty password', () {
      expect(Validators.password(''), 'Password is required');
    });

    test('rejects a password shorter than 8 characters', () {
      expect(
        Validators.password('1234567'),
        'Password must be at least 8 characters',
      );
    });

    test('accepts a password of 8 or more characters', () {
      expect(Validators.password('12345678'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    var password = 'secret123';
    final validate = Validators.confirmPassword(() => password);

    test('rejects an empty confirmation', () {
      expect(validate(''), 'Please confirm your password');
    });

    test('rejects a different password', () {
      expect(validate('secret124'), 'Passwords do not match');
    });

    test('accepts a matching password and reads the latest value', () {
      expect(validate('secret123'), isNull);
      password = 'changed99';
      expect(validate('changed99'), isNull);
    });
  });

  group('Validators.maxLength', () {
    final validate = Validators.maxLength(300, fieldName: 'Bio');

    test('accepts empty and text up to the limit', () {
      expect(validate(''), isNull);
      expect(validate('a' * 300), isNull);
    });

    test('rejects text over the limit', () {
      expect(validate('a' * 301), 'Bio must be at most 300 characters');
    });
  });
}
