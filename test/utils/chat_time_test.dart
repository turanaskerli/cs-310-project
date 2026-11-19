import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/utils/chat_time.dart';

void main() {
  // A Wednesday.
  final now = DateTime(2026, 11, 18, 14, 30);

  test('clockTime pads hours and minutes', () {
    expect(clockTime(DateTime(2026, 1, 1, 9, 5)), '09:05');
    expect(clockTime(DateTime(2026, 1, 1, 23, 59)), '23:59');
  });

  test('chatListTime: time today, Yesterday, weekday, then date', () {
    expect(chatListTime(DateTime(2026, 11, 18, 0, 1), now), '00:01');
    expect(chatListTime(DateTime(2026, 11, 17, 23, 59), now), 'Yesterday');
    expect(chatListTime(DateTime(2026, 11, 16, 10), now), 'Mon');
    expect(chatListTime(DateTime(2026, 11, 12, 10), now), 'Thu');
    expect(chatListTime(DateTime(2026, 11, 11, 10), now), '11 Nov');
  });

  test('chatDayLabel: Today, Yesterday, date, year when not this year', () {
    expect(chatDayLabel(DateTime(2026, 11, 18, 1), now), 'Today');
    expect(chatDayLabel(DateTime(2026, 11, 17, 1), now), 'Yesterday');
    expect(chatDayLabel(DateTime(2026, 11, 2), now), '2 Nov');
    expect(chatDayLabel(DateTime(2025, 12, 31), now), '31 Dec 2025');
  });

  test('isSameDay ignores the time', () {
    expect(isSameDay(DateTime(2026, 1, 1, 0), DateTime(2026, 1, 1, 23)), true);
    expect(isSameDay(DateTime(2026, 1, 1, 23), DateTime(2026, 1, 2)), false);
  });
}
