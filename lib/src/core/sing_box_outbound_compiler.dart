import 'package:truetun/src/profiles/proxy_node.dart';

class OutboundCompileException implements Exception {
  const OutboundCompileException(this.message);

  final String message;

  @override
  String toString() => 'OutboundCompileException: $message';
}

class SingBoxOutboundCompiler {
  const SingBoxOutboundCompiler();

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

    final packetEncoding = node.packetEncoding?.trim();
    if (packetEncoding != null && packetEncoding.isNotEmpty) {
      result['packet_encoding'] = packetEncoding;
    }

    final tls = _compileTls(node.tls);
    if (tls != null) result['tls'] = tls;

    final transport = _compileTransport(node.transport);
    if (transport != null) result['transport'] = transport;

    return result;
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
