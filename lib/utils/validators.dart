/// Form field validators shared by the sign-up, log-in and profile screens.
///
/// Each validator matches the `validator:` parameter of a `TextFormField`:
/// it takes the field's text and returns an error message to show under the
/// field, or `null` when the value is valid.
///
/// Example:
/// ```dart
/// TextFormField(validator: Validators.email)
/// TextFormField(validator: Validators.required('Name'))
/// ```
class Validators {
  Validators._(); // Only static members; no instances needed.

  /// Only Sabanci University addresses may sign up.
  static const String universityDomain = '@sabanciuniv.edu';

  static const int minPasswordLength = 8;

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Checks that the field is not empty or only spaces.
  ///
  /// [fieldName] is used in the message, for example "Name is required".
  static String? Function(String?) required(String fieldName) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return '$fieldName is required';
      }
      return null;
    };
  }

  /// Checks for a well-formed university email ending in [universityDomain].
  static String? email(String? value) {
    final email = value?.trim().toLowerCase() ?? '';
    if (email.isEmpty) {
      return 'Email is required';
    }
    if (!_emailPattern.hasMatch(email)) {
      return 'Enter a valid email address';
    }
    if (!email.endsWith(universityDomain)) {
      return 'Use your university email ($universityDomain)';
    }
    return null;
  }

  /// Checks that a password is present and at least [minPasswordLength]
  /// characters long.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < minPasswordLength) {
      return 'Password must be at least $minPasswordLength characters';
    }
    return null;
  }

  /// Checks that the confirm-password field matches the first password.
  ///
  /// [getPassword] is called at validation time so it always reads the
  /// current text, e.g. `Validators.confirmPassword(() => _passwordCtrl.text)`.
  static String? Function(String?) confirmPassword(
    String Function() getPassword,
  ) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password';
      }
      if (value != getPassword()) {
        return 'Passwords do not match';
      }
      return null;
    };
  }

  /// Checks that the text is at most [max] characters (for example the
  /// 300-character bio). An empty value is allowed; combine with
  /// [required] if the field must be filled.
  static String? Function(String?) maxLength(
    int max, {
    String fieldName = 'This field',
  }) {
    return (String? value) {
      if (value != null && value.length > max) {
        return '$fieldName must be at most $max characters';
      }
      return null;
    };
  }
}
