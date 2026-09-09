import 'dart:async';

import 'package:truetun/src/core/core_adapter.dart';
import 'package:truetun/src/platform/android/android_platform_bridge.dart';

class AndroidSingBoxAdapter implements ProxyCoreAdapter {
  AndroidSingBoxAdapter({
    AndroidPlatformBridge bridge = const AndroidPlatformBridge(),
  }) : _bridge = bridge {
    _bridge.events().listen(
      _onNativeEvent,
      onError: (Object error, StackTrace stackTrace) {
        _events.add(CoreFailure(error.toString()));
        _setState(ProxyCoreState.failed);
      },
    );
    unawaited(_syncInitialState());
  }

  final AndroidPlatformBridge _bridge;
  final StreamController<CoreEvent> _events = StreamController.broadcast();
  ProxyCoreState _state = ProxyCoreState.stopped;

  @override
  ProxyCoreState get state => _state;

  @override
  Stream<CoreEvent> get events => _events.stream;

  @override
  Future<CoreCapabilities> getCapabilities() => _bridge.getCapabilities();

  @override
  Future<void> validateConfig(String configJson) =>
      _bridge.validateConfig(configJson);

  @override
  Future<void> start(String configJson) async {
    if (_state != ProxyCoreState.stopped && _state != ProxyCoreState.failed) {
      throw CoreException('Core cannot start from state $_state');
    }
    final prepared = await _bridge.prepareVpn();
    if (!prepared) {
      throw const CoreException('Android VPN permission was denied');
    }

    await validateConfig(configJson);
    _setState(ProxyCoreState.starting);
    await _bridge.start(configJson);
    final result = await _waitForStates(
      const {
        ProxyCoreState.running,
        ProxyCoreState.failed,
        ProxyCoreState.stopped,
      },
      const Duration(seconds: 20),
    );
    if (result != ProxyCoreState.running) {
      throw CoreException('Android VPN failed to start (state: ${result.name})');
    }
  }

  @override
  Future<void> stop() async {
    if (_state == ProxyCoreState.stopped) return;
    _setState(ProxyCoreState.stopping);
    await _bridge.stop();
    await _waitForStates(
      const {ProxyCoreState.stopped, ProxyCoreState.failed},
      const Duration(seconds: 10),
    );
  }

  Future<void> _syncInitialState() async {
    try {
      final snapshot = await _bridge.getState();
      _setState(_parseState(snapshot['state']));
      final error = snapshot['error']?.toString();
      if (error != null && error.isNotEmpty) {
        _events.add(CoreFailure(error));
      }
      _events.add(
        CoreTraffic(
          upload: _int(snapshot['upload']),
          download: _int(snapshot['download']),
          uploadPerSecond: _int(snapshot['uploadPerSecond']),
          downloadPerSecond: _int(snapshot['downloadPerSecond']),
        ),
      );
    } catch (error) {
      _events.add(CoreFailure(error.toString()));
    }
  }

  void _onNativeEvent(Object? raw) {
    if (raw is! Map) return;
    final type = raw['type']?.toString();
    switch (type) {
      case 'state':
        _setState(_parseState(raw['state']));
        final error = raw['error']?.toString();
        if (error != null && error.isNotEmpty) {
          _events.add(CoreFailure(error));
        }
      case 'log':
        _events.add(
          CoreLogLine(
            raw['message']?.toString() ?? '',
            isError: raw['isError'] == true,
          ),
        );
      case 'failure':
        _events.add(
          CoreFailure(raw['message']?.toString() ?? 'Native core failure'),
        );
      case 'traffic':
        _events.add(
          CoreTraffic(
            upload: _int(raw['upload']),
            download: _int(raw['download']),
            uploadPerSecond: _int(raw['uploadPerSecond']),
            downloadPerSecond: _int(raw['downloadPerSecond']),
          ),
        );
    }
  }

  Future<ProxyCoreState> _waitForStates(
    Set<ProxyCoreState> states,
    Duration timeout,
  ) async {
    if (states.contains(_state)) return _state;
    final completer = Completer<ProxyCoreState>();
    late StreamSubscription<CoreEvent> subscription;
    subscription = _events.stream.listen((event) {
      if (event case CoreStateChanged(:final state)
          when states.contains(state)) {
        if (!completer.isCompleted) completer.complete(state);
      }
    });
    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      throw CoreException(
        'Timed out waiting for Android VPN state '
        '(${states.map((e) => e.name).join(', ')})',
      );
    } finally {
      await subscription.cancel();
    }
  }

  ProxyCoreState _parseState(Object? value) {
    final name = value?.toString();
    return ProxyCoreState.values
            .where((state) => state.name == name)
            .firstOrNull ??
        ProxyCoreState.stopped;
  }

  int _int(Object? value) => value is num ? value.toInt() : 0;

  void _setState(ProxyCoreState value) {
    if (_state == value) return;
    _state = value;
    _events.add(CoreStateChanged(value));
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
