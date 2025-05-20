import Flutter
import UIKit

// Helper to find the first responder
extension UIResponder {
    private static weak var _currentFirstResponder: UIResponder?

    public static var currentFirstResponder: UIResponder? {
        _currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(UIResponder.findFirstResponder(_:)), to: nil, from: nil, for: nil)
        return _currentFirstResponder
    }

    @objc internal func findFirstResponder(_ sender: Any) {
        UIResponder._currentFirstResponder = self
    }
}

public class OverlayKeebPlugin: NSObject, FlutterPlugin { // Removed FlutterStreamHandler for now to simplify
    private var channel: FlutterMethodChannel
    private var overlayEngine: FlutterEngine?
    private var overlayViewController: FlutterViewController?
    private var accessoryHostView: UIView? // The UIView that will be the inputAccessoryView
    private var keyboardEventSink: FlutterEventSink? // Ad

    // Store registrar if needed for assets, though often not for engine.run with package URI
    private var registrar: FlutterPluginRegistrar?

    // To keep track of which responder has our accessory view
    private weak var currentAccessoryResponder: UIResponder?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "overlay_keeb", binaryMessenger: registrar.messenger())
        let instance = OverlayKeebPlugin(channel: channel, registrar: registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
        Log.d("Plugin registered with InputAccessoryView approach.")
    }

    init(channel: FlutterMethodChannel, registrar: FlutterPluginRegistrar) {
        self.channel = channel
        self.registrar = registrar
        super.init()
        Log.d("OverlayKeebPlugin instance initialized.")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        Log.d("iOS handle method call: \(call.method)")
        switch call.method {
        case "checkOverlayPermission", "requestOverlayPermission":
            // Not applicable for inputAccessoryView in the same way
            result(true)
        case "showOverlay":
            let arguments = call.arguments as? [String: Any]
            let overlayHeightDp = arguments?["overlayHeightDp"] as? Int
            let heightInPoints = CGFloat(overlayHeightDp ?? 250) // Default or passed height

            DispatchQueue.main.async {
                self.showAccessoryFlutterOverlay(heightInPoints: heightInPoints)
            }
            result("iOS InputAccessoryView show initiated")
        case "hideOverlay":
            DispatchQueue.main.async {
                self.hideAccessoryFlutterOverlay()
            }
            result("iOS InputAccessoryView hide initiated")
        default:
            result(FlutterMethodNotImplemented)
        }
    }

  private func showAccessoryFlutterOverlay(heightInPoints: CGFloat) {
      Log.d("Attempting to show InputAccessoryView overlay with height: \(heightInPoints) points.")

      // Clean up any existing overlay
      if accessoryHostView != nil || overlayEngine != nil {
          Log.w("Existing accessory view or engine found. Cleaning up before showing new one.")
          hideAccessoryFlutterOverlayInternal()
      }

      // MODIFIED CODE: Create a default input accessory view even if no responder
      // is currently active - this will work when a text field becomes active
      let createAccessoryView = { [weak self] in
          guard let self = self else { return }

          // Create Flutter Engine & ViewController
          self.overlayEngine = FlutterEngine(name: "com.bhavuk.overlay_keeb.AccessoryEngine-\(UUID().uuidString)", project: nil, allowHeadlessExecution: true)
          guard let currentOverlayEngine = self.overlayEngine else {
              Log.e("Failed to create overlay FlutterEngine for accessory.")
              return
          }

          let libraryURI = "package:overlay_keeb/overlay_ui.dart"
          let entrypoint = "overlayMain"
          Log.d("Executing Dart entrypoint: '\(entrypoint)' from library: '\(libraryURI)' for accessory.")
          currentOverlayEngine.run(withEntrypoint: entrypoint, libraryURI: libraryURI)

          self.overlayViewController = FlutterViewController(engine: currentOverlayEngine, nibName: nil, bundle: nil)
          guard let currentOverlayVC = self.overlayViewController, let flutterView = currentOverlayVC.view else {
              Log.e("Failed to create overlay FlutterViewController or its view.")
              self.overlayEngine?.destroyContext()
              self.overlayEngine = nil
              return
          }
          flutterView.backgroundColor = .clear
          flutterView.isOpaque = false

          // Create the host UIView for the inputAccessoryView
          self.accessoryHostView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: heightInPoints))
          guard let currentAccessoryHostView = self.accessoryHostView else {
              Log.e("Failed to create accessoryHostView.")
              self.overlayViewController = nil
              self.overlayEngine?.destroyContext()
              self.overlayEngine = nil
              return
          }
          currentAccessoryHostView.backgroundColor = .clear

          // Add Flutter view to the host view
          flutterView.frame = currentAccessoryHostView.bounds
          flutterView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
          currentAccessoryHostView.addSubview(flutterView)

          // Now actively look for text fields in the view hierarchy and add our accessory view
          self.findAndUpdateTextFields()
      }

      createAccessoryView()
  }

    private func findAndUpdateTextFields() {
        // Find the first responder
        if let firstResponder = UIResponder.currentFirstResponder {
            currentAccessoryResponder = firstResponder
            Log.d("Current first responder: \(type(of: firstResponder))")
            if let textField = firstResponder as? UITextField {
                textField.inputAccessoryView = accessoryHostView
                textField.reloadInputViews()
                Log.d("InputAccessoryView added to UITextField.")
            } else if let textView = firstResponder as? UITextView {
                textView.inputAccessoryView = accessoryHostView
                textView.reloadInputViews()
                Log.d("InputAccessoryView added to UITextView.")
            } else {
                Log.w("Current responder is not a UITextField or UITextView. Accessory view not added.")
            }
        } else {
            Log.w("No current first responder found. Accessory view not added.")
        }
    }

    private func hideAccessoryFlutterOverlayInternal() {
        Log.d("hideAccessoryFlutterOverlayInternal: Attempting to hide/remove InputAccessoryView.")

        if let responder = currentAccessoryResponder {
            var success = false
            if let textField = responder as? UITextField, textField.inputAccessoryView == accessoryHostView {
                textField.inputAccessoryView = nil
                success = true
            } else if let textView = responder as? UITextView, textView.inputAccessoryView == accessoryHostView {
                textView.inputAccessoryView = nil
                success = true
            }
            // else if responder.responds(to: NSSelectorFromString("inputAccessoryView")) &&
            //          responder.value(forKey: "inputAccessoryView") as? UIView == accessoryHostView {
            //     responder.setValue(nil, forKey: "inputAccessoryView")
            //     success = true
            // }

            if success {
                responder.reloadInputViews()
                Log.d("InputAccessoryView removed from \(type(of: responder)) and reloadInputViews called.")
            } else {
                Log.w("Could not cleanly remove inputAccessoryView or it was already nil.")
            }
        } else {
            Log.d("No currentAccessoryResponder tracked to remove inputAccessoryView from.")
        }
        currentAccessoryResponder = nil

        // Cleanup Flutter resources
        accessoryHostView?.subviews.forEach { $0.removeFromSuperview() } // Remove FlutterView
        accessoryHostView = nil

        overlayViewController = nil // VC's view is already removed

        overlayEngine?.destroyContext()
        overlayEngine = nil

        Log.d("Flutter engine and accessory view resources cleaned up.")
    }

    private func hideAccessoryFlutterOverlay() {
        hideAccessoryFlutterOverlayInternal()
    }

    private func cleanUpFlutterOverlay() { // Called on plugin detach
        Log.d("cleanUpFlutterOverlay (plugin detach): Posting hideAccessoryFlutterOverlayInternal to main thread.")
        DispatchQueue.main.async {
            self.hideAccessoryFlutterOverlayInternal()
        }
    }

    // FlutterStreamHandler methods are not used in this approach for now

}

// Logger utility (ensure it's defined as before)
class Log { /* ... */
    static func d(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("DEBUG [OverlayKeebPlugin] \(fileName):\(line) \(function) -> \(message)")
        #endif
    }
    static func e(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("ERROR [OverlayKeebPlugin] \(fileName):\(line) \(function) -> \(message)")
        #endif
    }
    static func w(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("WARN [OverlayKeebPlugin] \(fileName):\(line) \(function) -> \(message)")
        #endif
    }
}
