/// Short date and time labels for the Chats list and the Chat screen.
library;

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

/// Whole calendar days between [t] and [now] (0 = same day).
int _daysAgo(DateTime t, DateTime now) =>
    // Rounded, so a daylight-saving change does not shift the count.
    (_day(now).difference(_day(t)).inHours / 24).round();

/// "09:05".
String clockTime(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// For the Chats list: "14:32" today, "Yesterday", "Mon" this week, then
/// "12 Nov".
String chatListTime(DateTime t, DateTime now) {
  final days = _daysAgo(t, now);
  if (days <= 0) return clockTime(t);
  if (days == 1) return 'Yesterday';
  if (days < 7) return _weekdays[t.weekday - 1];
  return '${t.day} ${_months[t.month - 1]}';
}

/// For the separators between messages: "Today", "Yesterday", "12 Nov".
String chatDayLabel(DateTime t, DateTime now) {
  final days = _daysAgo(t, now);
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  final label = '${t.day} ${_months[t.month - 1]}';
  return t.year == now.year ? label : '$label ${t.year}';
}

/// Whether [a] and [b] fall on the same calendar day.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
