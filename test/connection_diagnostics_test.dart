import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:truetun/src/core/connection_diagnostics.dart';

void main() {
  test('endpoint latency performs real TCP connection attempts', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final subscription = server.listen((socket) => socket.destroy());
    try {
      final latency = await const ConnectionDiagnostics().testEndpoint(
        InternetAddress.loopbackIPv4.address,
        server.port,
      );
      expect(latency, isA<Duration>());
      expect(latency.inMilliseconds, greaterThanOrEqualTo(0));
    } finally {
      await subscription.cancel();
      await server.close();
    }
  });

  test('speed test measures real download and upload payloads', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var uploadedBytes = 0;
    final subscription = server.listen((request) async {
      if (request.uri.path == '/__down') {
        final bytes = int.parse(request.uri.queryParameters['bytes'] ?? '0');
        if (bytes > 0) request.response.add(List<int>.filled(bytes, 7));
      } else if (request.uri.path == '/__up') {
        uploadedBytes = await request.fold<int>(
          0,
          (total, chunk) => total + chunk.length,
        );
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      await request.response.close();
    });

    try {
      final result = await ConnectionDiagnostics(
        speedTestBaseUrl:
            'http://${InternetAddress.loopbackIPv4.address}:${server.port}',
      ).testSpeed(downloadBytes: 64 * 1024, uploadBytes: 32 * 1024);

      expect(result.latency, isA<Duration>());
      expect(result.downloadBytesPerSecond, greaterThan(0));
      expect(result.uploadBytesPerSecond, greaterThan(0));
      expect(uploadedBytes, 32 * 1024);
    } finally {
      await subscription.cancel();
      await server.close(force: true);
    }
  });
}
