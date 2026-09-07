import 'dart:async';

import 'package:truetun/src/core/connection_snapshot.dart';
import 'package:truetun/src/core/core_adapter.dart';
import 'package:truetun/src/core/log_redactor.dart';
import 'package:truetun/src/core/sing_box_config_compiler.dart';

class ConnectionController {
  ConnectionController({
    required this.adapter,
    this.compiler = const SingBoxConfigCompiler(),
    this.redactor = const LogRedactor(),
  }) {
    _subscription = adapter.events.listen(_onCoreEvent);
  }

  final ProxyCoreAdapter adapter;
  final SingBoxConfigCompiler compiler;
  final LogRedactor redactor;
  final StreamController<CoreEvent> _events = StreamController.broadcast();
  late final StreamSubscription<CoreEvent> _subscription;

  ProxyCoreState get state => adapter.state;
  Stream<CoreEvent> get events => _events.stream;

  Future<void> connect(ConnectionSnapshot snapshot) async {
    final config = compiler.compile(snapshot);
    await adapter.start(config);
  }

  Future<void> disconnect() => adapter.stop();

  void _onCoreEvent(CoreEvent event) {
    if (event case CoreLogLine(:final line, :final isError)) {
      _events.add(CoreLogLine(redactor.redact(line), isError: isError));
    } else if (event case CoreFailure(:final message)) {
      _events.add(CoreFailure(redactor.redact(message)));
    } else {
      _events.add(event);
    }
  }

  Future<void> dispose() async {
    await _subscription.cancel();
    await _events.close();
  }
}
