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

  /// Produces the Android TUN inbound package filter patch used by sing-box.
  ///
  /// [ownPackageName] is deliberately never inserted into an include list and
  /// is always inserted into an exclude list to reduce accidental VPN loops.
  Map<String, Object> toAndroidTunPatch({required String ownPackageName}) {
    final selected = selectedPackageNames
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty && value != ownPackageName)
        .toSet();

    switch (mode) {
      case AppRoutingMode.proxyAllExceptSelected:
        return {
          'exclude_package': <String>{...selected, ownPackageName}.toList()..sort(),
        };
      case AppRoutingMode.proxyOnlySelected:
        return {
          'include_package': selected.toList()..sort(),
        };
    }
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
  });

  final String packageName;
  final String label;
  final AppCategory category;
  final bool isSystem;
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

/// Privacy-preserving baseline for the future smart app selector.
///
/// It intentionally uses only local metadata. Later versions can enrich this
/// with user-confirmed regional presets, connection failures and local usage
/// history, while keeping the decision explainable in the UI.
class SmartAppSuggestionEngine {
  const SmartAppSuggestionEngine();

  AppRoutingSuggestion suggest(
    InstalledAppDescriptor app, {
    required String ownPackageName,
  }) {
    if (app.packageName == ownPackageName) {
      return AppRoutingSuggestion(
        app: app,
        recommendation: AppRoutingRecommendation.bypass,
        confidence: 1,
        reason: 'TrueTun itself should not be routed back into its VPN.',
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
