import 'dart:convert';
import 'dart:io';

import 'package:truetun/src/profiles/profile_group.dart';
import 'package:truetun/src/profiles/vless_link_parser.dart';

class SubscriptionException implements Exception {
  const SubscriptionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SubscriptionService {
  const SubscriptionService({
    this.parser = const VlessLinkParser(),
    this.maxResponseBytes = 5 * 1024 * 1024,
  });

  final VlessLinkParser parser;
  final int maxResponseBytes;

  Future<List<ManagedProfile>> fetch(Uri url) async {
    if (url.scheme != 'https' && url.scheme != 'http') {
      throw const SubscriptionException(
          'Subscription URL must use HTTPS or HTTP');
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(url);
      request.headers.set(HttpHeaders.userAgentHeader, 'TrueTun/0.1 Linux');
      request.headers.set(HttpHeaders.acceptHeader, 'text/plain, */*');
      final response =
          await request.close().timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SubscriptionException(
          'Subscription server returned HTTP ${response.statusCode}',
        );
      }
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
        if (bytes.length > maxResponseBytes) {
          throw const SubscriptionException(
              'Subscription response is too large');
        }
      }
      return parse(utf8.decode(bytes));
    } on SubscriptionException {
      rethrow;
    } catch (_) {
      throw const SubscriptionException('Unable to download subscription');
    } finally {
      client.close(force: true);
    }
  }

  List<ManagedProfile> parse(String responseBody) {
    var content = responseBody.trim();
    if (!content.contains('://')) {
      try {
        content = utf8.decode(base64.decode(base64.normalize(content)));
      } catch (_) {
        try {
          content = utf8.decode(base64Url.decode(base64Url.normalize(content)));
        } catch (_) {
          throw const SubscriptionException(
              'Unsupported subscription encoding');
        }
      }
    }

    final profiles = <ManagedProfile>[];
    final seen = <String>{};
    for (final rawLine in const LineSplitter().convert(content)) {
      final line = rawLine.trim();
      if (!line.toLowerCase().startsWith('vless://')) continue;
      try {
        final node = parser.parse(line);
        final id = _fingerprint(node.server, node.port, node.uuid, node.name);
        if (seen.add(id)) profiles.add(ManagedProfile(id: id, node: node));
      } on ProfileParseException {
        // One malformed node must not invalidate other valid subscription nodes.
      }
    }
    if (profiles.isEmpty) {
      throw const SubscriptionException(
          'Subscription contains no valid VLESS nodes');
    }
    return List.unmodifiable(profiles);
  }

  String _fingerprint(String server, int port, String uuid, String name) {
    var hash = 0xcbf29ce484222325;
    for (final byte in utf8.encode('$server:$port:$uuid:$name')) {
      hash ^= byte;
      hash = (hash * 0x100000001b3) & 0x7fffffffffffffff;
    }
    return hash.toRadixString(16);
  }
}
