import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:truetun/src/core/sing_box_outbound_compiler.dart';
import 'package:truetun/src/profiles/proxy_node.dart';

class TrafficSnapshot {
  const TrafficSnapshot({required this.upload, required this.download});

  final int upload;
  final int download;
}

class ConnectionTestResult {
  const ConnectionTestResult({required this.latency, required this.statusCode});

  final Duration latency;
  final int statusCode;
}

class ConnectionDiagnostics {
  const ConnectionDiagnostics({this.apiPort = 19090});

  final int apiPort;

  Future<Duration> testEndpoint(String server, int port) async {
    final attempts = <Duration>[];
    for (var attempt = 0; attempt < 3; attempt++) {
      final stopwatch = Stopwatch()..start();
      Socket? socket;
      try {
        socket = await Socket.connect(
          server,
          port,
          timeout: const Duration(seconds: 4),
        );
        stopwatch.stop();
        attempts.add(stopwatch.elapsed);
      } finally {
        socket?.destroy();
      }
    }
    attempts.sort();
    return attempts[attempts.length ~/ 2];
  }

  Future<Duration> testProfile(VlessNode node) async {
    final listener = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = listener.port;
    await listener.close();
    final directory = await Directory.systemTemp.createTemp('truetun-ping-');
    Process? process;
    try {
      final config = <String, Object>{
        'log': <String, Object>{'disabled': true},
        'dns': <String, Object>{
          'servers': <Map<String, Object>>[
            <String, Object>{'type': 'local', 'tag': 'local-dns'},
          ],
          'final': 'local-dns',
        },
        'inbounds': <Map<String, Object>>[
          <String, Object>{
            'type': 'mixed',
            'tag': 'ping-in',
            'listen': '127.0.0.1',
            'listen_port': port,
          },
        ],
        'outbounds': <Map<String, Object>>[
          const SingBoxOutboundCompiler().compileVless(node, tag: 'proxy'),
        ],
        'route': <String, Object>{
          'default_domain_resolver': 'local-dns',
          'final': 'proxy',
        },
      };
      final file = File(p.join(directory.path, 'config.json'));
      await file.writeAsString(jsonEncode(config), flush: true);
      process = await Process.start(
        _resolveCore(),
        ['run', '-c', file.path],
        runInShell: false,
      );
      process.stdout.drain<void>();
      process.stderr.drain<void>();
      await _waitForPort(port, process);
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5)
        ..findProxy = (_) => 'PROXY 127.0.0.1:$port';
      final stopwatch = Stopwatch()..start();
      try {
        final request = await client.getUrl(
          Uri.parse('https://cp.cloudflare.com/generate_204'),
        );
        final response = await request.close().timeout(
              const Duration(seconds: 7),
            );
        await response.drain<void>();
        stopwatch.stop();
        if (response.statusCode < 200 || response.statusCode >= 400) {
          throw HttpException('Unexpected status ${response.statusCode}');
        }
        return stopwatch.elapsed;
      } finally {
        client.close(force: true);
      }
    } finally {
      process?.kill(ProcessSignal.sigterm);
      if (process != null) await process.exitCode;
      await directory.delete(recursive: true);
    }
  }

  Future<void> _waitForPort(int port, Process process) async {
    for (var attempt = 0; attempt < 30; attempt++) {
      if (await _hasExited(process)) {
        throw const HttpException('Profile test core failed to start');
      }
      try {
        final socket = await Socket.connect(
          InternetAddress.loopbackIPv4,
          port,
          timeout: const Duration(milliseconds: 100),
        );
        socket.destroy();
        return;
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
    throw const HttpException('Profile test core timed out');
  }

  Future<bool> _hasExited(Process process) async {
    final sentinel = Object();
    final result = await Future.any<Object>([
      process.exitCode.then<Object>((_) => true),
      Future<Object>.delayed(Duration.zero, () => sentinel),
    ]);
    return result != sentinel;
  }

  String _resolveCore() {
    final configured = Platform.environment['TRUETUN_CORE_PATH']?.trim();
    if (configured != null && configured.isNotEmpty) return configured;
    final bundled =
        File(p.join(p.dirname(Platform.resolvedExecutable), 'sing-box'));
    return bundled.existsSync() ? bundled.path : 'sing-box';
  }

  Future<ConnectionTestResult> testConnection() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    final stopwatch = Stopwatch()..start();
    try {
      final request = await client.getUrl(
        Uri.parse('https://cp.cloudflare.com/generate_204'),
      );
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      final response =
          await request.close().timeout(const Duration(seconds: 10));
      await response.drain<void>();
      stopwatch.stop();
      if (response.statusCode < 200 || response.statusCode >= 400) {
        throw HttpException('Unexpected status ${response.statusCode}');
      }
      return ConnectionTestResult(
        latency: stopwatch.elapsed,
        statusCode: response.statusCode,
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<TrafficSnapshot> readTraffic() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    try {
      final request = await client.getUrl(
        Uri.parse('http://127.0.0.1:$apiPort/connections'),
      );
      final response =
          await request.close().timeout(const Duration(seconds: 2));
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Metrics API returned ${response.statusCode}');
      }
      final body = await utf8.decoder.bind(response).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      return TrafficSnapshot(
        upload: (json['uploadTotal'] as num?)?.toInt() ?? 0,
        download: (json['downloadTotal'] as num?)?.toInt() ?? 0,
      );
    } finally {
      client.close(force: true);
    }
  }
}
