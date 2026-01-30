import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, TabController, TabBarView;
import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import '../ai_icon.dart';

/// Demo page showing CNTabBar with custom Flutter IconData icons.
///
/// This demonstrates how to use Flutter's built-in icons (like Material Icons
/// or Cupertino Icons) in the native tab bar, in addition to SF Symbols.
class TabBarCustomIconsDemoPage extends StatefulWidget {
  const TabBarCustomIconsDemoPage({super.key});

  @override
  State<TabBarCustomIconsDemoPage> createState() =>
      _TabBarCustomIconsDemoPageState();
}

class _TabBarCustomIconsDemoPageState extends State<TabBarCustomIconsDemoPage>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 5, vsync: this);
    _controller.addListener(() {
      final i = _controller.index;
      if (i != _index) setState(() => _index = i);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Tab Bar with Custom Icons'),
      ),
      child: Stack(
        children: [
          // Content below
          Positioned.fill(
            child: TabBarView(
              controller: _controller,
              children: const [
                _DemoTabPage(label: 'Dashboard', icon: Icons.dashboard),
                _DemoTabPage(label: 'Favorites', icon: Icons.roundabout_left),
                _DemoTabPage(label: 'Notifications', icon: Icons.notifications),
                _DemoTabPage(label: 'Messages', icon: Icons.message),
                _DemoTabPage(label: 'Profile', icon: Icons.account_circle),
              ],
            ),
          ),
          // Native tab bar with custom Flutter icons
          Align(
            alignment: Alignment.bottomCenter,
            child: CNTabBar(
              items: [
                // Using CNCustomIcon with Flutter IconData
                CNTabBarItem(
                  label: 'Dashboard',
                  icon: CNCustomIcon(Icons.dashboard),
                ),
                CNTabBarItem(
                  label: 'Favorites',
                  icon: CNCustomIcon(Icons.favorite),
                ),
                CNTabBarItem(
                  label: 'Alerts',
                  icon: CNCustomIcon(Icons.roundabout_left),
                ),
                CNTabBarItem(
                  label: 'Messages',
                  icon: CNCustomIcon(Icons.message),
                ),
                CNTabBarItem(
                  label: 'Profile',
                  icon: CNCustomIcon(Icons.account_circle),
                ),
              ],
              currentIndex: _index,
              onTap: (i) {
                setState(() => _index = i);
                _controller.animateTo(i);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Demo page showing mixed SF Symbols and custom icons.
class TabBarMixedIconsDemoPage extends StatefulWidget {
  const TabBarMixedIconsDemoPage({super.key});

  @override
  State<TabBarMixedIconsDemoPage> createState() =>
      _TabBarMixedIconsDemoPageState();
}

class _TabBarMixedIconsDemoPageState extends State<TabBarMixedIconsDemoPage>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 4, vsync: this);
    _controller.addListener(() {
      final i = _controller.index;
      if (i != _index) setState(() => _index = i);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Mixed Icons Demo'),
      ),
      child: Stack(
        children: [
          // Content below
          Positioned.fill(
            child: TabBarView(
              controller: _controller,
              children: const [
                _DemoTabPage(label: 'Home (SF Symbol)', icon: Icons.home),
                _DemoTabPage(label: 'Flutter Icon', icon: Icons.flutter_dash),
                _DemoTabPage(
                  label: 'Settings (SF Symbol)',
                  icon: Icons.settings,
                ),
                _DemoTabPage(
                  label: 'Cupertino Icon',
                  icon: CupertinoIcons.heart,
                ),
              ],
            ),
          ),
          // Native tab bar with mixed icon types
          Align(
            alignment: Alignment.bottomCenter,
            child: CNTabBar(
              items: [
                // SF Symbol (native iOS icon)
                const CNTabBarItem(label: 'Home', icon: CNSymbol('house.fill')),
                // Flutter Material Icon
                CNTabBarItem(
                  label: 'Flutter',
                  icon: CNCustomIcon(Icons.flutter_dash),
                ),
                // SF Symbol
                const CNTabBarItem(
                  label: 'Settings',
                  icon: CNSymbol('gearshape.fill'),
                ),
                // Cupertino Icon (Flutter)
                CNTabBarItem(
                  label: 'Love',
                  icon: CNCustomIcon(CupertinoIcons.heart_fill),
                ),
              ],
              currentIndex: _index,
              split: true,
              rightCount: 1,
              onTap: (i) {
                setState(() => _index = i);
                _controller.animateTo(i);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoTabPage extends StatelessWidget {
  const _DemoTabPage({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark
          ? CupertinoColors.systemBackground.darkColor
          : CupertinoColors.systemBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: CupertinoTheme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tab content area',
              style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
            ),
          ],
        ),
      ),
    );
  }
}

/// Demo page showing third-party icons (flutter_islamic_icons) and custom font icons.
///
/// This tests that icon packages and custom fonts work with CNCustomIcon.
class TabBarThirdPartyIconsDemoPage extends StatefulWidget {
  const TabBarThirdPartyIconsDemoPage({super.key});

  @override
  State<TabBarThirdPartyIconsDemoPage> createState() =>
      _TabBarThirdPartyIconsDemoPageState();
}

class _TabBarThirdPartyIconsDemoPageState
    extends State<TabBarThirdPartyIconsDemoPage>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 5, vsync: this);
    _controller.addListener(() {
      final i = _controller.index;
      if (i != _index) setState(() => _index = i);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Third-Party & Custom Icons'),
      ),
      child: Stack(
        children: [
          // Content below
          Positioned.fill(
            child: TabBarView(
              controller: _controller,
              children: [
                _DemoTabPage(
                  label: 'Dashboard',
                  icon: Icons.dashboard,
                ),
                _DemoTabPage(
                  label: 'AI (Custom Font)',
                  icon: AiIcon.aiIcon,
                ),
                _DemoTabPage(
                  label: 'Quran (Islamic Icons)',
                  icon: FlutterIslamicIcons.solidQuran2,
                ),
                _DemoTabPage(
                  label: 'Prayer (Islamic Icons)',
                  icon: FlutterIslamicIcons.solidPrayingPerson,
                ),
                _DemoTabPage(
                  label: 'Profile',
                  icon: Icons.account_circle,
                ),
              ],
            ),
          ),
          // Native tab bar with third-party and custom icons
          Align(
            alignment: Alignment.bottomCenter,
            child: CNTabBar(
              items: [
                // Material Icon
                CNTabBarItem(
                  label: 'Dashboard',
                  icon: CNCustomIcon(Icons.dashboard),
                ),
                // Custom font icon (AiIcon)
                CNTabBarItem(
                  label: 'AI',
                  icon: CNCustomIcon(AiIcon.aiIcon),
                ),
                // flutter_islamic_icons package
                CNTabBarItem(
                  label: 'Quran',
                  icon: CNCustomIcon(FlutterIslamicIcons.solidQuran2),
                ),
                // flutter_islamic_icons package
                CNTabBarItem(
                  label: 'Prayer',
                  icon: CNCustomIcon(FlutterIslamicIcons.solidPrayingPerson),
                ),
                // Material Icon
                CNTabBarItem(
                  label: 'Profile',
                  icon: CNCustomIcon(Icons.account_circle),
                ),
              ],
              currentIndex: _index,
              onTap: (i) {
                setState(() => _index = i);
                _controller.animateTo(i);
              },
            ),
          ),
        ],
      ),
    );
  }
}
