import 'dart:io';

import 'package:truetun/src/core/android_sing_box_adapter.dart';
import 'package:truetun/src/core/core_adapter.dart';
import 'package:truetun/src/core/process_sing_box_adapter.dart';

class CoreAdapterFactory {
  const CoreAdapterFactory._();

  static ProxyCoreAdapter create() {
    if (Platform.isAndroid) return AndroidSingBoxAdapter();
    return ProcessSingBoxAdapter();
  }
}
