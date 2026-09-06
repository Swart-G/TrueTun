class CorePreferences {
  const CorePreferences({
    this.logLevel = 'info',
    this.stack = 'mixed',
    this.mtu = 1400,
    this.strictRoute = false,
    this.ipv6 = false,
    this.remoteDns = 'https://1.1.1.1/dns-query',
    this.directDns = '1.1.1.1',
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
  }) {
    return CorePreferences(
      logLevel: logLevel ?? this.logLevel,
      stack: stack ?? this.stack,
      mtu: mtu ?? this.mtu,
      strictRoute: strictRoute ?? this.strictRoute,
      ipv6: ipv6 ?? this.ipv6,
      remoteDns: remoteDns ?? this.remoteDns,
      directDns: directDns ?? this.directDns,
    );
  }
}
