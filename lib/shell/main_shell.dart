import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    const double iconSize = 26.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          backgroundColor: Colors.white,
          elevation: 0,
          onTap: (index) {
            navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF9886E3),
          unselectedItemColor: const Color(0xFF666666),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
              icon: Image.asset('assets/images/product-logo-black.png', width: iconSize, height: iconSize),
              activeIcon: Image.asset('assets/images/product-logo.png', width: iconSize, height: iconSize),
              label: s.tabDevice,
            ),
            BottomNavigationBarItem(
              icon: Image.asset('assets/images/data-black.png', width: iconSize, height: iconSize),
              activeIcon: Image.asset('assets/images/data.png', width: iconSize, height: iconSize),
              label: s.tabUsage,
            ),
            BottomNavigationBarItem(
              icon: Image.asset('assets/images/user-black.png', width: iconSize, height: iconSize),
              activeIcon: Image.asset('assets/images/user-purple.png', width: iconSize, height: iconSize),
              label: s.tabUser,
            ),
          ],
        ),
      ),
    );
  }
}
