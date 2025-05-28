import 'dart:async';

import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:overlay_keeb/overlay_keeb.dart'; // Assuming this is your plugin's main import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _overlayKeebPlugin = OverlayKeeb();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _overlayKeebPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: ChatScreen(),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode();
  bool showPicker = false;

  final OverlayKeeb _overlayKeebPlugin = OverlayKeeb();
  bool _nativeOverlayVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _registerCustomOverlayUi(); // <--- ADD THIS CALL HERE
  }

  Future<void> _registerCustomOverlayUi() async {
    try {
      // IMPORTANT: Replace 'overlay_keeb_example' with your actual example app's package name
      // as defined in your example/pubspec.yaml if it's different.
      // And ensure 'custom_overlay.dart' is the correct path from your example/lib/ folder.
      String exampleAppPackageName = "overlay_keeb_example"; // <<< VERIFY THIS
      String overlayUiFilePathInLib =
          "custom_overlay.dart"; // <<< VERIFY THIS PATH

      await _overlayKeebPlugin.registerOverlayUi(
        entrypointFunctionName:
            "myCoolOverlayMain", // This should match your @pragma function
        entrypointLibraryPath:
            "package:$exampleAppPackageName/$overlayUiFilePathInLib",
      );
      if (kDebugMode) {
        print(
          "OverlayKeebPlugin (ExampleApp): Custom overlay UI registered with path: package:$exampleAppPackageName/$overlayUiFilePathInLib",
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          "OverlayKeebPlugin (ExampleApp): Failed to register custom overlay UI: $e",
        );
      }
    }
  }

  @override
  void dispose() {
    // ... (your existing dispose code)
    WidgetsBinding.instance.removeObserver(this);
    if (_nativeOverlayVisible) {
      _overlayKeebPlugin.hideOverlay();
    }
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ... (your existing didChangeAppLifecycleState code)
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
    } else if (state == AppLifecycleState.paused) {
      if (_nativeOverlayVisible) {
        _hideNativeOverlay();
      }
    }
  }

  Future<void> _requestPermissionAndShowNativeOverlay() async {
    try {
      await _overlayKeebPlugin.showOverlay();

      if (mounted) {
        setState(() {
          _nativeOverlayVisible = true;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("OverlayKeebPlugin: Failed to show overlay: $e");
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to show overlay: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _hideNativeOverlay() async {
    // ... (your existing _hideNativeOverlay code)
    if (!_nativeOverlayVisible) return;
    try {
      await _overlayKeebPlugin.hideOverlay();
      if (mounted) {
        setState(() {
          _nativeOverlayVisible = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("OverlayKeebPlugin: Failed to hide overlay: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (your existing build method)
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_textFieldFocusNode.hasFocus) {
                  _textFieldFocusNode.unfocus();
                }
              },
              child: Stack(
                children: [
                  const Center(
                    child: Text("Chat messages area (tap to unfocus field)"),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _textFieldFocusNode,
                    decoration: const InputDecoration(
                      hintText: "Type a message",
                    ),
                    onTap: () {
                      if (showPicker) {
                        setState(() {
                          showPicker = false;
                        });
                      }
                      if (_nativeOverlayVisible) {
                        _hideNativeOverlay();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.mood),
                  onPressed: () {
                    if (_nativeOverlayVisible) _hideNativeOverlay();

                    if (_textFieldFocusNode.hasFocus) {
                      _textFieldFocusNode.unfocus();
                    }
                    setState(() {
                      showPicker = !showPicker;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.attachment),
                  onPressed: () async {
                    // Make this async if you added await for focus
                    if (showPicker) {
                      setState(() => showPicker = false);
                    }

                    if (_nativeOverlayVisible) {
                      await _hideNativeOverlay(); // ensure await if _hideNativeOverlay is async
                    } else {
                      if (!_textFieldFocusNode.hasFocus) {
                        _textFieldFocusNode.requestFocus();
                        await Future.delayed(
                          const Duration(milliseconds: 100),
                        ); // Optional delay
                      }
                      await _requestPermissionAndShowNativeOverlay();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
