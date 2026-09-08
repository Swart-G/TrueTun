import 'package:truetun/src/profiles/proxy_node.dart';
import 'package:truetun/src/profiles/vless_link_parser.dart';
import 'package:yaml/yaml.dart';

class Hysteria2ProfileParser {
  const Hysteria2ProfileParser();

  Hysteria2Node parse(String rawInput) {
    final input = rawInput.trim();
    if (input.isEmpty) {
      throw const ProfileParseException('Hysteria2 configuration is empty');
    }

    final scheme = _schemeOf(input);
    if (scheme == 'hysteria2' || scheme == 'hy2') {
      return _parseUri(input);
    }

    Object? document;
    try {
      document = loadYaml(input);
    } catch (error) {
      throw ProfileParseException('Invalid Hysteria2 YAML/JSON: $error');
    }
    final map = _map(document);
    if (map.isEmpty) {
      throw const ProfileParseException('Hysteria2 configuration is not a map');
    }

    final nodes = _parseStructuredMap(map);
    if (nodes.isEmpty) {
      throw const ProfileParseException(
        'Configuration contains no supported Hysteria2 profile',
      );
    }
    if (nodes.length > 1) {
      throw const ProfileParseException(
        'Configuration contains multiple Hysteria2 profiles; import it as a subscription',
      );
    }
    return nodes.single;
  }

  List<Hysteria2Node> parseMany(String rawInput) {
    final input = rawInput.trim();
    if (input.isEmpty) return const [];

    final scheme = _schemeOf(input);
    if (scheme == 'hysteria2' || scheme == 'hy2') {
      return [_parseUri(input)];
    }

    Object? document;
    try {
      document = loadYaml(input);
    } catch (_) {
      return const [];
    }
    final map = _map(document);
    if (map.isEmpty) return const [];
    return _parseStructuredMap(map);
  }

  List<Hysteria2Node> _parseStructuredMap(Map<Object?, Object?> map) {
    final proxies = map['proxies'];
    if (proxies is Iterable) {
      return [
        for (final rawProxy in proxies)
          if (_isHysteria2Map(_map(rawProxy)))
            _parseMihomoProxy(_map(rawProxy)),
      ];
    }

    final outbounds = map['outbounds'];
    if (outbounds is Iterable) {
      return [
        for (final rawOutbound in outbounds)
          if (_isHysteria2Map(_map(rawOutbound)))
            _parseSingBoxOutbound(_map(rawOutbound)),
      ];
    }

    if (_isHysteria2Map(map)) {
      return [
        if (map.containsKey('server_port') || map.containsKey('server_ports'))
          _parseSingBoxOutbound(map)
        else
          _parseMihomoProxy(map),
      ];
    }

    if (map.containsKey('server') && map.containsKey('auth')) {
      return [_parseOfficialConfig(map)];
    }
    return const [];
  }

  Hysteria2Node _parseUri(String rawLink) {
    final parsed = _parseHysteriaUri(rawLink);
    final query = parsed.query;
    _rejectUnsupportedSecurityFields(
      pinSha256: _string(query['pinSHA256']),
      ech: _string(query['ech']),
    );

    final obfsType = _string(query['obfs'])?.toLowerCase();
    final obfsPassword = _string(query['obfs-password']);
    final obfs = _buildObfs(
      type: obfsType,
      password: obfsPassword,
      minPacketSize: _integer(query['obfs-min-packet-size']),
      maxPacketSize: _integer(query['obfs-max-packet-size']),
    );

    final alpn = (_string(query['alpn']) ?? '')
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    final extensions = <String, String>{};
    for (final entry in query.entries) {
      if (!_knownUriParameters.contains(entry.key)) {
        extensions[entry.key] = entry.value;
      }
    }

    return Hysteria2Node(
      name: parsed.name,
      server: parsed.endpoint.server,
      port: parsed.endpoint.port,
      serverPorts: parsed.endpoint.serverPorts,
      password: parsed.auth,
      tls: TlsOptions(
        enabled: true,
        serverName: _string(query['sni']),
        alpn: alpn,
        insecure: _bool(query['insecure']),
      ),
      obfs: obfs,
      extensions: Map.unmodifiable(extensions),
    );
  }

