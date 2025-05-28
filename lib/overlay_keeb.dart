import 'overlay_keeb_platform_interface.dart';

// If overlay_ui.dart is no longer part of the plugin's default UI,
// you might remove this export or keep it if it serves as a utility/example.
// For this change, we assume the user provides their own, so it can be removed.
// export 'overlay_ui.dart';

class OverlayKeeb {
  Future<String?> getPlatformVersion() {
    return OverlayKeebPlatform.instance.getPlatformVersion();
  }

  // New method
  Future<void> registerOverlayUi({
    required String entrypointFunctionName,
    required String entrypointLibraryPath,
  }) {
    return OverlayKeebPlatform.instance.registerOverlayUi(
      entrypointFunctionName: entrypointFunctionName,
      entrypointLibraryPath: entrypointLibraryPath,
    );
  }

  Future<void> showOverlay() {
    return OverlayKeebPlatform.instance.showOverlay();
  }

  Future<void> hideOverlay() {
    return OverlayKeebPlatform.instance.hideOverlay();
  }
}
