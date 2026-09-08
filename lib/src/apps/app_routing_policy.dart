enum AppRoutingMode {
  /// Everything enters the tunnel except packages in [selectedPackageNames].
  proxyAllExceptSelected,

  /// Only packages in [selectedPackageNames] enter the tunnel.
  proxyOnlySelected,
}

class AppRoutingPolicy {
  const AppRoutingPolicy({
    required this.mode,
    this.selectedPackageNames = const {},
  });

  final AppRoutingMode mode;
  final Set<String> selectedPackageNames;

  Map<String, Object> toAndroidVpnPolicy({required String ownPackageName}) {
    final selected = _normalizedPackages(ownPackageName);

    switch (mode) {
      case AppRoutingMode.proxyAllExceptSelected:
        return {
          'mode': 'exclude',
          'packages': selected.toList()..sort(),
        };
      case AppRoutingMode.proxyOnlySelected:
        return {
          'mode': 'include',
          'packages': <String>{...selected, ownPackageName}.toList()..sort(),
        };
    }
  }

  /// sing-box mobile bindings expose the same package filters in TunOptions.
  /// TrueTun itself must enter the TUN so its connection diagnostics test the
  /// real VPN. Core sockets are exempted separately with VpnService.protect().
  Map<String, Object> toAndroidTunPatch({required String ownPackageName}) {
    final selected = _normalizedPackages(ownPackageName);

    switch (mode) {
      case AppRoutingMode.proxyAllExceptSelected:
        return {
          'exclude_package': selected.toList()..sort(),
        };
      case AppRoutingMode.proxyOnlySelected:
        return {
          'include_package': <String>{...selected, ownPackageName}.toList()
            ..sort(),
        };
    }
  }

  Set<String> _normalizedPackages(String ownPackageName) {
    return selectedPackageNames
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty && value != ownPackageName)
        .toSet();
  }
}

enum AppCategory {
  browser,
  messaging,
  social,
  streaming,
  game,
  banking,
  system,
  vpnOrProxy,
  other,
}

class InstalledAppDescriptor {
  const InstalledAppDescriptor({
    required this.packageName,
    required this.label,
    required this.category,
    required this.isSystem,
    this.uid,
  });

  final String packageName;
  final String label;
  final AppCategory category;
  final bool isSystem;
  final int? uid;
}

enum AppRoutingRecommendation {
  proxy,
  bypass,
  neutral,
}

class AppRoutingSuggestion {
  const AppRoutingSuggestion({
    required this.app,
    required this.recommendation,
    required this.confidence,
    required this.reason,
  });

  final InstalledAppDescriptor app;
  final AppRoutingRecommendation recommendation;
  final double confidence;
  final String reason;
}

class SmartAppSuggestionEngine {
  const SmartAppSuggestionEngine();

  AppRoutingSuggestion suggest(
    InstalledAppDescriptor app, {
    required String ownPackageName,
  }) {
    if (app.packageName == ownPackageName) {
      return AppRoutingSuggestion(
        app: app,
        recommendation: AppRoutingRecommendation.proxy,
        confidence: 1,
        reason: 'TrueTun diagnostics must enter the VPN; core sockets bypass it with protect().',
      );
    }

    if (app.category == AppCategory.vpnOrProxy) {
      return AppRoutingSuggestion(
        app: app,
        recommendation: AppRoutingRecommendation.bypass,
        confidence: 0.95,
        reason: 'Another VPN/proxy app can create routing loops or conflicts.',
      );
    }

    if (app.isSystem || app.category == AppCategory.system) {
      return AppRoutingSuggestion(
        app: app,
        recommendation: AppRoutingRecommendation.bypass,
        confidence: 0.7,
        reason: 'System services are safer outside the tunnel by default.',
      );
    }

    if ({
      AppCategory.browser,
      AppCategory.messaging,
      AppCategory.social,
    }.contains(app.category)) {
      return AppRoutingSuggestion(
        app: app,
        recommendation: AppRoutingRecommendation.proxy,
        confidence: 0.65,
        reason: 'This category commonly benefits from the selected proxy route.',
      );
    }

    return AppRoutingSuggestion(
      app: app,
      recommendation: AppRoutingRecommendation.neutral,
      confidence: 0.5,
      reason: 'No safe automatic choice; keep the current routing policy.',
    );
  }
}
