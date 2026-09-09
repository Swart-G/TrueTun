enum ProxyCoreState {
  stopped,
  starting,
  running,
  stopping,
  failed,
}

class CoreCapabilities {
  const CoreCapabilities({
    required this.name,
    required this.version,
    required this.protocols,
    required this.features,
  });

  final String name;
  final String version;
  final Set<String> protocols;
  final Set<String> features;
}

sealed class CoreEvent {
  const CoreEvent();
}

class CoreStateChanged extends CoreEvent {
  const CoreStateChanged(this.state);

  final ProxyCoreState state;
}

class CoreLogLine extends CoreEvent {
  const CoreLogLine(this.line, {required this.isError});

  final String line;
  final bool isError;
}

class CoreFailure extends CoreEvent {
  const CoreFailure(this.message);

  final String message;
}

class CoreTraffic extends CoreEvent {
  const CoreTraffic({
    required this.upload,
    required this.download,
    required this.uploadPerSecond,
    required this.downloadPerSecond,
  });

  final int upload;
  final int download;
  final int uploadPerSecond;
  final int downloadPerSecond;
}

class CoreException implements Exception {
  const CoreException(this.message);

  final String message;

  @override
  String toString() => 'CoreException: $message';
}

abstract interface class ProxyCoreAdapter {
  ProxyCoreState get state;

  Stream<CoreEvent> get events;

  Future<CoreCapabilities> getCapabilities();

  Future<void> validateConfig(String configJson);

  Future<void> start(String configJson);

  Future<void> stop();
}
