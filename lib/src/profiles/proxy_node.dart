enum ProxyProtocol {
  vless,
  vmess,
  trojan,
  shadowsocks,
  hysteria2,
  tuic,
  ssh,
  wireguard,
}

enum V2RayTransportType {
  tcp,
  http,
  websocket,
  grpc,
  httpUpgrade,
  quic,
  xhttp,
}

class RealityOptions {
  const RealityOptions({
    required this.publicKey,
    required this.shortId,
  });

  final String publicKey;
  final String shortId;
}

class TlsOptions {
  const TlsOptions({
    required this.enabled,
    this.serverName,
    this.alpn = const [],
    this.insecure = false,
    this.fingerprint,
    this.reality,
  });

  final bool enabled;
  final String? serverName;
  final List<String> alpn;
  final bool insecure;
  final String? fingerprint;
  final RealityOptions? reality;
}

class V2RayTransportOptions {
  const V2RayTransportOptions({
    required this.type,
    this.host,
    this.path,
    this.serviceName,
    this.mode,
  });

  final V2RayTransportType type;
  final String? host;
  final String? path;
  final String? serviceName;

  /// Extended-transport option, currently used by XHTTP imports.
  final String? mode;
}

sealed class ProxyNode {
  const ProxyNode({
    required this.name,
    required this.server,
    required this.port,
    required this.protocol,
  });

  final String name;
  final String server;
  final int port;
  final ProxyProtocol protocol;
}

class VlessNode extends ProxyNode {
  const VlessNode({
    required super.name,
    required super.server,
    required super.port,
    required this.uuid,
    required this.tls,
    required this.transport,
    this.flow,
    this.packetEncoding,
  }) : super(protocol: ProxyProtocol.vless);

  final String uuid;
  final String? flow;
  final String? packetEncoding;
  final TlsOptions tls;
  final V2RayTransportOptions transport;
}
