import 'overlay_keeb_platform_interface.dart';

/// Main class for the Overlay Keyboard plugin.
///
/// Provides methods to register custom UI, show and hide the overlay.
class OverlayKeeb {
  /// Returns the current platform version.
  ///
  /// This is primarily used for testing the plugin channel connectivity.
  /// Returns a [Future] that completes with the platform version as a [String].
  Future<String?> getPlatformVersion() {
    return OverlayKeebPlatform.instance.getPlatformVersion();
  }

  /// Registers a custom overlay UI with the plugin.
  ///
  /// This method must be called before [showOverlay] to specify which
  /// Dart entrypoint should be used for the overlay UI.
  ///
  /// Parameters:
  /// - [entrypointFunctionName]: The name of the Dart function to run as the entrypoint
  ///   (e.g., 'overlayMain')
  /// - [entrypointLibraryPath]: The path to the Dart library containing the entrypoint
  ///   (e.g., 'package:my_app/overlay_ui.dart')
  ///
  /// Example:
  /// ```dart
  /// await overlayKeeb.registerOverlayUi(
  ///   entrypointFunctionName: 'overlayMain',
  ///   entrypointLibraryPath: 'package:my_app/overlay_ui.dart',
  /// );
  /// ```
  Future<void> registerOverlayUi({
    required String entrypointFunctionName,
    required String entrypointLibraryPath,
  }) {
    return OverlayKeebPlatform.instance.registerOverlayUi(
      entrypointFunctionName: entrypointFunctionName,
      entrypointLibraryPath: entrypointLibraryPath,
    );
  }

  /// Shows the overlay UI above the keyboard.
  ///
  /// Must be called after [registerOverlayUi]. This will display the
  /// custom Flutter UI defined in your registered entrypoint function.
  ///
  /// The overlay appears with a slide-up animation from the bottom of the screen.
  Future<void> showOverlay() {
    return OverlayKeebPlatform.instance.showOverlay();
  }

  /// Hides the currently displayed overlay.
  ///
  /// Dismisses the overlay with a slide-down animation.
  Future<void> hideOverlay() {
    return OverlayKeebPlatform.instance.hideOverlay();
  }
}
