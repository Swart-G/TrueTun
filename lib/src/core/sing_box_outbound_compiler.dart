import 'package:truetun/src/profiles/proxy_node.dart';

class OutboundCompileException implements Exception {
  const OutboundCompileException(this.message);

  final String message;

  @override
  String toString() => 'OutboundCompileException: $message';
}

class SingBoxOutboundCompiler {
  const SingBoxOutboundCompiler();

  Map<String, Object> compile(
    ProxyNode node, {
    required String tag,
  }) {
    return switch (node) {
      VlessNode() => compileVless(node, tag: tag),
      Hysteria2Node() => compileHysteria2(node, tag: tag),
    };
  }

  Map<String, Object> compileVless(
    VlessNode node, {
    required String tag,
  }) {
    final result = <String, Object>{
      'type': 'vless',
      'tag': tag,
      'server': node.server,
      'server_port': node.port,
      'uuid': node.uuid,
    };

    final flow = node.flow?.trim();
    if (flow != null && flow.isNotEmpty) result['flow'] = flow;

    final packetEncoding = _compilePacketEncoding(node.packetEncoding);
    if (packetEncoding != null) result['packet_encoding'] = packetEncoding;

    final tls = _compileTls(node.tls);
    if (tls != null) result['tls'] = tls;

    final transport = _compileTransport(node.transport);
    if (transport != null) result['transport'] = transport;

    return result;
  }

  Map<String, Object> compileHysteria2(
    Hysteria2Node node, {
    required String tag,
  }) {
    if (!node.tls.enabled) {
      throw const OutboundCompileException('Hysteria2 requires TLS');
    }
    final tls = _compileTls(node.tls);
    if (tls == null) {
      throw const OutboundCompileException(
          'Hysteria2 TLS configuration is missing');
    }

    final result = <String, Object>{
      'type': 'hysteria2',
      'tag': tag,
      'server': node.server,
      if (node.serverPorts.isEmpty) 'server_port': node.port,
      if (node.serverPorts.isNotEmpty) 'server_ports': node.serverPorts,
      'password': node.password,
      'tls': tls,
    };

    final hopInterval = node.hopInterval?.trim();
    if (hopInterval != null && hopInterval.isNotEmpty) {
      result['hop_interval'] = hopInterval;
    }
    final hopIntervalMax = node.hopIntervalMax?.trim();
    if (hopIntervalMax != null && hopIntervalMax.isNotEmpty) {
      result['hop_interval_max'] = hopIntervalMax;
    }
    if (node.upMbps != null) result['up_mbps'] = node.upMbps!;
    if (node.downMbps != null) result['down_mbps'] = node.downMbps!;

    final obfs = node.obfs;
    if (obfs != null) {
      result['obfs'] = <String, Object>{
        'type': obfs.type,
        'password': obfs.password,
        if (obfs.minPacketSize != null) 'min_packet_size': obfs.minPacketSize!,
        if (obfs.maxPacketSize != null) 'max_packet_size': obfs.maxPacketSize!,
      };
    }
    return result;
  }

  String? _compilePacketEncoding(String? raw) {
    final value = raw?.trim().toLowerCase();
    if (value == null || value.isEmpty) return null;
    return switch (value) {
      // VLESS share links commonly spell the disabled value as "none", while
      // sing-box represents it as an empty packet_encoding string.
      'none' => '',
      'xudp' => 'xudp',
      'packetaddr' => 'packetaddr',
      _ => throw OutboundCompileException(
          'Unsupported VLESS packet encoding: $raw',
        ),
    };
  }

  Map<String, Object>? _compileTls(TlsOptions options) {
    if (!options.enabled) return null;

    final result = <String, Object>{'enabled': true};
    final serverName = options.serverName?.trim();
    if (serverName != null && serverName.isNotEmpty) {
      result['server_name'] = serverName;
    }
    if (options.alpn.isNotEmpty) result['alpn'] = options.alpn;
    if (options.insecure) result['insecure'] = true;

    final fingerprint = options.fingerprint?.trim();
    if (fingerprint != null && fingerprint.isNotEmpty) {
      result['utls'] = <String, Object>{
        'enabled': true,
        'fingerprint': fingerprint,
      };
    }

    final reality = options.reality;
    if (reality != null) {
      result['reality'] = <String, Object>{
        'enabled': true,
        'public_key': reality.publicKey,
        'short_id': reality.shortId,
      };
    }

    return result;
  }

  Map<String, Object>? _compileTransport(V2RayTransportOptions options) {
    switch (options.type) {
      case V2RayTransportType.tcp:
        return null;
      case V2RayTransportType.http:
        return <String, Object>{
          'type': 'http',
          if (_notEmpty(options.host)) 'host': <String>[options.host!.trim()],
          if (_notEmpty(options.path)) 'path': options.path!.trim(),
        };
      case V2RayTransportType.websocket:
        return <String, Object>{
          'type': 'ws',
          if (_notEmpty(options.path)) 'path': options.path!.trim(),
          if (_notEmpty(options.host))
            'headers': <String, Object>{'Host': options.host!.trim()},
        };
      case V2RayTransportType.grpc:
        return <String, Object>{
          'type': 'grpc',
          if (_notEmpty(options.serviceName))
            'service_name': options.serviceName!.trim(),
        };
      case V2RayTransportType.httpUpgrade:
        return <String, Object>{
          'type': 'httpupgrade',
          if (_notEmpty(options.host)) 'host': options.host!.trim(),
          if (_notEmpty(options.path)) 'path': options.path!.trim(),
        };
      case V2RayTransportType.quic:
        return <String, Object>{'type': 'quic'};
      case V2RayTransportType.xhttp:
        return <String, Object>{
          'type': 'xhttp',
          if (_notEmpty(options.mode)) 'mode': options.mode!.trim(),
          if (_notEmpty(options.host)) 'host': options.host!.trim(),
          if (_notEmpty(options.path)) 'path': options.path!.trim(),
          'x_padding_bytes': '100-1000',
        };
    }
  }

  bool _notEmpty(String? value) => value != null && value.trim().isNotEmpty;
}
