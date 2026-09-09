import 'package:flutter/services.dart';
import 'package:truetun/src/apps/app_routing_policy.dart';
import 'package:truetun/src/core/core_adapter.dart';

class AndroidPlatformBridge {
  const AndroidPlatformBridge();

  static const MethodChannel methodChannel = MethodChannel('truetun/core');
  static const EventChannel eventChannel = EventChannel('truetun/core/events');

  Future<bool> prepareVpn() async =>
      await _invoke<bool>('prepareVpn') ?? false;

  Future<void> start(String configJson) async {
    await _invoke<bool>('start', {'configJson': configJson});
  }

  Future<void> stop() async {
    await _invoke<bool>('stop');
  }

  Future<void> openVpnSettings() async {
    await _invoke<bool>('openVpnSettings');
  }

  Future<Map<String, Object?>> getState() async {
    final result = await _invoke<Map<Object?, Object?>>('getState') ?? const {};
    return result.map((key, value) => MapEntry(key.toString(), value));
  }

  Future<CoreCapabilities> getCapabilities() async {
    final result =
        await _invoke<Map<Object?, Object?>>('getCapabilities') ?? const {};
    return CoreCapabilities(
      name: result['name']?.toString() ?? 'sing-box libbox',
      version: result['version']?.toString() ?? 'unknown',
      protocols: _stringSet(result['protocols']),
      features: _stringSet(result['features']),
    );
  }

  Future<void> validateConfig(String configJson) async {
    await _invoke<bool>('validateConfig', {'configJson': configJson});
  }

  Future<List<InstalledAppDescriptor>> getInstalledApps() async {
    final raw = await _invoke<List<Object?>>('getInstalledApps') ?? const [];
    return raw.whereType<Map<Object?, Object?>>().map((entry) {
      final categoryName = entry['category']?.toString() ?? 'other';
      AppCategory category;
      try {
        category = AppCategory.values.byName(categoryName);
      } catch (_) {
        category = AppCategory.other;
      }
      return InstalledAppDescriptor(
        packageName: entry['packageName']?.toString() ?? '',
        label:
            entry['label']?.toString() ?? entry['packageName']?.toString() ?? '',
        category: category,
        isSystem: entry['isSystem'] == true,
        uid: (entry['uid'] as num?)?.toInt(),
      );
    }).where((app) => app.packageName.isNotEmpty).toList(growable: false);
  }

  Future<Map<String, Object?>> getDiagnostics() async {
    final result =
        await _invoke<Map<Object?, Object?>>('getDiagnostics') ?? const {};
    return result.map((key, value) => MapEntry(key.toString(), value));
  }

  Stream<Object?> events() => eventChannel.receiveBroadcastStream();

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await methodChannel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      throw CoreException(error.message ?? error.code);
    } on MissingPluginException catch (error) {
      throw CoreException('Android native bridge is unavailable: $error');
    }
  }

  Set<String> _stringSet(Object? raw) =>
      raw is Iterable ? raw.map((value) => value.toString()).toSet() : const {};
}
