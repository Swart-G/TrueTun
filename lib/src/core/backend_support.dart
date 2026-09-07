import 'package:truetun/src/core/core_adapter.dart';
import 'package:truetun/src/profiles/proxy_node.dart';

enum BackendSupportState { unsupported, importOnly, experimental, supported }

class BackendSupport {
  const BackendSupport({required this.state, required this.reason});

  final BackendSupportState state;
  final String reason;

  bool get canConnect =>
      state == BackendSupportState.experimental ||
      state == BackendSupportState.supported;
}

class BackendSupportResolver {
  const BackendSupportResolver();

  BackendSupport resolve(ProxyNode node, CoreCapabilities capabilities) {
    if (!capabilities.protocols.contains(node.protocol.name)) {
      return BackendSupport(
        state: BackendSupportState.importOnly,
        reason:
            '${node.protocol.name} is not supported by ${capabilities.name}',
      );
    }
    if (node
        case VlessNode(
          transport: V2RayTransportOptions(type: V2RayTransportType.xhttp)
        )) {
      if (!capabilities.features.contains('xhttp')) {
        return const BackendSupport(
          state: BackendSupportState.importOnly,
          reason: 'XHTTP requires an extended backend',
        );
      }
      return const BackendSupport(
        state: BackendSupportState.experimental,
        reason: 'XHTTP support is experimental',
      );
    }
    return const BackendSupport(
      state: BackendSupportState.supported,
      reason: 'Supported by the selected backend',
    );
  }
}
