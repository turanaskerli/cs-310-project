import 'package:flutter/material.dart';

import '../chat/chats_screen.dart';
import '../matches/matches_screen.dart';
import '../profile/profile_screen.dart';
import '../requests/requests_screen.dart';

/// Main tabs. Owner: Murad.
///
/// The screen the user lands on after logging in. A bottom navigation bar
/// switches between the four tabs: Matches, Requests, Chats and Profile.
/// Each tab's content is built by its owner in their own folder.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // IndexedStack keeps every tab alive, so scroll position and typed text
  // are not lost when the user switches tabs.
  static const List<Widget> _tabs = [
    MatchesScreen(),
    RequestsScreen(),
    ChatsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Matches',
          ),
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
