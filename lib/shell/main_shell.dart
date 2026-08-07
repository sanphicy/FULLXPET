import 'package:flutter/material.dart';
// 引入设备列表页面
import 'package:fullxpet/features/device/device_list/device_list_page.dart';
import 'package:fullxpet/features/user/user_page.dart';
import 'package:fullxpet/features/device/device_usage/device_usage_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [const DeviceListPage(), const DeviceUsagePage(), const UserPage()];
  @override
  Widget build(BuildContext context) {
    const double iconSize = 26.0;

    return Scaffold(
      backgroundColor: Colors.white,
      // IndexedStack 配合外层注入的 Provider，完美保持状态
      body: IndexedStack(index: _currentIndex, children: _pages),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.white,
          elevation: 0,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
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
              label: "设备",
            ),
            BottomNavigationBarItem(
              icon: Image.asset('assets/images/data-black.png', width: iconSize, height: iconSize),
              activeIcon: Image.asset('assets/images/data.png', width: iconSize, height: iconSize),
              label: "概况",
            ),
            BottomNavigationBarItem(
              icon: Image.asset('assets/images/user-black.png', width: iconSize, height: iconSize),
              activeIcon: Image.asset('assets/images/user-purple.png', width: iconSize, height: iconSize),
              label: "用户",
            ),
          ],
        ),
      ),
    );
  }
}
