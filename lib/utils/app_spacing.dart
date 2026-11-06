/// Spacing and size values shared by every screen.
/// Use these for padding, gaps and corner radius instead of raw numbers.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Left and right padding of every screen.
  static const double screenPadding = lg;

  /// Corner radius of buttons, text fields and cards.
  static const double radius = 12;

  /// Height of buttons and text fields.
  static const double controlHeight = 48;
}