  Hysteria2Node _parseOfficialConfig(Map<Object?, Object?> map) {
    final server =
        _requiredString(map['server'], 'Hysteria2 server is missing');
    if (_schemeOf(server) case 'hysteria2' || 'hy2') {
      return _parseUri(server);
    }

    final endpoint = _parseEndpoint(server);
    final password = _requiredString(map['auth'], 'Hysteria2 auth is missing');
    final tls = _map(map['tls']);
    _rejectUnsupportedSecurityFields(
      pinSha256: _string(tls['pinSHA256']),
      ech: tls['ech'],
    );

    final obfsMap = _map(map['obfs']);
    final obfsType = _string(obfsMap['type'])?.toLowerCase();
    final selectedObfs =
        obfsType == null ? const <Object?, Object?>{} : _map(obfsMap[obfsType]);
    final obfs = _buildObfs(
      type: obfsType,
      password:
          _string(selectedObfs['password']) ?? _string(obfsMap['password']),
      minPacketSize: _integer(selectedObfs['minPacketSize']) ??
          _integer(selectedObfs['min_packet_size']),
      maxPacketSize: _integer(selectedObfs['maxPacketSize']) ??
          _integer(selectedObfs['max_packet_size']),
    );

    final bandwidth = _map(map['bandwidth']);
    return Hysteria2Node(
      name: _string(map['name']) ?? '${endpoint.server}:${endpoint.port}',
      server: endpoint.server,
      port: endpoint.port,
      serverPorts: endpoint.serverPorts,
      password: password,
      tls: TlsOptions(
        enabled: true,
        serverName: _string(tls['sni']),
        insecure: _bool(tls['insecure']),
      ),
      upMbps: _bandwidthMbps(bandwidth['up']),
      downMbps: _bandwidthMbps(bandwidth['down']),
      obfs: obfs,
    );
  }

  Hysteria2Node _parseMihomoProxy(Map<Object?, Object?> map) {
    final server =
        _requiredString(map['server'], 'Hysteria2 server is missing');
    final endpoint = _parseEndpoint(
      server,
      portOverride: map['port'],
      portsOverride: map['ports'],
    );
    final password = _requiredString(
      map['password'],
      'Hysteria2 password is missing',
    );
    _rejectUnsupportedSecurityFields(
      pinSha256: _string(map['fingerprint']),
      ech: map['ech-config'] ?? map['ech'],
    );

    final hop = _hopIntervals(map['hop-interval']);
    final alpnRaw = map['alpn'];
    final alpn = alpnRaw is Iterable
        ? alpnRaw.map((value) => value.toString()).toList(growable: false)
        : const <String>[];
    final obfs = _buildObfs(
      type: _string(map['obfs'])?.toLowerCase(),
      password: _string(map['obfs-password']),
      minPacketSize: _integer(map['obfs-min-packet-size']),
      maxPacketSize: _integer(map['obfs-max-packet-size']),
    );

    return Hysteria2Node(
      name: _string(map['name']) ?? '${endpoint.server}:${endpoint.port}',
      server: endpoint.server,
      port: endpoint.port,
      serverPorts: endpoint.serverPorts,
      password: password,
      tls: TlsOptions(
        enabled: true,
        serverName: _string(map['sni']) ?? _string(map['name-cert-verify']),
        alpn: alpn,
        insecure: _bool(map['skip-cert-verify']),
      ),
      hopInterval: hop.$1,
      hopIntervalMax: hop.$2,
      upMbps: _bandwidthMbps(map['up']),
      downMbps: _bandwidthMbps(map['down']),
      obfs: obfs,
    );
  }

  Hysteria2Node _parseSingBoxOutbound(Map<Object?, Object?> map) {
    final server =
        _requiredString(map['server'], 'Hysteria2 server is missing');
    final endpoint = _parseEndpoint(
      server,
      portOverride: map['server_port'],
      portsOverride: map['server_ports'],
    );
    final password = _requiredString(
      map['password'],
      'Hysteria2 password is missing',
    );
    final tls = _map(map['tls']);
    final unsupportedPin = tls['certificate_public_key_sha256'];
    if (unsupportedPin is Iterable && unsupportedPin.isNotEmpty) {
      throw const ProfileParseException(
        'Hysteria2 certificate public-key pinning is not supported by TrueTun yet',
      );
    }
    if (_map(tls['ech'])['enabled'] == true) {
      throw const ProfileParseException(
        'Hysteria2 ECH is not supported by TrueTun yet',
      );
    }

    final obfsMap = _map(map['obfs']);
    final obfs = _buildObfs(
      type: _string(obfsMap['type'])?.toLowerCase(),
      password: _string(obfsMap['password']),
      minPacketSize: _integer(obfsMap['min_packet_size']),
      maxPacketSize: _integer(obfsMap['max_packet_size']),
    );
    final alpnRaw = tls['alpn'];
    final alpn = alpnRaw is Iterable
        ? alpnRaw.map((value) => value.toString()).toList(growable: false)
        : const <String>[];

    return Hysteria2Node(
      name: _string(map['tag']) ?? '${endpoint.server}:${endpoint.port}',
      server: endpoint.server,
      port: endpoint.port,
      serverPorts: endpoint.serverPorts,
      password: password,
      tls: TlsOptions(
        enabled: true,
        serverName: _string(tls['server_name']),
        alpn: alpn,
        insecure: _bool(tls['insecure']),
      ),
      hopInterval: _duration(map['hop_interval']),
      hopIntervalMax: _duration(map['hop_interval_max']),
      upMbps: _integer(map['up_mbps']),
      downMbps: _integer(map['down_mbps']),
      obfs: obfs,
    );
  }

