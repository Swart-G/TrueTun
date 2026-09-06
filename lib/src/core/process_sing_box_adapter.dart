import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:truetun/src/core/core_adapter.dart';

/// Linux/development adapter that runs a sing-box-compatible executable.
///
/// Production Android will use a native mobile binding behind the same
/// [ProxyCoreAdapter] interface instead of spawning a process.
class ProcessSingBoxAdapter implements ProxyCoreAdapter {
  ProcessSingBoxAdapter({String? executable}) : _executable = executable;

  final String? _executable;
  final StreamController<CoreEvent> _events = StreamController.broadcast();

  Process? _process;
  Directory? _runtimeDirectory;
  ProxyCoreState _state = ProxyCoreState.stopped;

  @override
  ProxyCoreState get state => _state;

  @override
  Stream<CoreEvent> get events => _events.stream;

  @override
  Future<CoreCapabilities> getCapabilities() async {
    final executable = _resolveExecutable();
    final result = await Process.run(executable, const ['version']);
    if (result.exitCode != 0) {
      throw CoreException('Unable to execute $executable: ${result.stderr}');
    }

    final output = result.stdout.toString().trim();
    final firstLine = output.split('\n').firstOrNull ?? 'sing-box';
    return CoreCapabilities(
      name: 'sing-box compatible',
      version: firstLine,
      protocols: const {
        'vless',
        'vmess',
        'trojan',
        'shadowsocks',
        'hysteria2',
        'tuic',
        'ssh',
        'wireguard',
      },
      features: const {'tun', 'route-rules', 'rule-sets', 'urltest', 'xhttp'},
    );
  }

  @override
  Future<void> validateConfig(String configJson) async {
    final helper = _resolveHelper();
    if (helper != null) {
      final process = await _startHelper(helper, 'check', configJson);
      final output = await Future.wait([
        process.stdout.transform(utf8.decoder).join(),
        process.stderr.transform(utf8.decoder).join(),
      ]);
      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        final details = output[1].trim();
        throw CoreException(
          details.isEmpty
              ? 'Privileged core validation failed with code $exitCode'
              : details,
        );
      }
      return;
    }

    final executable = _resolveExecutable();
    final directory = await Directory.systemTemp.createTemp('truetun-check-');
    try {
      final file = File('${directory.path}/config.json');
      await file.writeAsString(configJson, flush: true);
      final result = await Process.run(executable, ['check', '-c', file.path]);
      if (result.exitCode != 0) {
        final details = result.stderr.toString().trim();
        throw CoreException(
            details.isEmpty ? 'Core rejected configuration' : details);
      }
    } finally {
      await directory.delete(recursive: true);
    }
  }

  @override
  Future<void> start(String configJson) async {
    if (_state != ProxyCoreState.stopped && _state != ProxyCoreState.failed) {
      throw CoreException('Core cannot start from state $_state');
    }

    _setState(ProxyCoreState.starting);
    try {
      await validateConfig(configJson);
      final helper = _resolveHelper();
      final Process process;
      if (helper != null) {
        process = await _startHelper(helper, 'run', configJson);
      } else {
        _runtimeDirectory =
            await Directory.systemTemp.createTemp('truetun-run-');
        final configFile = File('${_runtimeDirectory!.path}/config.json');
        await configFile.writeAsString(configJson, flush: true);
        process = await Process.start(
          _resolveExecutable(),
          ['run', '-c', configFile.path],
          runInShell: false,
        );
      }
      _process = process;

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) => _events.add(CoreLogLine(line, isError: false)));
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) => _events.add(CoreLogLine(line, isError: true)));

      _setState(ProxyCoreState.running);
      unawaited(_watchExit(process));
    } catch (error) {
      _setState(ProxyCoreState.failed);
      _events.add(CoreFailure(error.toString()));
      await _cleanupRuntimeDirectory();
      rethrow;
    }
  }

  Future<void> _watchExit(Process process) async {
    final exitCode = await process.exitCode;
    if (!identical(_process, process)) return;

    _process = null;
    await _cleanupRuntimeDirectory();
    if (_state == ProxyCoreState.stopping) {
      _setState(ProxyCoreState.stopped);
      return;
    }

    if (exitCode == 0) {
      _setState(ProxyCoreState.stopped);
    } else {
      _setState(ProxyCoreState.failed);
      _events.add(CoreFailure('Core exited with code $exitCode'));
    }
  }

  @override
  Future<void> stop() async {
    final process = _process;
    if (process == null) {
      _setState(ProxyCoreState.stopped);
      await _cleanupRuntimeDirectory();
      return;
    }

    _setState(ProxyCoreState.stopping);
    process.kill(ProcessSignal.sigterm);
    await process.exitCode;
  }

  void _setState(ProxyCoreState value) {
    _state = value;
    _events.add(CoreStateChanged(value));
  }

  Future<void> _cleanupRuntimeDirectory() async {
    final directory = _runtimeDirectory;
    _runtimeDirectory = null;
    if (directory != null && await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<Process> _startHelper(
    String helper,
    String command,
    String configJson,
  ) async {
    final process = await Process.start(
      'sudo',
      ['-n', '--', helper, command],
      runInShell: false,
    );
    process.stdin.write(configJson);
    await process.stdin.close();
    return process;
  }

  String? _resolveHelper() {
    final helper = Platform.environment['TRUETUN_CORE_HELPER']?.trim();
    if (helper != null && helper.isNotEmpty && File(helper).existsSync()) {
      return helper;
    }
    return null;
  }

  String _resolveExecutable() {
    final configured = _executable?.trim();
    if (configured != null && configured.isNotEmpty) return configured;

    final installed = Platform.environment['TRUETUN_CORE_PATH']?.trim();
    if (installed != null &&
        installed.isNotEmpty &&
        File(installed).existsSync()) {
      return installed;
    }

    if (Platform.isLinux) {
      final bundled =
          File(p.join(p.dirname(Platform.resolvedExecutable), 'sing-box'));
      if (bundled.existsSync()) return bundled.path;
    }
    return 'sing-box';
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
