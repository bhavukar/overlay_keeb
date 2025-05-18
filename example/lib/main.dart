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
  final FocusNode _textFieldFocusNode = FocusNode(); // Add a FocusNode
  bool showPicker = false; // For your purely Flutter-based picker example

  final OverlayKeeb _overlayKeebPlugin = OverlayKeeb();
  bool _hasOverlayPermission = false;
  bool _nativeOverlayVisible = false; // Renamed for clarity

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionOnInit();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_nativeOverlayVisible) {
      _overlayKeebPlugin.hideOverlay();
    }
    _textFieldFocusNode.dispose(); // Dispose FocusNode
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _updatePermissionStatus();
    } else if (state == AppLifecycleState.paused) {
      // Optionally hide the overlay when the app is paused
      if (_nativeOverlayVisible) {
        _hideNativeOverlay();
      }
    }
  }

  Future<void> _checkPermissionOnInit() async {
    final status = await _overlayKeebPlugin.checkOverlayPermission();
    if (mounted) {
      setState(() {
        _hasOverlayPermission = status;
      });
      if (!status && kDebugMode) {
        print("OverlayKeebPlugin: Overlay permission not granted yet.");
      }
    }
  }

  Future<void> _updatePermissionStatus() async {
    final status = await _overlayKeebPlugin.checkOverlayPermission();
    if (mounted) {
      setState(() {
        _hasOverlayPermission = status;
      });
    }
  }

  Future<void> _requestPermissionAndShowNativeOverlay() async {
    bool permissionGranted = _hasOverlayPermission;
    if (!permissionGranted) {
      await _overlayKeebPlugin.requestOverlayPermission();
      permissionGranted =
          await _overlayKeebPlugin.checkOverlayPermission(); // Re-check
      if (mounted) {
        // Update state after permission attempt
        setState(() {
          _hasOverlayPermission = permissionGranted;
        });
      }
    }

    if (!permissionGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Overlay permission is required. Please grant it in settings and try again.',
            ),
          ),
        );
      }
      return;
    }

    // If permission is now granted
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
    if (!_nativeOverlayVisible) return; // Don't try to hide if not visible
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
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              // GestureDetector to unfocus TextField when tapping outside
              onTap: () {
                if (_textFieldFocusNode.hasFocus) {
                  _textFieldFocusNode.unfocus();
                  // Optionally hide native overlay when chat area is tapped
                  // if (_nativeOverlayVisible) {
                  //   _hideNativeOverlay();
                  // }
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
                    focusNode: _textFieldFocusNode, // Assign FocusNode
                    decoration: const InputDecoration(
                      hintText: "Type a message",
                    ),
                    onTap: () {
                      // When text field is tapped, ensure our custom UIs are hidden
                      if (showPicker) {
                        setState(() {
                          showPicker = false;
                        });
                      }
                      // If native overlay is visible when TextField is tapped, hide it.
                      // This allows user to easily get back to typing.
                      if (_nativeOverlayVisible) {
                        _hideNativeOverlay();
                      }
                    },
                  ),
                ),
                // Button for purely Flutter-based picker (example)
                IconButton(
                  icon: const Icon(Icons.mood),
                  onPressed: () {
                    if (_nativeOverlayVisible)
                      _hideNativeOverlay(); // Hide native if shown

                    // If keyboard is open, hide it to show the pure Flutter picker
                    if (_textFieldFocusNode.hasFocus) {
                      _textFieldFocusNode.unfocus();
                    }
                    setState(() {
                      showPicker = !showPicker;
                    });
                  },
                ),
                // Button for Native Flutter Overlay
                IconButton(
                  icon: const Icon(
                    Icons.attachment,
                  ), // Changed to attachment for clarity
                  onPressed: () {
                    if (showPicker) {
                      setState(
                        () => showPicker = false,
                      ); // Hide pure Flutter picker
                    }

                    if (_nativeOverlayVisible) {
                      _hideNativeOverlay();
                      // After hiding, if TextField had focus, it should retain it.
                      // If not, and you want to ensure keyboard comes back:
                      // _textFieldFocusNode.requestFocus();
                    } else {
                      // KEY CHANGE: REMOVED FocusScope.of(context).unfocus();
                      // The keyboard should stay open if the TextField is focused.
                      // The native overlay has FLAG_NOT_FOCUSABLE.

                      // If the TextField is not focused, and you want the keyboard
                      // to appear before showing the overlay, you could request focus here.
                      // However, typically this button is tapped when TextField already has focus.
                      if (!_textFieldFocusNode.hasFocus) {
                        _textFieldFocusNode
                            .requestFocus(); // This will bring up the keyboard
                      }
                      // Now request and show the overlay
                      _requestPermissionAndShowNativeOverlay();
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
