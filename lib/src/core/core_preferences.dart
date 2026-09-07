class CorePreferences {
  const CorePreferences({
    this.logLevel = 'info',
    this.stack = 'mixed',
    this.mtu = 9000,
    this.strictRoute = true,
    this.ipv6 = true,
    this.remoteDns = 'https://1.1.1.1/dns-query',
    this.directDns = 'local',
  });

  final String logLevel;
  final String stack;
  final int mtu;
  final bool strictRoute;
  final bool ipv6;
  final String remoteDns;
  final String directDns;

  CorePreferences copyWith({
    String? logLevel,
    String? stack,
    int? mtu,
    bool? strictRoute,
    bool? ipv6,
    String? remoteDns,
    String? directDns,
  }) =>
      CorePreferences(
        logLevel: logLevel ?? this.logLevel,
        stack: stack ?? this.stack,
        mtu: mtu ?? this.mtu,
        strictRoute: strictRoute ?? this.strictRoute,
        ipv6: ipv6 ?? this.ipv6,
        remoteDns: remoteDns ?? this.remoteDns,
        directDns: directDns ?? this.directDns,
      );

  Map<String, Object> toJson() => {
        'logLevel': logLevel,
        'stack': stack,
        'mtu': mtu,
        'strictRoute': strictRoute,
        'ipv6': ipv6,
        'remoteDns': remoteDns,
        'directDns': directDns,
      };

  factory CorePreferences.fromJson(Map<String, dynamic> json) =>
      CorePreferences(
        logLevel: json['logLevel'] as String? ?? 'info',
        stack: json['stack'] as String? ?? 'mixed',
        mtu: (json['mtu'] as num?)?.toInt() ?? 9000,
        strictRoute: json['strictRoute'] as bool? ?? true,
        ipv6: json['ipv6'] as bool? ?? true,
        remoteDns: json['remoteDns'] as String? ?? 'https://1.1.1.1/dns-query',
        directDns: json['directDns'] as String? ?? 'local',
      );
}
