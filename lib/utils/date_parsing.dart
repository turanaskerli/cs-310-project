/// Converts a stored date into a [DateTime] without importing Firebase.
///
/// Accepts a [DateTime], milliseconds since epoch, an ISO-8601 string, or
/// anything with a `toDate()` method (such as a Firestore `Timestamp`), so
/// models stay free of Firebase imports.
DateTime? parseDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  try {
    final converted = (value as dynamic).toDate();
    if (converted is DateTime) return converted;
  } catch (_) {
    // Not a timestamp-like object.
  }
  return null;
}
