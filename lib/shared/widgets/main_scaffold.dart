import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  static const List<_NavItem> _items = [
    _NavItem(label: 'ホーム', icon: Icons.home_outlined, activeIcon: Icons.home),
    _NavItem(label: 'テクニック', icon: Icons.account_tree_outlined, activeIcon: Icons.account_tree),
    _NavItem(label: '動画', icon: Icons.play_circle_outline, activeIcon: Icons.play_circle),
    _NavItem(label: 'マイページ', icon: Icons.person_outline, activeIcon: Icons.person),
  ];

  void _onTap(BuildContext context, int index) {
    HapticFeedback.lightImpact();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = navigationShell.currentIndex;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        color: const Color(0xFF0C0C0E),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: List.generate(_items.length, (i) {
                final item = _items[i];
                final isSelected = i == selected;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _onTap(context, i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          size: 22,
                          color: isSelected
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF52525B),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF52525B),
                            fontSize: isSelected ? 10 : 9,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
