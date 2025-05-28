import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'overlay_keeb_platform_interface.dart';

class MethodChannelOverlayKeeb extends OverlayKeebPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('overlay_keeb');

  // No explicit constructor needed, default constructor is fine.

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<void> registerOverlayUi({
    required String entrypointFunctionName,
    required String entrypointLibraryPath,
  }) async {
    await methodChannel.invokeMethod('registerOverlayUi', {
      'entrypointFunctionName': entrypointFunctionName,
      'entrypointLibraryPath': entrypointLibraryPath,
    });
  }

  @override
  Future<void> showOverlay({int? overlayHeightDp}) async {
    await methodChannel.invokeMethod('showOverlay');
  }

  @override
  Future<void> hideOverlay() async {
    await methodChannel.invokeMethod('hideOverlay');
  }
}
