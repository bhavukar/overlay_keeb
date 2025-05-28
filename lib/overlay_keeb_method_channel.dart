/// Implementation of a method channel-based service to communicate with the native platform code.
///
/// This class provides the actual implementation of the [OverlayKeebPlatform] abstract methods
/// using Flutter's [MethodChannel] to interact with native Android/iOS code.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'overlay_keeb_platform_interface.dart';

/// Method channel implementation for the overlay keyboard plugin.
///
/// This class handles all the communication with platform-specific code
/// through the Flutter method channel mechanism.
class MethodChannelOverlayKeeb extends OverlayKeebPlatform {
  /// The method channel used to communicate with the platform-side.
  ///
  /// Made visible for testing purposes so it can be mocked in unit tests.
  @visibleForTesting
  final methodChannel = const MethodChannel('overlay_keeb');

  // No explicit constructor needed, default constructor is fine.

  /// Retrieves the current platform version.
  ///
  /// This method calls the native 'getPlatformVersion' method through the method channel.
  /// It's primarily used for testing connectivity with the platform code.
  ///
  /// Returns a [Future] containing the platform version as a [String], or null if failed.
  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  /// Registers a custom overlay UI implementation with the platform.
  ///
  /// This method must be called before showing the overlay to specify which Dart
  /// entrypoint function should be executed to build the overlay UI.
  ///
  /// Parameters:
  /// - [entrypointFunctionName]: The name of the function that will be called to run the overlay UI
  ///   (e.g., 'overlayMain')
  /// - [entrypointLibraryPath]: The path to the Dart file containing the entrypoint function
  ///   (e.g., 'package:my_app/overlay_ui.dart')
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

  /// Shows the overlay UI above the keyboard.
  ///
  /// Calls the native 'showOverlay' method to display the overlay with
  /// the UI implementation specified in [registerOverlayUi].
  ///
  /// Parameters:
  /// - [overlayHeightDp]: Optional parameter to specify the height of the overlay in density-independent pixels.
  ///   If not provided, the native implementation will use the default height.
  @override
  Future<void> showOverlay({int? overlayHeightDp}) async {
    await methodChannel.invokeMethod('showOverlay');
  }

  /// Hides the currently displayed overlay.
  ///
  /// Calls the native 'hideOverlay' method to dismiss any visible overlay UI.
  @override
  Future<void> hideOverlay() async {
    await methodChannel.invokeMethod('hideOverlay');
  }
}
