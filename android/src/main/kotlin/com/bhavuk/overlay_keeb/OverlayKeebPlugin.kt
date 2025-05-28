package com.bhavuk.overlay_keeb // Ensure this matches your package structure

import android.app.Activity
import android.content.Context
import android.graphics.PixelFormat
import android.graphics.Rect
import android.graphics.drawable.BitmapDrawable
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
// import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.PopupWindow
import androidx.annotation.NonNull

// Flutter imports
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineGroup // Import FlutterEngineGroup
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.dart.DartExecutor
// import io.flutter.embedding.engine.FlutterAssets // Not directly used in DartEntrypoint creation now
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.loader.FlutterLoader


class OverlayKeebPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
  private lateinit var channel: MethodChannel
  private var activity: Activity? = null
  private var flutterPluginBindingInstance: FlutterPlugin.FlutterPluginBinding? = null

  private var overlayFlutterEngine: FlutterEngine? = null
  private var overlayFlutterView: FlutterView? = null
  private var popupWindow: PopupWindow? = null

  private var userEntrypointFunctionName: String? = null
  private var userEntrypointLibraryPath: String? = null // This is expected to be the package URI

  // FlutterEngineGroup for managing multiple engines
  private var engineGroup: FlutterEngineGroup? = null

  companion object {
    private const val TAG = "OverlayKeebPlugin"
    private const val DEFAULT_OVERLAY_HEIGHT_DP = 250
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    this.flutterPluginBindingInstance = flutterPluginBinding
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "overlay_keeb")
    channel.setMethodCallHandler(this)
    // Initialize engineGroup here, needs a context. Application context is good.
    engineGroup = FlutterEngineGroup(flutterPluginBinding.applicationContext)
    Log.d(TAG, "onAttachedToEngine: Plugin attached and FlutterEngineGroup created.")
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    Log.d(TAG, "onDetachedFromEngine: Plugin detached from main engine. Cleaning up overlay...")
    cleanUpFlutterOverlay() // This will also destroy the engine
    engineGroup = null // Release engine group
    this.flutterPluginBindingInstance = null
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    Log.d(TAG, "onAttachedToActivity: Activity attached: ${activity?.localClassName}")
  }

  override fun onDetachedFromActivity() {
    Log.d(TAG, "onDetachedFromActivity: Activity detached: ${activity?.localClassName}. Cleaning up overlay.")
    cleanUpFlutterOverlay()
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    Log.d(TAG, "onReattachedToActivityForConfigChanges: Activity re-attached: ${activity?.localClassName}")
  }

  override fun onDetachedFromActivityForConfigChanges() {
    Log.d(TAG, "onDetachedFromActivityForConfigChanges: Activity detached for config changes.")
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    Log.d(TAG, "onMethodCall: ${call.method}")
    when (call.method) {
      "registerOverlayUi" -> {
        userEntrypointFunctionName = call.argument<String>("entrypointFunctionName")
        userEntrypointLibraryPath = call.argument<String>("entrypointLibraryPath")
        if (userEntrypointFunctionName != null && userEntrypointLibraryPath != null) {
          Log.d(TAG, "Registered overlay UI: Fn='${userEntrypointFunctionName}' Lib='${userEntrypointLibraryPath}'")
          result.success(null)
        } else {
          Log.e(TAG, "Failed to register overlay UI: function name or library path is null.")
          result.error("REGISTRATION_FAILED", "Function name or library path cannot be null.", null)
        }
      }
      "checkOverlayPermission" -> {
        Log.d(TAG, "checkOverlayPermission: Not required for PopupWindow approach. Returning true.")
        result.success(true)
      }
      "requestOverlayPermission" -> {
        Log.d(TAG, "requestOverlayPermission: Not required for PopupWindow approach. Returning true.")
        result.success(true)
      }
      "showOverlay" -> {
        if (activity == null) {
          result.error("NO_ACTIVITY", "Activity not available to show overlay.", null)
          return
        }
        if (userEntrypointFunctionName == null || userEntrypointLibraryPath == null) {
          result.error("UI_NOT_REGISTERED", "Overlay UI has not been registered. Call registerOverlayUi first.", null)
          return
        }
        if (engineGroup == null) {
          Log.e(TAG, "FlutterEngineGroup is null. Cannot create overlay engine.")
          result.error("ENGINE_GROUP_NULL", "FlutterEngineGroup not initialized.", null)
          return
        }

        Log.d(TAG, "onMethodCall('showOverlay'): Posting to UI thread for PopupWindow.")
        activity?.runOnUiThread {
          showFlutterOverlayWithPopupWindow()
        }
        result.success("Flutter Overlay (PopupWindow) show initiation posted.")
      }
      "hideOverlay" -> {
        Log.d(TAG, "onMethodCall('hideOverlay'): Posting to UI thread for PopupWindow.")
        activity?.runOnUiThread {
          hideFlutterOverlayWithPopupWindow()
        }
        result.success("Flutter Overlay (PopupWindow) hide initiation posted.")
      }
      else -> result.notImplemented()
    }
  }

  private fun showFlutterOverlayWithPopupWindow() {
    Log.d(TAG, "showFlutterOverlayWithPopupWindow: ----- Attempting to show overlay -----")
    val currentActivity = activity ?: run {
      Log.e(TAG, "showFlutterOverlayWithPopupWindow: Activity is null. Cannot show overlay.")
      return
    }
    val currentEngineGroup = engineGroup ?: run {
      Log.e(TAG, "showFlutterOverlayWithPopupWindow: FlutterEngineGroup is null. Cannot create engine.")
      return
    }
    val entrypointName = userEntrypointFunctionName!!
    val libraryUriFromDart = userEntrypointLibraryPath!! // This IS the package URI from Dart

    if (popupWindow?.isShowing == true || overlayFlutterEngine != null) {
      Log.w(TAG, "showFlutterOverlayWithPopupWindow: Existing popup or engine found. Forcing cleanup first.")
      hideFlutterOverlayInternal()
    }

    Log.d(TAG, "showFlutterOverlayWithPopupWindow: Proceeding to create new overlay.")

    val keyboardHeight = getKeyboardHeight(currentActivity)
    Log.d(TAG, "showFlutterOverlayWithPopupWindow: Using keyboard height: $keyboardHeight px.")

    val overlayHeightInPixels = if (keyboardHeight > 0) keyboardHeight else (DEFAULT_OVERLAY_HEIGHT_DP * currentActivity.resources.displayMetrics.density).toInt()

    // FlutterLoader is still used by FlutterEngineGroup implicitly.
    // val flutterLoader: FlutterLoader = FlutterInjector.instance().flutterLoader()
    // if (!flutterLoader.initialized()) {
    //     Log.d(TAG, "showFlutterOverlayWithPopupWindow: Initializing FlutterLoader.")
    //     flutterLoader.startInitialization(currentActivity.applicationContext)
    //     flutterLoader.ensureInitializationComplete(currentActivity.applicationContext, null)
    // }

    Log.d(TAG, "showFlutterOverlayWithPopupWindow: Creating and running new FlutterEngine via FlutterEngineGroup for overlay.")

    // --- MODIFIED DartEntrypoint and Engine Creation using FlutterEngineGroup ---
    // The DartEntrypoint now only needs the URI and function name if appBundlePath is handled by the group.
    // However, the createAndRunEngine method often takes a DartExecutor.DartEntrypoint.
    // Let's use the standard DartEntrypoint constructor that takes appBundlePath.
    val appBundlePath = FlutterInjector.instance().flutterLoader().findAppBundlePath()
    if (appBundlePath == null) {
      Log.e(TAG, "showFlutterOverlayWithPopupWindow: appBundlePath is null. Flutter assets not found for DartEntrypoint?")
      return
    }

    val dartEntrypoint = DartExecutor.DartEntrypoint(
      appBundlePath,      // Path to the flutter_assets directory
      libraryUriFromDart, // This should be the package URI like "package:overlay_keeb_example/custom_overlay.dart"
      entrypointName
    )

    // Create and run the engine using the group
    // The context passed here is for the engine's general Android system services.
    overlayFlutterEngine = currentEngineGroup.createAndRunEngine(currentActivity.applicationContext, dartEntrypoint)

    Log.d(TAG, "showFlutterOverlayWithPopupWindow: Engine created and Dart entrypoint execution initiated via FlutterEngineGroup.")
    Log.d(TAG, "showFlutterOverlayWithPopupWindow: Executing USER'S Dart entrypoint: $entrypointName (using library URI '$libraryUriFromDart')")


    Log.d(TAG, "showFlutterOverlayWithPopupWindow: Creating FlutterView for overlay.")
    overlayFlutterView = FlutterView(currentActivity)
    overlayFlutterView!!.attachToFlutterEngine(overlayFlutterEngine!!) // Attach the newly created engine

    popupWindow = PopupWindow(
      overlayFlutterView,
      WindowManager.LayoutParams.MATCH_PARENT,
      overlayHeightInPixels
    )

    popupWindow?.isFocusable = false
    popupWindow?.isOutsideTouchable = true
    popupWindow?.setBackgroundDrawable(BitmapDrawable())
    popupWindow?.softInputMode = WindowManager.LayoutParams.SOFT_INPUT_STATE_UNCHANGED

    try {
      val styleId = currentActivity.resources.getIdentifier("OverlayAnimation", "style", currentActivity.packageName)
      if (styleId != 0) {
        popupWindow?.animationStyle = styleId
        Log.d(TAG, "showFlutterOverlayWithPopupWindow: Applied window animations to PopupWindow (Style ID: $styleId).")
      } else {
        Log.w(TAG, "showFlutterOverlayWithPopupWindow: OverlayAnimation style not found for PopupWindow.")
      }
    } catch (e: Exception) {
      Log.e(TAG, "showFlutterOverlayWithPopupWindow: Error applying animations to PopupWindow.", e)
    }

    val rootView = currentActivity.window.decorView.rootView
    if (rootView != null && rootView.windowToken != null) {
      popupWindow?.showAtLocation(rootView, Gravity.BOTTOM, 0, 0)
      Log.d(TAG, "showFlutterOverlayWithPopupWindow: PopupWindow shown at bottom. Height: $overlayHeightInPixels px.")
    } else {
      Log.e(TAG, "showFlutterOverlayWithPopupWindow: Root view or its window token is null. Cannot show PopupWindow.")
      cleanUpFlutterOverlay()
    }
  }

  private fun getKeyboardHeight(activity: Activity): Int { /* ... same as before ... */
    val rect = Rect()
    activity.window.decorView.getWindowVisibleDisplayFrame(rect)
    val screenHeight = activity.window.decorView.rootView.height
    val keyboardHeight = screenHeight - rect.bottom

    if (keyboardHeight > screenHeight * 0.15) {
      Log.d(TAG, "getKeyboardHeight: Detected keyboard height: $keyboardHeight")
      return if (keyboardHeight - 50 > 0) keyboardHeight - 50 else keyboardHeight
    }
    Log.w(TAG, "getKeyboardHeight: Keyboard not detected or too small. Falling back to default ${DEFAULT_OVERLAY_HEIGHT_DP}dp.")
    return (DEFAULT_OVERLAY_HEIGHT_DP * activity.resources.displayMetrics.density).toInt()
  }

  private fun hideFlutterOverlayInternal() { /* ... same as before ... */
    Log.d(TAG, "hideFlutterOverlayInternal: ----- Attempting to hide/dismiss PopupWindow -----")
    popupWindow?.let {
      if (it.isShowing) {
        try {
          it.dismiss()
          Log.d(TAG, "hideFlutterOverlayInternal: PopupWindow dismissed.")
        } catch (e: Exception) {
          Log.e(TAG, "hideFlutterOverlayInternal: Exception dismissing PopupWindow.", e)
        }
      }
    }
    popupWindow = null

    overlayFlutterView?.detachFromFlutterEngine()
    overlayFlutterView = null
    // The engine created by FlutterEngineGroup is managed by the group.
    // Destroying it here might be redundant or incorrect if the group handles its lifecycle.
    // Typically, you destroy engines when the group itself is no longer needed or if you explicitly want to free one.
    // For now, let's keep the explicit destroy, but be aware of group management.
    overlayFlutterEngine?.destroy()
    overlayFlutterEngine = null
    Log.d(TAG, "hideFlutterOverlayInternal: Flutter engine and view resources nulled and engine destroyed.")
  }

  private fun hideFlutterOverlayWithPopupWindow() { /* ... same as before ... */
    Log.d(TAG, "hideFlutterOverlayWithPopupWindow (from MethodChannel): Hiding overlay.")
    hideFlutterOverlayInternal()
  }

  private fun cleanUpFlutterOverlay() { /* ... same as before ... */
    Log.d(TAG, "cleanUpFlutterOverlay: Posting hideFlutterOverlayInternal to main thread.")
    val mainHandler = Handler(Looper.getMainLooper())
    mainHandler.post {
      hideFlutterOverlayInternal()
    }
  }
}
