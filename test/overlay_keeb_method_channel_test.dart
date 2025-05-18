import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:overlay_keeb/overlay_keeb_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelOverlayKeeb platform = MethodChannelOverlayKeeb();
  const MethodChannel channel = MethodChannel('overlay_keeb');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
