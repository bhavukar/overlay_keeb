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

## Android Setup

1.  **Add `SYSTEM_ALERT_WINDOW` Permission:**
    Open your project's `android/app/src/main/AndroidManifest.xml` file and add the following permission *outside* the `<application>` tag, but inside the `<manifest>` tag:

    ```xml
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
    ```

2.  **(Plugin Internal) Animation Resources:**
    This plugin uses native Android animations. Ensure the following files are correctly placed within the plugin's Android resource directory (`overlay_keeb/android/src/main/res/`):
    * `anim/slide_in_up.xml` (or your preferred enter animation)
    * `anim/slide_out_down.xml` (or your preferred exit animation)
    * `values/styles.xml` (containing the `OverlayAnimation` style that references the animators)

## Basic Usage

Import the plugin:

```dart
import 'package:overlay_keeb/overlay_keeb.dart';
Initialize the plugin:final OverlayKeeb _overlayKeebPlugin = OverlayKeeb();
1. Check and Request Overlay Permission (Android):It's crucial to have the "display over other apps" permission on Android.bool hasPermission = await _overlayKeebPlugin.checkOverlayPermission();
if (!hasPermission) {
  // This will open the system settings for the user to grant permission.
  await _overlayKeebPlugin.requestOverlayPermission();
  // You should re-check the permission status when your app resumes,
  // for example, by using WidgetsBindingObserver and AppLifecycleState.resumed.
}
2. Show the Overlay:Once permission is granted, you can show the overlay. You can optionally specify a height in DP.if (await _overlayKeebPlugin.checkOverlayPermission()) {
  try {
    // Example: Show overlay with a height of 300dp
    await _overlayKeebPlugin.showOverlay(overlayHeightDp: 300);
    // To use a default height (currently 250dp in the plugin):
    // await _overlayKeebPlugin.showOverlay();
  } catch (e) {
    print("Failed to show overlay: $e");
  }
} else {
  print("Overlay permission not granted.");
  // Guide user to grant permission or explain why it's needed.
}
3. Hide the Overlay:await _overlayKeebPlugin.hideOverlay();
Example Scenario (e.g., in a chat input field):// In your Widget's state
bool _isOverlayVisible = false;
final OverlayKeeb _overlayKeebPlugin = OverlayKeeb();
final FocusNode _textFieldFocusNode = FocusNode(); // To help manage keyboard focus

// ... (permission checking logic, perhaps in initState or a utility function) ...

IconButton(
  icon: Icon(Icons.attach_file),
  onPressed: () async {
    if (_isOverlayVisible) {
      await _overlayKeebPlugin.hideOverlay();
      setState(() {
        _isOverlayVisible = false;
      });
    } else {
      bool hasPermission = await _overlayKeebPlugin.checkOverlayPermission();
      if (!hasPermission) {
        await _overlayKeebPlugin.requestOverlayPermission();
        // Wait for user to return from settings and re-check.
        // This part is simplified; robust handling would use AppLifecycleState.
        // For this example, assume user grants it and we might need to tap again.
        return; 
      }

      // Ensure TextField is focused to keep keyboard up, or bring it up.
      if (!_textFieldFocusNode.hasFocus) {
        _textFieldFocusNode.requestFocus();
        // It might take a moment for the keyboard to appear.
        // If relying on auto-detected keyboard height in the plugin, a small delay might be needed.
        await Future.delayed(const Duration(milliseconds: 100)); 
      }
      
      // TODO: Implement robust keyboard height detection in your app
      // For now, we'll pass a fixed height or let the plugin use its default.
      // int keyboardHeightDp = getKeyboardHeightInDpFromMyApp(); 
      await _overlayKeebPlugin.showOverlay(overlayHeightDp: 300 /* or keyboardHeightDp */);
      setState(() {
        _isOverlayVisible = true;
      });
    }
  },
)
Customizing the Overlay UI (Current Method)The content of the overlay is currently a separate Flutter UI defined within the plugin itself, specifically in the file lib/overlay_ui.dart (this file is part of the overlay_keeb plugin's own lib folder).To customize this UI:Open the overlay_keeb plugin project.Navigate to lib/overlay_ui.dart.Modify the overlayMain() function and the widgets it runs (e.g., OverlayApp, OverlayContent). This is where you build the desired layout, buttons, etc., using standard Flutter widgets that will appear in the overlay.Example structure of overlay_ui.dart (inside the plugin):// In overlay_keeb/lib/overlay_ui.dart
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
Note on Communication:Communicating from the overlay UI (in overlay_ui.dart) back to your main application (e.g., when a button in the overlay is tapped) requires setting up a separate MethodChannel for the overlay's Flutter engine. This is an advanced setup.Roadmap & Future EnhancementsiOS Support (WIP): Implement the native overlay functionality for iOS.Dynamic UI from Consuming App (TODO): Explore ways for the consuming Flutter application to directly provide or build the Widget tree for the overlay, rather than it being fixed within the plugin's overlay_ui.dart. This would greatly enhance flexibility.Advanced Animations (TODO):Allow customization of native animations (e.g., duration, interpolator) from Dart.Investigate Flutter-driven animations for the panel itself for more complex effects (e.g., circular reveal), which would require significant changes to the native implementation and inter-engine communication.Robust Keyboard Height Detection (Enhancement): While the plugin accepts a height parameter, building more robust and cross-platform keyboard height detection directly into the plugin or providing clearer guidance for app-side implementation would be beneficial.Bi-directional Communication (Enhancement): Simplify or provide helpers for two-way communication between the main app and the overlay UI (e.g., for overlay button taps to trigger actions in the main app).Issues and ContributionsPlease file any issues, bugs, or feature requests on the GitHub repository. Contributions are welcome!This README is a starting point. Feel free to add more details, API documentation, and examples as the plugin matures.