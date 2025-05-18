import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'overlay_keeb_platform_interface.dart';

/// An implementation of [OverlayKeebPlatform] that uses method channels.
class MethodChannelOverlayKeeb extends OverlayKeebPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('overlay_keeb');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<void> showOverlay() async {
    await methodChannel.invokeMethod('showOverlay');
  }

  @override
  Future<void> hideOverlay() async {
    await methodChannel.invokeMethod('hideOverlay');
  }

  @override
  Future<bool> checkOverlayPermission() async {
    final permission = await methodChannel.invokeMethod<bool>(
      'checkOverlayPermission',
    );
    return permission ?? false;
  }

  @override
  Future<bool> requestOverlayPermission() async {
    final permission = await methodChannel.invokeMethod<bool>(
      'requestOverlayPermission',
    );
    return permission ?? false;
  }
}
