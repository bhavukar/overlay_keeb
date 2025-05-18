library overlay_keeb;

import 'overlay_keeb_platform_interface.dart';

export 'overlay_ui.dart';

class OverlayKeeb {
  Future<String?> getPlatformVersion() {
    return OverlayKeebPlatform.instance.getPlatformVersion();
  }

  //show overlay
  Future<void> showOverlay() {
    return OverlayKeebPlatform.instance.showOverlay();
  }

  //hide overlay
  Future<void> hideOverlay() {
    return OverlayKeebPlatform.instance.hideOverlay();
  }

  //check overlay permission
  Future<bool> checkOverlayPermission() {
    return OverlayKeebPlatform.instance.checkOverlayPermission();
  }

  //request overlay permission
  Future<bool> requestOverlayPermission() {
    return OverlayKeebPlatform.instance.requestOverlayPermission();
  }
}
