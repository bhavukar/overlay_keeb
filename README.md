# Overlay Keeb Flutter Plugin

[![pub package](https://img.shields.io/badge/pub-coming_soon-blue.svg)](https://pub.dev/packages/overlay_keeb) A Flutter plugin that allows you to display a custom Flutter widget as an overlay, typically appearing above the keyboard, similar to WhatsApp's attachment menu. This plugin currently supports Android.

## Features

* **Custom Flutter UI Overlay:** Display any Flutter widget content (defined within the plugin's secondary Dart entrypoint) in a native overlay window.
* **Above Keyboard Presentation:** Designed to appear above the soft keyboard without dismissing it.
* **Configurable Height:** The height of the overlay adjust wrt to height keyboard height.
* **Slide Animations:** Smooth slide-in and slide-out animations for the overlay window (configurable via native Android animations).




## Screenshots
![screen-20250529-025029 mp42](https://github.com/user-attachments/assets/f911537c-719d-4e53-adca-7f38dd7a89ea)


1.  Add this to your package's `pubspec.yaml` file:

    ```yaml
    dependencies:
      overlay_keeb: ^0.0.1 # Replace with the latest version
    ```

2.  Install packages from the command line:

    ```bash
    flutter pub get
    ```

## Basic Usage

Import the plugin:

```dart

import 'package:flutter/material.dart';
import 'dart:developer' as developer;

@pragma('vm:entry-point')
void overlayMain() {
  developer.log('--- OVERLAY_UI.DART: overlayMain() STARTED ---', name: 'MyOverlayDartLog');
  try {
    runApp(const OverlayApp()); // Your custom overlay app
    developer.log('--- OVERLAY_UI.DART: runApp() CALLED SUCCESSFULLY ---', name: 'MyOverlayDartLog');
  } catch (e, stackTrace) {
    developer.log('--- OVERLAY_UI.DART: EXCEPTION ---', name: 'MyOverlayDartLog', error: e, stackTrace: stackTrace);
  }
}

class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayContent(), // Your main overlay widget
    );
  }
}

class OverlayContent extends StatelessWidget {
  const OverlayContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Build your custom UI here
    return Container(
      color: Colors.grey[200], // Example background for the overlay panel
      child: Center(
        child: Text("My Custom Overlay UI!"),
        // Example: Add your Rows, Columns, Buttons for an item picker
      ),
    );
  }
}
```

## Sample Usage

```dart
  final _overlayKeeb = OverlayKeeb();
  bool _nativeOverlayVisible = false;

  @override
  void initState() {
    super.initState();
    // Register the overlay UI
    _overlayKeeb.registerOverlayUi(
      entrypointFunctionName: 'overlayMain',
      entrypointLibraryPath: 'package:your_app_name/overlay_ui.dart',
    );
  }

  Future<void> _showActualNativeOverlay() async {
    await _overlayKeeb.showOverlay();
    setState(() => _nativeOverlayVisible = true);
  }

  Future<void> _hideNativeOverlay() async {
    await _overlayKeeb.hideOverlay();
    setState(() => _nativeOverlayVisible = false);
  }

```

## Platform Support

Currently, this plugin supports Android. iOS support is planned for future releases.

## Contributing
Contributions are welcome! If you have suggestions for improvements or new features, please open an issue or submit a pull request.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

