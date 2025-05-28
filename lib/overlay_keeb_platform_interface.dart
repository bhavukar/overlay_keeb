import 'package:overlay_keeb/overlay_keeb_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class OverlayKeebPlatform extends PlatformInterface {
  OverlayKeebPlatform() : super(token: _token);

  static final Object _token = Object();
  static OverlayKeebPlatform _instance = MethodChannelOverlayKeeb();

  static OverlayKeebPlatform get instance => _instance;
  static set instance(OverlayKeebPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  // New method to register the user's custom UI entrypoint
  Future<void> registerOverlayUi({
    required String entrypointFunctionName,
    required String entrypointLibraryPath,
  }) {
    throw UnimplementedError('registerOverlayUi() has not been implemented.');
  }

  Future<void> showOverlay({int? overlayHeightDp}) {
    throw UnimplementedError('showOverlay() has not been implemented.');
  }

  Future<void> hideOverlay() {
    throw UnimplementedError('hideOverlay() has not been implemented.');
  }
}
