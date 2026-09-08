import 'package:truetun/src/profiles/hysteria2_profile_parser.dart';
import 'package:truetun/src/profiles/proxy_node.dart';
import 'package:truetun/src/profiles/vless_link_parser.dart';

class ProxyProfileParser {
  const ProxyProfileParser({
    this.vless = const VlessLinkParser(),
    this.hysteria2 = const Hysteria2ProfileParser(),
  });

  final VlessLinkParser vless;
  final Hysteria2ProfileParser hysteria2;

  ProxyNode parse(String rawInput) {
    final input = rawInput.trim();
    if (input.isEmpty) {
      throw const ProfileParseException('Profile input is empty');
    }

    final marker = input.indexOf('://');
    final scheme = marker > 0 ? input.substring(0, marker).toLowerCase() : null;
    return switch (scheme) {
      'vless' => vless.parse(input),
      'hysteria2' || 'hy2' => hysteria2.parse(input),
      'hysteria' => throw const ProfileParseException(
          'Legacy Hysteria v1 is not supported; use a Hysteria2 configuration',
        ),
      null => hysteria2.parse(input),
      _ => throw ProfileParseException('Unsupported proxy scheme: $scheme'),
    };
  }
}
