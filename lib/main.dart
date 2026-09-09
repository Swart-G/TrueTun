import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart' as tray;
import 'package:truetun/src/android_mobile_app_v2.dart';
import 'package:truetun/src/application/app_state.dart';
import 'package:truetun/src/core/core_adapter.dart';
import 'package:truetun/src/linux_desktop_app.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isLinux) {
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);
  }
  runApp(
    ProviderScope(
      child: _DesktopLifecycle(
        startHidden: arguments.contains('--hidden'),
        child: Platform.isAndroid
            ? const TrueTunAndroidApp()
            : const TrueTunLinuxApp(),
      ),
    ),
  );
}

class _DesktopLifecycle extends ConsumerStatefulWidget {
  const _DesktopLifecycle({required this.startHidden, required this.child});

  final bool startHidden;
  final Widget child;

  @override
  ConsumerState<_DesktopLifecycle> createState() => _DesktopLifecycleState();
}

class _DesktopLifecycleState extends ConsumerState<_DesktopLifecycle>
    with WindowListener, tray.TrayListener {
  bool _quitting = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isLinux) {
      windowManager.addListener(this);
      tray.trayManager.addListener(this);
      WidgetsBinding.instance.addPostFrameCallback((_) => _initializeDesktop());
    }
  }

  Future<void> _initializeDesktop() async {
    await tray.trayManager.setIcon('assets/tray_icon.png');
    await tray.trayManager.setContextMenu(
      tray.Menu(
        items: [
          tray.MenuItem(key: 'show', label: 'Show TrueTun'),
          tray.MenuItem(key: 'hide', label: 'Hide to tray'),
          tray.MenuItem.separator(),
          tray.MenuItem(key: 'quit', label: 'Quit'),
        ],
      ),
    );
    if (widget.startHidden) await windowManager.hide();
  }

  Future<void> _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  void onWindowClose() {
    if (_quitting) return;
    if (ref.read(appControllerProvider).minimizeToTray) {
      windowManager.hide();
    } else {
      _quit();
    }
  }

  @override
  void onTrayIconMouseDown() => _showWindow();

  @override
  void onTrayMenuItemClick(tray.MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        _showWindow();
      case 'hide':
        windowManager.hide();
      case 'quit':
        _quit();
    }
  }

  Future<void> _quit() async {
    _quitting = true;
    final controller = ref.read(appControllerProvider.notifier);
    if (ref.read(appControllerProvider).coreState != ProxyCoreState.stopped) {
      await controller.disconnect();
    }
    await tray.trayManager.destroy();
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  @override
  void dispose() {
    if (Platform.isLinux) {
      windowManager.removeListener(this);
      tray.trayManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
