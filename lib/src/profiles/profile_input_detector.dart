enum ProfileInputKind {
  singleShareLink,
  shareLinkList,
  encodedShareLinkList,
  remoteSubscriptionUrl,
  singBoxJson,
  clashOrMihomoYaml,
  unknown,
}

class ProfileInputDetector {
  const ProfileInputDetector();

  static const _shareSchemes = <String>{
    'vless',
    'vmess',
    'trojan',
    'ss',
    'hysteria',
    'hysteria2',
    'hy2',
    'tuic',
    'wireguard',
    'wg',
    'ssh',
    'socks',
  };

  ProfileInputKind detect(String rawInput) {
    final input = rawInput.trim();
    if (input.isEmpty) return ProfileInputKind.unknown;

    final singleUri = Uri.tryParse(input);
    if (singleUri != null && _shareSchemes.contains(singleUri.scheme.toLowerCase())) {
      return ProfileInputKind.singleShareLink;
    }

    if (singleUri != null &&
        (singleUri.scheme == 'https' || singleUri.scheme == 'http')) {
      return ProfileInputKind.remoteSubscriptionUrl;
    }

    if (_looksLikeSingBoxJson(input)) return ProfileInputKind.singBoxJson;
    if (_looksLikeClashYaml(input)) return ProfileInputKind.clashOrMihomoYaml;

    final nonEmptyLines = input
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    if (nonEmptyLines.length > 1 &&
        nonEmptyLines.every((line) {
          final uri = Uri.tryParse(line);
          return uri != null && _shareSchemes.contains(uri.scheme.toLowerCase());
        })) {
      return ProfileInputKind.shareLinkList;
    }

    if (_looksLikeBase64(input)) return ProfileInputKind.encodedShareLinkList;
    return ProfileInputKind.unknown;
  }

  bool _looksLikeSingBoxJson(String input) {
    return input.startsWith('{') &&
        input.endsWith('}') &&
        (input.contains('"outbounds"') || input.contains('"inbounds"'));
  }

  bool _looksLikeClashYaml(String input) {
    final normalized = input.toLowerCase();
    return normalized.contains('\nproxies:') ||
        normalized.startsWith('proxies:') ||
        normalized.contains('\nproxy-providers:') ||
        normalized.contains('\nrules:');
  }

  bool _looksLikeBase64(String input) {
    if (input.length < 24 || input.length % 4 == 1) return false;
    return RegExp(r'^[A-Za-z0-9_+/=-]+$').hasMatch(input);
  }
}
