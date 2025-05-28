import 'package:flutter_test/flutter_test.dart';
import 'package:overlay_keeb/overlay_keeb.dart';
import 'package:overlay_keeb/overlay_keeb_method_channel.dart';
import 'package:overlay_keeb/overlay_keeb_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockOverlayKeebPlatform
    with MockPlatformInterfaceMixin
    implements OverlayKeebPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<void> showOverlay({int? overlayHeightDp}) => Future.value();

  @override
  Future<void> hideOverlay() => Future.value();

  @override
  Future<void> registerOverlayUi({
    required String entrypointFunctionName,
    required String entrypointLibraryPath,
  }) {
    // Mock implementation for testing
    return Future.value();
  }
}

void main() {
  final OverlayKeebPlatform initialPlatform = OverlayKeebPlatform.instance;

  test('$MethodChannelOverlayKeeb is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelOverlayKeeb>());
  });

  test('getPlatformVersion', () async {
    OverlayKeeb overlayKeebPlugin = OverlayKeeb();
    MockOverlayKeebPlatform fakePlatform = MockOverlayKeebPlatform();
    OverlayKeebPlatform.instance = fakePlatform;

    expect(await overlayKeebPlugin.getPlatformVersion(), '42');
  });
}
