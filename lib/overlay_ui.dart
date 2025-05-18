// overlay_keeb/lib/overlay_ui.dart

import 'package:flutter/material.dart';

@pragma('vm:entry-point')
void overlayMain() {
  runApp(const OverlayApp());
}

class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayContent(),
    );
  }
}

class OverlayContent extends StatelessWidget {
  const OverlayContent({super.key});

  // Helper function to build individual picker items
  Widget _buildPickerItem(
    BuildContext context,
    IconData icon,
    String label,
    Color iconBgColor,
  ) {
    return InkWell(
      onTap: () {
        // IMPORTANT: This 'print' will go to the device log for the overlay's Flutter instance,
        // not necessarily your main app's debug console directly without extra setup.
        // To send data back to your main app, you'd need to set up a MethodChannel
        // for this secondary Flutter engine. For now, let's focus on UI.
        print('Overlay item tapped: $label');

        // Example: If you wanted to close the overlay from a button within the overlay UI itself
        // you would need a MethodChannel call back to the native plugin to tell it to hide.
        // For now, closing is handled by your main app's ChatScreen.
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[800],
            child: Icon(icon, size: 26, color: iconBgColor),
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
    // The native side controls the window height (set to 250dp).
    // This Container will fill that window.
    return Material(
      child: Container(
        // Set the background color for your picker panel
        color: Colors.grey[900], // WhatsApp-like light grey background
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.spaceAround, // Distribute rows of items
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // First row of items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildPickerItem(
                  context,
                  Icons.description,
                  'Document',
                  Colors.indigo,
                ),
                _buildPickerItem(
                  context,
                  Icons.camera_alt,
                  'Camera',
                  Colors.pink,
                ),
                _buildPickerItem(
                  context,
                  Icons.photo_library,
                  'Gallery',
                  Colors.purple,
                ),
              ],
            ),
            // Second row of items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildPickerItem(
                  context,
                  Icons.headset,
                  'Audio',
                  Colors.orange,
                ),
                _buildPickerItem(
                  context,
                  Icons.location_on,
                  'Location',
                  Colors.green,
                ),
                _buildPickerItem(context, Icons.person, 'Contact', Colors.blue),
                // Add more items or rows as needed
              ],
            ),
            // You could add more rows or a different layout
          ],
        ),
      ),
    );
  }
}
