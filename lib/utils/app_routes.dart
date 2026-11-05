import 'package:flutter/material.dart';

import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/chat/roommate_confirmed_screen.dart';
import '../screens/home/main_shell.dart';
import '../screens/matches/match_detail_screen.dart';
import '../screens/onboarding/basic_profile_screen.dart';
import '../screens/onboarding/consent_screen.dart';
import '../screens/questionnaire/dealbreakers_screen.dart';
import '../screens/questionnaire/honesty_intro_screen.dart';
import '../screens/questionnaire/questionnaire_screen.dart';
import '../screens/questionnaire/review_submit_screen.dart';
import '../screens/settings/settings_screen.dart';

/// All named routes of the app. Every screen already has a file and a route,
/// so members only edit their own screen files, never this one.
///
/// Open a screen with: Navigator.pushNamed(context, AppRoutes.login);
///
/// The four tabs (Matches, Requests, Chats, Profile) are not routes; they
/// live inside [MainShell], which is opened with [AppRoutes.home].
class AppRoutes {
  AppRoutes._();

  // Auth (Murad, Bassam)
  static const String welcome = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String signUp = '/sign-up';
  static const String verifyEmail = '/verify-email';

  // Onboarding (Bassam)
  static const String consent = '/consent';
  static const String basicProfile = '/basic-profile'; // also Edit profile

  // Questionnaire (Turan, Arda)
  static const String honestyIntro = '/honesty-intro';
  static const String questionnaire = '/questionnaire'; // also Edit answers
  static const String dealbreakers = '/dealbreakers';
  static const String reviewSubmit = '/review-submit';

  // Main app
  static const String home = '/home'; // bottom tabs (Murad)
  static const String matchDetail = '/match-detail'; // Turan
  static const String chat = '/chat'; // Arda
  static const String roommateConfirmed = '/roommate-confirmed'; // Arda
  static const String settings = '/settings'; // Arda

  static Map<String, WidgetBuilder> get routes => {
    welcome: (_) => const WelcomeScreen(),
    login: (_) => const LoginScreen(),
    forgotPassword: (_) => const ForgotPasswordScreen(),
    signUp: (_) => const SignUpScreen(),
    verifyEmail: (_) => const VerifyEmailScreen(),
    consent: (_) => const ConsentScreen(),
    basicProfile: (_) => const BasicProfileScreen(),
    honestyIntro: (_) => const HonestyIntroScreen(),
    questionnaire: (_) => const QuestionnaireScreen(),
    dealbreakers: (_) => const DealbreakersScreen(),
    reviewSubmit: (_) => const ReviewSubmitScreen(),
    home: (_) => const MainShell(),
    matchDetail: (_) => const MatchDetailScreen(),
    chat: (_) => const ChatScreen(),
    roommateConfirmed: (_) => const RoommateConfirmedScreen(),
    settings: (_) => const SettingsScreen(),
  };
}