  _ParsedUri _parseHysteriaUri(String rawLink) {
    final marker = rawLink.indexOf('://');
    if (marker <= 0) {
      throw const ProfileParseException('Invalid Hysteria2 URI');
    }
    final scheme = rawLink.substring(0, marker).toLowerCase();
    if (scheme != 'hysteria2' && scheme != 'hy2') {
      throw const ProfileParseException('Input is not a Hysteria2 URI');
    }

    final authorityStart = marker + 3;
    var authorityEnd = rawLink.length;
    for (final delimiter in ['/', '?', '#']) {
      final index = rawLink.indexOf(delimiter, authorityStart);
      if (index >= 0 && index < authorityEnd) authorityEnd = index;
    }
    final authority = rawLink.substring(authorityStart, authorityEnd);
    final at = authority.lastIndexOf('@');
    if (at <= 0 || at == authority.length - 1) {
      throw const ProfileParseException('Hysteria2 auth or server is missing');
    }
    final auth = Uri.decodeComponent(authority.substring(0, at)).trim();
    if (auth.isEmpty) {
      throw const ProfileParseException('Hysteria2 auth is missing');
    }

    final endpoint = _parseEndpoint(authority.substring(at + 1));
    final suffix =
        authorityEnd < rawLink.length ? rawLink.substring(authorityEnd) : '';
    final safeHost = endpoint.server.contains(':')
        ? '[${endpoint.server}]'
        : endpoint.server;
    final uri =
        Uri.tryParse('$scheme://auth@$safeHost:${endpoint.port}$suffix');
    if (uri == null) {
      throw const ProfileParseException('Invalid Hysteria2 URI');
    }
    final name = uri.fragment.trim().isEmpty
        ? '${endpoint.server}:${endpoint.port}'
        : Uri.decodeComponent(uri.fragment.trim());
    return _ParsedUri(
      auth: auth,
      endpoint: endpoint,
      query: uri.queryParameters,
      name: name,
    );
  }

  _Endpoint _parseEndpoint(
    String rawServer, {
    Object? portOverride,
    Object? portsOverride,
  }) {
    var server = rawServer.trim();
    if (server.isEmpty) {
      throw const ProfileParseException('Hysteria2 server is missing');
    }

    String? embeddedPortSpec;
    if (server.startsWith('[')) {
      final close = server.indexOf(']');
      if (close <= 1) {
        throw const ProfileParseException('Invalid Hysteria2 IPv6 server');
      }
      final host = server.substring(1, close);
      if (close + 1 < server.length) {
        if (server[close + 1] != ':') {
          throw const ProfileParseException('Invalid Hysteria2 server address');
        }
        embeddedPortSpec = server.substring(close + 2);
      }
      server = host;
    } else {
      final colonCount = ':'.allMatches(server).length;
      if (colonCount == 1) {
        final colon = server.lastIndexOf(':');
        embeddedPortSpec = server.substring(colon + 1);
        server = server.substring(0, colon);
      }
    }

    if (server.isEmpty) {
      throw const ProfileParseException('Hysteria2 server is missing');
    }

    final rawPorts = _portSpecs(portsOverride);
    final portSpec =
        rawPorts.isNotEmpty ? null : _string(portOverride) ?? embeddedPortSpec;
    final serverPorts = rawPorts.isNotEmpty
        ? rawPorts
        : _isMultiPort(portSpec)
            ? _portSpecs(portSpec)
            : const <String>[];

    final displayPort = serverPorts.isNotEmpty
        ? _firstPort(serverPorts.first)
        : _parsePort(portSpec ?? '443');
    return _Endpoint(
        server: server, port: displayPort, serverPorts: serverPorts);
  }

  List<String> _portSpecs(Object? value) {
    if (value == null) return const [];
    final values = value is Iterable ? value : [value];
    final result = <String>[];
    for (final item in values) {
      for (final part in item.toString().split(',')) {
        final normalized = part.trim().replaceAll('-', ':');
        if (normalized.isEmpty) continue;
        if (!_portRangePattern.hasMatch(normalized)) {
          throw ProfileParseException('Invalid Hysteria2 port range: $part');
        }
        final pieces = normalized.split(':');
        for (final piece in pieces) {
          _parsePort(piece);
        }
        result.add(normalized);
      }
    }
    return List.unmodifiable(result);
  }

