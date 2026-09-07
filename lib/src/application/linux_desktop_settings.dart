import 'dart:io';

import 'package:path/path.dart' as p;

class LinuxDesktopSettings {
  const LinuxDesktopSettings();

  File get _autostartFile {
    final config = Platform.environment['XDG_CONFIG_HOME']?.trim();
    final root = config == null || config.isEmpty
        ? p.join(Platform.environment['HOME']!, '.config')
        : config;
    return File(p.join(root, 'autostart', 'truetun.desktop'));
  }

  Future<bool> isAutostartEnabled() => _autostartFile.exists();

  Future<void> setAutostart(bool enabled) async {
    final file = _autostartFile;
    if (!enabled) {
      if (await file.exists()) await file.delete();
      return;
    }
    await file.parent.create(recursive: true);
    final launcher = p.join(p.dirname(Platform.resolvedExecutable), 'truetun');
    final escaped = launcher.replaceAll(r'\', r'\\').replaceAll(' ', r'\ ');
    await file.writeAsString(
      '[Desktop Entry]\nType=Application\nName=TrueTun\n'
      'Comment=Start TrueTun in the system tray\nExec=$escaped --hidden\n'
      'Terminal=false\nX-GNOME-Autostart-enabled=true\n',
      flush: true,
    );
  }
}
