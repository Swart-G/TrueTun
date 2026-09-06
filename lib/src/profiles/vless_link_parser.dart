import 'package:truetun/src/profiles/proxy_node.dart';

class ProfileParseException implements Exception {
  const ProfileParseException(this.message);

  final String message;

  @override
  String toString() => 'ProfileParseException: $message';
}

class VlessLinkParser {
  const VlessLinkParser();

  VlessNode parse(String rawLink) {
    final uri = Uri.tryParse(rawLink.trim());
    if (uri == null || uri.scheme.toLowerCase() != 'vless') {
      throw const ProfileParseException('Input is not a VLESS link');
    }

    final uuid = uri.userInfo.trim();
    if (!_uuidPattern.hasMatch(uuid)) {
      throw const ProfileParseException('VLESS UUID is missing or invalid');
    }
    if (uri.host.isEmpty) {
      throw const ProfileParseException('VLESS server host is missing');
    }
    if (!uri.hasPort || uri.port <= 0 || uri.port > 65535) {
      throw const ProfileParseException('VLESS server port is missing or invalid');
    }

    final query = uri.queryParameters;
    final security = (query['security'] ?? 'none').toLowerCase();
    final tlsEnabled = security == 'tls' || security == 'reality';

    RealityOptions? reality;
    if (security == 'reality') {
      final publicKey = _firstNonEmpty(query['pbk'], query['publicKey']);
      if (publicKey == null) {
        throw const ProfileParseException('Reality public key is missing');
      }
      reality = RealityOptions(
        publicKey: publicKey,
        shortId: _firstNonEmpty(query['sid'], query['shortId']) ?? '',
      );
    }

    final alpn = (query['alpn'] ?? '')
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    final tls = TlsOptions(
      enabled: tlsEnabled,
      serverName: _firstNonEmpty(query['sni'], query['serverName']),
      alpn: alpn,
      insecure: _isTruthy(query['allowInsecure']) || _isTruthy(query['insecure']),
      fingerprint: _firstNonEmpty(query['fp'], query['fingerprint']),
      reality: reality,
    );

    final type = (query['type'] ?? 'tcp').toLowerCase();
    final headerType = (query['headerType'] ?? '').toLowerCase();
    final transportType = _parseTransport(type, headerType: headerType);
    final transport = V2RayTransportOptions(
      type: transportType,
      host: _firstNonEmpty(query['host'], query['authority']),
      path: _firstNonEmpty(query['path'], query['spx']),
      serviceName: _firstNonEmpty(query['serviceName'], query['service_name']),
      mode: query['mode']?.trim().isEmpty == true ? null : query['mode']?.trim(),
    );

    final fragment = uri.fragment.trim();
    final name = fragment.isEmpty ? '${uri.host}:${uri.port}' : Uri.decodeComponent(fragment);

    return VlessNode(
      name: name,
      server: uri.host,
      port: uri.port,
      uuid: uuid,
      flow: _emptyToNull(query['flow']),
      packetEncoding: _firstNonEmpty(query['packetEncoding'], query['packet_encoding']),
      tls: tls,
      transport: transport,
    );
  }

  V2RayTransportType _parseTransport(
    String type, {
    required String headerType,
  }) {
    if (type == 'tcp' && headerType == 'http') {
      return V2RayTransportType.http;
    }

    return switch (type) {
      'tcp' => V2RayTransportType.tcp,
      'http' => V2RayTransportType.http,
      'ws' || 'websocket' => V2RayTransportType.websocket,
      'grpc' => V2RayTransportType.grpc,
      'httpupgrade' => V2RayTransportType.httpUpgrade,
      'quic' => V2RayTransportType.quic,
      'xhttp' || 'splithttp' => V2RayTransportType.xhttp,
      _ => throw ProfileParseException('Unsupported VLESS transport: $type'),
    };
  }

  String? _firstNonEmpty(String? first, String? second) {
    return _emptyToNull(first) ?? _emptyToNull(second);
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  bool _isTruthy(String? value) {
    return switch (value?.trim().toLowerCase()) {
      '1' || 'true' || 'yes' => true,
      _ => false,
    };
  }

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
}
