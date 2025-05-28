import 'package:overlay_keeb/overlay_keeb_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// An abstract class that serves as the platform interface for the Overlay Keyboard plugin.
///
/// Platform implementations should extend this class rather than implement it as
/// this ensures the interface remains consistent across all implementations.
/// This follows the Flutter plugin development best practices.
abstract class OverlayKeebPlatform extends PlatformInterface {
  /// Constructs a OverlayKeebPlatform instance.
  ///
  /// The [token] parameter is used to verify that subclasses were correctly instantiated.
  OverlayKeebPlatform() : super(token: _token);

  /// Verification token used by the [PlatformInterface] to ensure that only valid
  /// platform implementations can be registered.
  static final Object _token = Object();

  /// The default instance of [OverlayKeebPlatform] to use.
  ///
  /// By default, this is set to [MethodChannelOverlayKeeb], which uses
  /// a method channel to communicate with the native platform code.
  static OverlayKeebPlatform _instance = MethodChannelOverlayKeeb();

  /// Returns the current default implementation.
  ///
  /// This is primarily used by the plugin implementation to access
  /// platform-specific functionality.
  static OverlayKeebPlatform get instance => _instance;

  /// Sets the default instance of [OverlayKeebPlatform] to use.
  ///
  /// This is only used for testing purposes to provide a mock implementation.
  /// The setter verifies that the provided instance has a valid platform interface token.
  static set instance(OverlayKeebPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Gets the current platform version.
  ///
  /// This is primarily used for testing purposes to verify connectivity with
  /// platform-specific code.
  ///
  /// Implementations should override this method to provide platform-specific functionality.
  /// Returns a [Future] containing the platform version as a [String].
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Registers a custom Flutter UI to be displayed in the overlay.
  ///
  /// This method must be called before [showOverlay] to specify which
  /// Dart code will be executed when the overlay is shown.
  ///
  /// Parameters:
  /// - [entrypointFunctionName]: The name of the Dart function to run (e.g., 'overlayMain')
  /// - [entrypointLibraryPath]: The path to the Dart library containing the entrypoint
  ///   (e.g., 'package:my_app/overlay_ui.dart')
  ///
  /// Implementations should override this method to register the overlay UI
  /// with the platform-specific code.
  Future<void> registerOverlayUi({
    required String entrypointFunctionName,
    required String entrypointLibraryPath,
  }) {
    throw UnimplementedError('registerOverlayUi() has not been implemented.');
  }

  /// Shows the overlay UI.
  ///
  /// This displays the custom Flutter UI that was registered with [registerOverlayUi].
  /// The overlay typically appears with a slide-up animation from the bottom of the screen.
  ///
  /// Parameters:
  /// - [overlayHeightDp]: Optional parameter to specify the height of the overlay
  ///   in density-independent pixels. If not provided, a default height is used.
  ///
  /// Implementations should override this method to show the overlay on the platform.
  Future<void> showOverlay({int? overlayHeightDp}) {
    throw UnimplementedError('showOverlay() has not been implemented.');
  }

  /// Hides the currently displayed overlay.
  ///
  /// Dismisses the overlay with a slide-down animation.
  ///
  /// Implementations should override this method to hide the overlay on the platform.
  Future<void> hideOverlay() {
    throw UnimplementedError('hideOverlay() has not been implemented.');
  }
}
