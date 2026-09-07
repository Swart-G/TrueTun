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
}
