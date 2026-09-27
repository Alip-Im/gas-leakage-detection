import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'history_log_screen.dart';
import 'settings_screen.dart';
import 'user_profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  static const Color lightBlue = Color(0xFF82CAFF);
  static const Color steelBlue = Color(0xFF4682B4);
  static const Color darkBlue = Color(0xFF234E70);

  final List<Widget> _screens = [
    const DashboardScreen(),
    const HistoryLogScreen(),
    const SettingsScreen(),
    const UserProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: lightBlue.withOpacity(0.35),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            backgroundColor: Colors.white,
            selectedItemColor: steelBlue,
            unselectedItemColor: Colors.blueGrey.shade400,
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: _navIcon(
                  Icons.dashboard_outlined,
                  false,
                ),
                activeIcon: _navIcon(
                  Icons.dashboard_rounded,
                  true,
                ),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: _navIcon(
                  Icons.show_chart_rounded,
                  false,
                ),
                activeIcon: _navIcon(
                  Icons.show_chart_rounded,
                  true,
                ),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: _navIcon(
                  Icons.tune_rounded,
                  false,
                ),
                activeIcon: _navIcon(
                  Icons.tune_rounded,
                  true,
                ),
                label: 'Settings',
              ),
              BottomNavigationBarItem(
                icon: _navIcon(
                  Icons.person_outline_rounded,
                  false,
                ),
                activeIcon: _navIcon(
                  Icons.person_rounded,
                  true,
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, bool selected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: selected
            ? lightBlue.withOpacity(0.22)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 23,
        color: selected ? darkBlue : Colors.blueGrey.shade400,
      ),
    );
  }
}