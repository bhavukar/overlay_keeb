import 'dart:developer' as developer;

import 'package:flutter/material.dart';

// This MUST be a top-level function or a static method in a class.
@pragma('vm:entry-point')
void myCoolOverlayMain() {
  // User chooses this name
  developer.log(
    '--- MyCustomOverlay: myCoolOverlayMain() STARTED ---',
    name: 'UserOverlayLog',
  );
  try {
    runApp(const MyCustomOverlayContent());
    developer.log(
      '--- MyCustomOverlay: runApp() CALLED SUCCESSFULLY ---',
      name: 'UserOverlayLog',
    );
  } catch (e, stackTrace) {
    developer.log(
      '--- MyCustomOverlay: EXCEPTION ---',
      name: 'UserOverlayLog',
      error: e,
      stackTrace: stackTrace,
    );
  }
}

class MyCustomOverlayContent extends StatelessWidget {
  const MyCustomOverlayContent({super.key});

  // You can reuse your _buildPickerItem or create any UI you want here
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
    return Material(
      // Added Material for better theming if needed
      type:
          MaterialType
              .transparency, // Ensure transparency if container is not full
      child: Container(
        color: Colors.grey[900], // Your desired background
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Text(
              "User's Custom UI!",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 20),
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
              ],
            ),
            // Add more rows or widgets
          ],
        ),
      ),
    );
  }
}
