import 'dart:convert';
import 'dart:io';

import 'package:truetun/src/profiles/hysteria2_profile_parser.dart';
import 'package:truetun/src/profiles/profile_group.dart';
import 'package:truetun/src/profiles/proxy_node.dart';
import 'package:truetun/src/profiles/proxy_profile_parser.dart';
import 'package:truetun/src/profiles/vless_link_parser.dart';

class SubscriptionException implements Exception {
  const SubscriptionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SubscriptionService {
  const SubscriptionService({
    this.parser = const ProxyProfileParser(),
    this.hysteria2Parser = const Hysteria2ProfileParser(),
    this.maxResponseBytes = 5 * 1024 * 1024,
  });

  final ProxyProfileParser parser;
  final Hysteria2ProfileParser hysteria2Parser;
  final int maxResponseBytes;

  Future<List<ManagedProfile>> fetch(Uri url) async {
    if (url.scheme != 'https' && url.scheme != 'http') {
      throw const SubscriptionException(
        'Subscription URL must use HTTPS or HTTP',
      );
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(url);
      request.headers.set(HttpHeaders.userAgentHeader, 'TrueTun/0.2');
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
    if (_looksStructured(content)) {
      final structured = _parseStructured(content);
      if (structured.isNotEmpty) return structured;
    }

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
      if (_looksStructured(content)) {
        final structured = _parseStructured(content);
        if (structured.isNotEmpty) return structured;
      }
    }

    final profiles = <ManagedProfile>[];
    final seen = <String>{};
    for (final rawLine in const LineSplitter().convert(content)) {
      final line = rawLine.trim();
      if (!_isSupportedShareLink(line)) continue;
      try {
        final node = parser.parse(line);
        _appendNode(profiles, seen, node);
      } on ProfileParseException {
        // One malformed node must not invalidate other valid subscription nodes.
      }
    }
    if (profiles.isEmpty) {
      throw const SubscriptionException(
        'Subscription contains no valid supported proxy nodes',
      );
    }
    return List.unmodifiable(profiles);
  }

  List<ManagedProfile> _parseStructured(String content) {
    final profiles = <ManagedProfile>[];
    final seen = <String>{};
    for (final node in hysteria2Parser.parseMany(content)) {
      _appendNode(profiles, seen, node);
    }
    return List.unmodifiable(profiles);
  }

  void _appendNode(
    List<ManagedProfile> profiles,
    Set<String> seen,
    ProxyNode node,
  ) {
    final id = _fingerprint(node);
    if (seen.add(id)) profiles.add(ManagedProfile(id: id, node: node));
  }

  String _fingerprint(ProxyNode node) {
    final credential = switch (node) {
      VlessNode() => node.uuid,
      Hysteria2Node() => node.password,
    };
    var hash = 0xcbf29ce484222325;
    for (final byte in utf8.encode(
      '${node.protocol.name}:${node.server}:${node.port}:$credential:${node.name}',
    )) {
      hash ^= byte;
      hash = (hash * 0x100000001b3) & 0x7fffffffffffffff;
    }
    return hash.toRadixString(16);
  }

  bool _isSupportedShareLink(String line) {
    final normalized = line.toLowerCase();
    return normalized.startsWith('vless://') ||
        normalized.startsWith('hysteria2://') ||
        normalized.startsWith('hy2://');
  }

  bool _looksStructured(String content) {
    final normalized = content.trimLeft();
    if (normalized.startsWith('{')) return true;
    return RegExp(
      r'(^|\n)\s*(proxies|outbounds|server)\s*:',
      caseSensitive: false,
    ).hasMatch(content);
  }
}