  bool _isMultiPort(String? value) {
    if (value == null) return false;
    return value.contains(',') || value.contains('-') || value.contains(':');
  }

  int _firstPort(String spec) => _parsePort(spec.split(':').first);

  int _parsePort(String raw) {
    final port = int.tryParse(raw.trim());
    if (port == null || port < 1 || port > 65535) {
      throw ProfileParseException('Invalid Hysteria2 port: $raw');
    }
    return port;
  }

  Hysteria2ObfsOptions? _buildObfs({
    required String? type,
    required String? password,
    int? minPacketSize,
    int? maxPacketSize,
  }) {
    if (type == null || type.isEmpty) return null;
    if (type != 'salamander' && type != 'gecko') {
      throw ProfileParseException('Unsupported Hysteria2 obfs type: $type');
    }
    if (password == null || password.trim().isEmpty) {
      throw const ProfileParseException('Hysteria2 obfs password is missing');
    }
    if (type != 'gecko' && (minPacketSize != null || maxPacketSize != null)) {
      throw const ProfileParseException(
        'Hysteria2 packet-size obfs options require gecko',
      );
    }
    return Hysteria2ObfsOptions(
      type: type,
      password: password.trim(),
      minPacketSize: minPacketSize,
      maxPacketSize: maxPacketSize,
    );
  }

  void _rejectUnsupportedSecurityFields({Object? pinSha256, Object? ech}) {
    if (_string(pinSha256)?.isNotEmpty == true) {
      throw const ProfileParseException(
        'Hysteria2 pinSHA256 cannot be translated safely to sing-box yet',
      );
    }
    if (ech != null && _string(ech)?.isNotEmpty != false) {
      throw const ProfileParseException(
        'Hysteria2 ECH cannot be translated safely to sing-box yet',
      );
    }
  }

  (String?, String?) _hopIntervals(Object? value) {
    final raw = _string(value);
    if (raw == null) return (null, null);
    final match = RegExp(r'^\s*(\d+)\s*-\s*(\d+)\s*$').firstMatch(raw);
    if (match != null) {
      return ('${match.group(1)}s', '${match.group(2)}s');
    }
    return (_duration(raw), null);
  }

  String? _duration(Object? value) {
    final raw = _string(value);
    if (raw == null) return null;
    if (RegExp(r'^\d+$').hasMatch(raw)) return '${raw}s';
    return raw;
  }

  int? _bandwidthMbps(Object? value) {
    if (value is num) return value.round();
    final raw = _string(value);
    if (raw == null) return null;
    final match = RegExp(r'^(\d+(?:\.\d+)?)\s*(?:m(?:bit)?s?|mbps)?$',
            caseSensitive: false)
        .firstMatch(raw);
    if (match == null) return null;
    return double.parse(match.group(1)!).round();
  }

  bool _isHysteria2Map(Map<Object?, Object?> map) {
    final type = _string(map['type'])?.toLowerCase();
    return type == 'hysteria2' || type == 'hy2';
  }

  Map<Object?, Object?> _map(Object? value) {
    if (value is YamlMap) return Map<Object?, Object?>.from(value);
    if (value is Map) return Map<Object?, Object?>.from(value);
    return const {};
  }

  String _requiredString(Object? value, String message) {
    final result = _string(value);
    if (result == null) throw ProfileParseException(message);
    return result;
  }

  String? _string(Object? value) {
    if (value == null) return null;
    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }

  int? _integer(Object? value) {
    if (value is num) return value.round();
    return int.tryParse(_string(value) ?? '');
  }

  bool _bool(Object? value) {
    if (value is bool) return value;
    return switch (_string(value)?.toLowerCase()) {
      '1' || 'true' || 'yes' || 'on' => true,
      _ => false,
    };
  }

  String? _schemeOf(String value) {
    final marker = value.indexOf('://');
    if (marker <= 0) return null;
    return value.substring(0, marker).toLowerCase();
  }

  static const _knownUriParameters = <String>{
    'obfs',
    'obfs-password',
    'obfs-min-packet-size',
    'obfs-max-packet-size',
    'sni',
    'insecure',
    'pinSHA256',
    'ech',
    'alpn',
  };

  static final _portRangePattern = RegExp(r'^\d+(?::\d+)?$');
}

class _Endpoint {
  const _Endpoint({
    required this.server,
    required this.port,
    required this.serverPorts,
  });

  final String server;
  final int port;
  final List<String> serverPorts;
}

class _ParsedUri {
  const _ParsedUri({
    required this.auth,
    required this.endpoint,
    required this.query,
    required this.name,
  });

  final String auth;
  final _Endpoint endpoint;
  final Map<String, String> query;
  final String name;
}
