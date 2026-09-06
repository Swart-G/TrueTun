import 'package:flutter/material.dart';

class TrueTunApp extends StatelessWidget {
  const TrueTunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TrueTun',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF625BFF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8D87FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _destinations = <NavigationDestination>[
    NavigationDestination(icon: Icon(Icons.power_settings_new), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.dns_outlined), label: 'Profiles'),
    NavigationDestination(icon: Icon(Icons.alt_route), label: 'Routing'),
    NavigationDestination(icon: Icon(Icons.apps), label: 'Apps'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
  ];

  static const _pages = <Widget>[
    _HomePage(),
    _PlaceholderPage(
      title: 'Profiles',
      body: 'Subscriptions and single VLESS/VMess/Trojan/etc. links live here.',
      icon: Icons.dns_outlined,
    ),
    _PlaceholderPage(
      title: 'Routing',
      body: 'Ordered Mihomo-style rules, rule sets and proxy groups live here.',
      icon: Icons.alt_route,
    ),
    _PlaceholderPage(
      title: 'Apps',
      body: 'Android include/exclude app routing and smart local suggestions live here.',
      icon: Icons.apps,
    ),
    _PlaceholderPage(
      title: 'Settings',
      body: 'Core, TUN, DNS, updates, diagnostics and appearance live here.',
      icon: Icons.settings_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        if (!desktop) {
          return Scaffold(
            body: SafeArea(child: _pages[_index]),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              destinations: _destinations,
              onDestinationSelected: (value) => setState(() => _index = value),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  labelType: NavigationRailLabelType.all,
                  leading: const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: _BrandMark(),
                  ),
                  destinations: _destinations
                      .map(
                        (item) => NavigationRailDestination(
                          icon: item.icon,
                          selectedIcon: item.selectedIcon,
                          label: Text(item.label),
                        ),
                      )
                      .toList(growable: false),
                  onDestinationSelected: (value) => setState(() => _index = value),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _pages[_index]),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'TrueTun',
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.shield_outlined),
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('TrueTun', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
          'Proxy client foundation for Android and Linux',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        Center(
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(
              fixedSize: const Size(160, 160),
              shape: const CircleBorder(),
            ),
            onPressed: null,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.power_settings_new, size: 42),
                SizedBox(height: 10),
                Text('No profile'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        const _StatusCard(
          icon: Icons.route_outlined,
          title: 'Routing engine',
          value: 'Ready for rules',
        ),
        const SizedBox(height: 12),
        const _StatusCard(
          icon: Icons.memory_outlined,
          title: 'Core adapter',
          value: 'sing-box compatible',
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.icon, required this.title, required this.value});

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 56),
              const SizedBox(height: 20),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(body, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
