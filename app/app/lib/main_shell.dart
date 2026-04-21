import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'user_provider.dart';
import 'screens/home_screen.dart';
import 'screens/terms_consent_screen.dart';
import 'screens/plants_map_screen.dart';
import 'screens/about_screen.dart';
import 'screens/settings_screen.dart';

/// هيكل التطبيق مع شريط تنقل سفلي ثابت.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<PlantsMapScreenState> _mapKey = GlobalKey<PlantsMapScreenState>();

  void _onNavSelected(int i) {
    setState(() => _index = i);
    if (i == 0) {
      _homeKey.currentState?.refreshData();
    } else if (i == 1) {
      _mapKey.currentState?.refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (!UserProvider.hasAcceptedTermsPrivacy) {
      return TermsConsentScreen(
        onCompleted: () {
          if (mounted) setState(() {});
        },
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(key: _homeKey),
          PlantsMapScreen(key: _mapKey),
          const AboutScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 68,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontWeight: FontWeight.w700,
                fontSize: 12,
              );
            }
            return const TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontWeight: FontWeight.w500,
              fontSize: 11,
            );
          }),
          indicatorColor: AppTheme.primary.withOpacity(0.22),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _onNavSelected,
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shadowColor: Colors.black26,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded),
              label: 'الخريطة',
            ),
            NavigationDestination(
              icon: Icon(Icons.info_outline_rounded),
              selectedIcon: Icon(Icons.info_rounded),
              label: 'حول',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }
}
