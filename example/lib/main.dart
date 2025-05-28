import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:overlay_keeb/overlay_keeb.dart';

// MAIN Entrypoint for the Application
void main() {
  runApp(const MyApp());
}

// =======================================================================
// == OVERLAY UI CODE (This can be in main.dart or its own imported file) ==
// =======================================================================
@pragma('vm:entry-point')
void myCoolOverlayMain() {
  // This is your overlay's entrypoint
  developer.log(
    '--- MyCustomOverlay (in main.dart): myCoolOverlayMain() STARTED ---',
    name: 'UserOverlayLog',
  );
  try {
    // IMPORTANT: This runApp is for the OVERLAY UI.
    // It should be simple and render your desired overlay content.
    runApp(
      const MyOverlayApp(),
    ); // Changed from MyCustomOverlayContent directly to ensure Material context
    developer.log(
      '--- MyCustomOverlay (in main.dart): runApp() CALLED SUCCESSFULLY ---',
      name: 'UserOverlayLog',
    );
  } catch (e, stackTrace) {
    developer.log(
      '--- MyCustomOverlay (in main.dart): EXCEPTION ---',
      name: 'UserOverlayLog',
      error: e,
      stackTrace: stackTrace,
    );
  }
}

// This is the root widget for your overlay's separate Flutter instance
class MyOverlayApp extends StatelessWidget {
  const MyOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Important: Make the home Scaffold/Material transparent if the content
      // itself will define the opaque background (like your item picker).
      // Or set a specific background color here if the content is smaller.
      home: MyCustomOverlayContent(),
    );
  }
}

class MyCustomOverlayContent extends StatelessWidget {
  const MyCustomOverlayContent({super.key});

  Widget _buildPickerItem(
    BuildContext context,
    IconData icon,
    String label,
    Color iconColor,
  ) {
    return InkWell(
      onTap: () {
        developer.log(
          'MyCustomOverlay: Item tapped: $label',
          name: 'UserOverlayLog',
        );
        // To send data back to main app, a MethodChannel specific to this engine would be needed.
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blueGrey[700],
            child: Icon(icon, size: 26, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This is where you build your actual overlay UI (the item picker)
    // Ensure this root widget provides an opaque background.
    return Material(
      // Or just Container
      type:
          MaterialType
              .transparency, // To allow custom shape/background for Container
      child: Container(
        // This color will be the background of your overlay.
        // Your Kotlin code sets the PopupWindow to be 250dp high (or keyboardHeight).
        // This container will fill that space.
        color: Colors.grey[900], // Example: Dark background for the picker
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            // Row for the first set of items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildPickerItem(
                  context,
                  Icons.camera_alt,
                  'Camera',
                  Colors.pinkAccent,
                ),
                _buildPickerItem(
                  context,
                  Icons.photo_library,
                  'Gallery',
                  Colors.purpleAccent,
                ),
                _buildPickerItem(
                  context,
                  Icons.audiotrack,
                  'Audio',
                  Colors.orangeAccent,
                ),
                _buildPickerItem(
                  context,
                  Icons.location_on,
                  'Location',
                  Colors.greenAccent,
                ),

                _buildPickerItem(
                  context,
                  Icons.file_copy,
                  'File',
                  Colors.blueAccent,
                ),

                _buildPickerItem(
                  context,
                  Icons.person,
                  'Contact',
                  Colors.lightBlueAccent,
                ),
              ],
            ),
            // Add more rows or widgets as needed
          ],
        ),
      ),
    );
  }
}

// =======================================================================
// == YOUR MAIN APP CODE (MyApp, ChatScreen etc.) below this            ==
// =======================================================================

class MyApp extends StatefulWidget {
  // ... (your MyApp code from the prompt)
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String platformVersion = 'Unknown';
  final _overlayKeebPlugin = OverlayKeeb();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion =
          await _overlayKeebPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }
    if (!mounted) return;
    setState(() {
      platformVersion = platformVersion;
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
  bool showPicker =
      false; // For purely Flutter-based picker example (can be removed if not used)

  final OverlayKeeb _overlayKeebPlugin = OverlayKeeb();
  bool _nativeOverlayVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _registerCustomOverlayUi();
  }

  Future<void> _registerCustomOverlayUi() async {
    try {
      // Ensure 'overlay_keeb_example' is the 'name:' in your example/pubspec.yaml
      // And 'main.dart' now contains 'myCoolOverlayMain'
      String exampleAppPackageName = "overlay_keeb_example";
      String overlayUiEntryPointFile =
          "main.dart"; // Since myCoolOverlayMain is now in main.dart

      await _overlayKeebPlugin.registerOverlayUi(
        entrypointFunctionName: "myCoolOverlayMain",
        entrypointLibraryPath:
            "package:$exampleAppPackageName/$overlayUiEntryPointFile",
      );
      if (kDebugMode) {
        print(
          "OverlayKeebPlugin (ExampleApp): Custom overlay UI registered. Entrypoint: myCoolOverlayMain in package:$exampleAppPackageName/$overlayUiEntryPointFile",
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
    WidgetsBinding.instance.removeObserver(this);
    if (_nativeOverlayVisible) {
      _overlayKeebPlugin.hideOverlay();
    }
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // if (state == AppLifecycleState.resumed) {
    //   // _updatePermissionStatus(); // Permission status not needed for PopupWindow
    // } else
    if (state == AppLifecycleState.paused) {
      if (_nativeOverlayVisible) {
        _hideNativeOverlay();
      }
    }
  }

  // _requestPermissionAndShowNativeOverlay can be simplified as permission is not needed
  Future<void> _showActualNativeOverlay() async {
    // Renamed for clarity
    try {
      // The Kotlin side uses getKeyboardHeight(), no need to pass height from here for that logic.
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
    return Scaffold(
      resizeToAvoidBottomInset: true, // Important for keyboard interaction
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_textFieldFocusNode.hasFocus) {
                  _textFieldFocusNode.unfocus();
                }
              },
              child: const Center(
                child: Text("Chat messages area (tap to unfocus field)"),
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
                      if (_nativeOverlayVisible) {
                        _hideNativeOverlay();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.attachment),
                  onPressed: () async {
                    if (_nativeOverlayVisible) {
                      await _hideNativeOverlay();
                    } else {
                      if (!_textFieldFocusNode.hasFocus) {
                        _textFieldFocusNode.requestFocus();
                        // Small delay might still be beneficial for focus to settle before keyboard height detection
                        await Future.delayed(const Duration(milliseconds: 50));
                      }
                      await _showActualNativeOverlay(); // Call the simplified method
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
