import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'overlay_keeb_method_channel.dart';

abstract class OverlayKeebPlatform extends PlatformInterface {
  /// Constructs a OverlayKeebPlatform.
  OverlayKeebPlatform() : super(token: _token);

  static final Object _token = Object();

  static OverlayKeebPlatform _instance = MethodChannelOverlayKeeb();

  /// The default instance of [OverlayKeebPlatform] to use.
  ///
  /// Defaults to [MethodChannelOverlayKeeb].
  static OverlayKeebPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [OverlayKeebPlatform] when
  /// they register themselves.
  static set instance(OverlayKeebPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> showOverlay() {
    throw UnimplementedError('showOverlay() has not been implemented.');
  }

  Future<void> hideOverlay() {
    throw UnimplementedError('hideOverlay() has not been implemented.');
  }

  // New methods for permission
  Future<bool> checkOverlayPermission() {
    throw UnimplementedError(
      'checkOverlayPermission() has not been implemented.',
    );
  }

  Future<bool> requestOverlayPermission() {
    throw UnimplementedError(
      'requestOverlayPermission() has not been implemented.',
    );
  }
}
