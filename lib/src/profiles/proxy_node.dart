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
    this.extensions = const {},
  }) : super(protocol: ProxyProtocol.vless);

  final String uuid;
  final String? flow;
  final String? packetEncoding;
  final TlsOptions tls;
  final V2RayTransportOptions transport;
  final Map<String, String> extensions;

  VlessNode copyWith({
    String? name,
    String? server,
    int? port,
    String? uuid,
    String? flow,
    String? packetEncoding,
    TlsOptions? tls,
    V2RayTransportOptions? transport,
    Map<String, String>? extensions,
  }) {
    return VlessNode(
      name: name ?? this.name,
      server: server ?? this.server,
      port: port ?? this.port,
      uuid: uuid ?? this.uuid,
      flow: flow ?? this.flow,
      packetEncoding: packetEncoding ?? this.packetEncoding,
      tls: tls ?? this.tls,
      transport: transport ?? this.transport,
      extensions: extensions ?? this.extensions,
    );
  }
}

class Hysteria2ObfsOptions {
  const Hysteria2ObfsOptions({
    required this.type,
    required this.password,
    this.minPacketSize,
    this.maxPacketSize,
  });

  final String type;
  final String password;
  final int? minPacketSize;
  final int? maxPacketSize;
}

class Hysteria2Node extends ProxyNode {
  const Hysteria2Node({
    required super.name,
    required super.server,
    required super.port,
    required this.password,
    required this.tls,
    this.serverPorts = const [],
    this.hopInterval,
    this.hopIntervalMax,
    this.upMbps,
    this.downMbps,
    this.obfs,
    this.extensions = const {},
  }) : super(protocol: ProxyProtocol.hysteria2);

  final String password;
  final TlsOptions tls;

  /// Optional sing-box port-hopping ranges such as `20000:30000`.
  final List<String> serverPorts;
  final String? hopInterval;
  final String? hopIntervalMax;
  final int? upMbps;
  final int? downMbps;
  final Hysteria2ObfsOptions? obfs;
  final Map<String, String> extensions;

  Hysteria2Node copyWith({
    String? name,
    String? server,
    int? port,
    String? password,
    TlsOptions? tls,
    List<String>? serverPorts,
    String? hopInterval,
    String? hopIntervalMax,
    int? upMbps,
    int? downMbps,
    Hysteria2ObfsOptions? obfs,
    Map<String, String>? extensions,
  }) {
    return Hysteria2Node(
      name: name ?? this.name,
      server: server ?? this.server,
      port: port ?? this.port,
      password: password ?? this.password,
      tls: tls ?? this.tls,
      serverPorts: serverPorts ?? this.serverPorts,
      hopInterval: hopInterval ?? this.hopInterval,
      hopIntervalMax: hopIntervalMax ?? this.hopIntervalMax,
      upMbps: upMbps ?? this.upMbps,
      downMbps: downMbps ?? this.downMbps,
      obfs: obfs ?? this.obfs,
      extensions: extensions ?? this.extensions,
    );
  }
}
