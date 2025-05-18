package com.bhavuk.overlay_keeb

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.WindowManager
import androidx.annotation.NonNull

// Flutter imports
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.loader.FlutterLoader

class OverlayKeebPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel: MethodChannel
  private var activity: Activity? = null
  private var windowManager: WindowManager? = null
  private var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null

  private var overlayFlutterEngine: FlutterEngine? = null
  private var overlayFlutterView: FlutterView? = null

  companion object {
    private const val TAG = "OverlayKeebPlugin"
    private const val OVERLAY_PERMISSION_REQUEST_CODE = 1234
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    this.flutterPluginBinding = flutterPluginBinding
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "overlay_keeb")
    channel.setMethodCallHandler(this)
    Log.d(TAG, "OverlayKeebPlugin attached to engine.")
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    Log.d(TAG, "OverlayKeebPlugin detached from main engine. Cleaning up overlay...")
    cleanUpFlutterOverlay()
    this.flutterPluginBinding = null
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    windowManager = activity?.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    Log.d(TAG, "OverlayKeebPlugin attached to activity: ${activity?.localClassName}")
  }

  override fun onDetachedFromActivity() {
    Log.d(TAG, "OverlayKeebPlugin detached from activity: ${activity?.localClassName}. Cleaning up overlay.")
    cleanUpFlutterOverlay()
    activity = null
    windowManager = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    windowManager = activity?.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    Log.d(TAG, "OverlayKeebPlugin re-attached to activity: ${activity?.localClassName}")
  }

  override fun onDetachedFromActivityForConfigChanges() {
    Log.d(TAG, "OverlayKeebPlugin detached from activity for config changes.")
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    Log.d(TAG, "Method call: ${call.method}")
    when (call.method) {
      "checkOverlayPermission" -> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
          result.success(Settings.canDrawOverlays(activity))
        } else {
          result.success(true)
        }
      }
      "requestOverlayPermission" -> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
          if (activity == null) {
            result.error("NO_ACTIVITY", "Activity is not available to request permission.", null)
            return
          }
          if (!Settings.canDrawOverlays(activity!!)) {
            val intent = Intent(
              Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
              Uri.parse("package:${activity!!.packageName}")
            )
            activity!!.startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST_CODE)
            result.success(false)
          } else {
            result.success(true)
          }
        } else {
          result.success(true)
        }
      }
      "showOverlay" -> {
        if (activity == null || windowManager == null) {
          result.error("NO_ACTIVITY_OR_WM", "Activity or WindowManager not available.", null)
          return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(activity)) {
          result.error("NO_PERMISSION", "Overlay permission not granted.", null)
          return
        }
        try {
          activity?.runOnUiThread {
            showFlutterOverlay()
          }
          result.success("Flutter Overlay show initiated")
        } catch (e: Exception) {
          Log.e(TAG, "Error showing overlay", e)
          result.error("SHOW_ERROR", "Failed to show Flutter overlay: ${e.message}", e.toString())
        }
      }
      "hideOverlay" -> {
        try {
          activity?.runOnUiThread {
            hideFlutterOverlay()
          }
          result.success("Flutter Overlay hide initiated")
        } catch (e: Exception) {
          Log.e(TAG, "Error hiding overlay", e)
          result.error("HIDE_ERROR", "Failed to hide Flutter overlay: ${e.message}", e.toString())
        }
      }
      else -> result.notImplemented()
    }
  }

  private fun showFlutterOverlay(keyboardHeightParam: Int? = null) {
    val currentActivity = activity ?: run {
      Log.e(TAG, "Activity is null in showFlutterOverlay. Cannot show overlay.")
      return
    }

    Log.d(TAG, "Attempting to show Flutter overlay")

    // Ensure previous instance is cleaned
    hideFlutterOverlay()

    // Get keyboard height from the system
    val keyboardHeight = keyboardHeightParam ?: getKeyboardHeight(currentActivity)
    Log.d(TAG, "Using keyboard height: $keyboardHeight")

    val flutterLoader: FlutterLoader = FlutterInjector.instance().flutterLoader()
    if (!flutterLoader.initialized()) {
      flutterLoader.startInitialization(currentActivity.applicationContext)
      flutterLoader.ensureInitializationComplete(currentActivity.applicationContext, null)
    }

    val appBundlePath = flutterLoader.findAppBundlePath()
    if (appBundlePath == null) {
      Log.e(TAG, "appBundlePath is null. Cannot create DartEntrypoint.")
      return
    }

    // Create new engine
    overlayFlutterEngine = FlutterEngine(currentActivity.applicationContext)

    val dartEntrypoint = DartExecutor.DartEntrypoint(
      appBundlePath,
      "package:overlay_keeb/overlay_ui.dart",
      "overlayMain"
    )

    overlayFlutterEngine!!.dartExecutor.executeDartEntrypoint(dartEntrypoint)

    // Create and attach view
    overlayFlutterView = FlutterView(currentActivity)
    overlayFlutterView!!.attachToFlutterEngine(overlayFlutterEngine!!)

    val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
    } else {
      WindowManager.LayoutParams.TYPE_PHONE
    }

    val params = WindowManager.LayoutParams(
      WindowManager.LayoutParams.MATCH_PARENT,
      keyboardHeight,
      layoutFlag,
      WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
      PixelFormat.TRANSLUCENT
    ).apply {
      gravity = Gravity.BOTTOM

        x = 0
        y = 0
        width = WindowManager.LayoutParams.MATCH_PARENT
        height = keyboardHeight
        flags = flags or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL


      try {
        val styleId = currentActivity.resources.getIdentifier("OverlayAnimation", "style", currentActivity.packageName)
        if (styleId != 0) {
          windowAnimations = styleId
          Log.d(TAG, "showFlutterOverlay: Applied window animations using style ID: $styleId")
        } else {
          Log.w(TAG, "showFlutterOverlay: OverlayAnimation style not found! Animations will not play. Package name checked: ${currentActivity.packageName}")
        }
      } catch (e: Exception) {
      Log.e(TAG, "showFlutterOverlay: Error applying window animations.", e)
    }


    }

    try {
      windowManager?.addView(overlayFlutterView, params)
      Log.d(TAG, "Flutter overlay added to WindowManager with height: $keyboardHeight")
    } catch (e: Exception) {
      Log.e(TAG, "Error adding overlay to WindowManager", e)
      cleanUpFlutterOverlay()
    }
  }

  private fun getKeyboardHeight(activity: Activity): Int {
    // Get the visible display frame
    val rect = android.graphics.Rect()
    activity.window.decorView.getWindowVisibleDisplayFrame(rect)

    // Calculate the screen height
    val screenHeight = activity.window.decorView.rootView.height

    // Calculate keyboard height (if keyboard is visible)
    val keyboardHeight = screenHeight - rect.bottom

    // If keyboard height is significant, use it
    if (keyboardHeight > 100) {
      return keyboardHeight - 50
    }

    // If keyboard is not visible, get the height from the display metrics
    // This gets approximately 1/3 of the screen height which is typical for keyboards
    val displayMetrics = activity.resources.displayMetrics
    val screenHeightPixels = displayMetrics.heightPixels
    return (screenHeightPixels / 3)
  }

  private fun hideFlutterOverlay() {
    Log.d(TAG, "Hiding Flutter overlay with slide-out animation.")
    overlayFlutterView?.let { view ->
      try {
        if (view.isAttachedToWindow) {
          // Get the animation duration to properly time the removal
          val animDuration = activity?.resources?.getInteger(android.R.integer.config_mediumAnimTime) ?: 300

          // Create and start animation listener to remove view after animation completes
          val listener = object : android.animation.AnimatorListenerAdapter() {
            override fun onAnimationEnd(animation: android.animation.Animator) {
              try {
                if (view.isAttachedToWindow) {
                  windowManager?.removeView(view)
                  Log.d(TAG, "Overlay view removed after animation completed.")
                }
                view.detachFromFlutterEngine()
                overlayFlutterView = null
                overlayFlutterEngine?.destroy()
                overlayFlutterEngine = null
              } catch (e: Exception) {
                Log.e(TAG, "Error removing overlay view after animation", e)
              }
            }
          }

          // Start disappearing animation programmatically
          val anim = android.animation.ObjectAnimator.ofFloat(view, "translationY", 0f, view.height.toFloat())
          anim.duration = animDuration.toLong()
          anim.interpolator = android.view.animation.AccelerateInterpolator()
          anim.addListener(listener)

          // Fade out simultaneously
          val fadeAnim = android.animation.ObjectAnimator.ofFloat(view, "alpha", 1f, 0f)
          fadeAnim.duration = animDuration.toLong()

          // Play both animations together
          val animSet = android.animation.AnimatorSet()
          animSet.playTogether(anim, fadeAnim)
          animSet.start()
        }
      } catch (e: Exception) {
        Log.e(TAG, "Error initiating overlay hide animation", e)
        // Fallback to immediate removal
        try {
          windowManager?.removeView(view)
        } catch (e2: Exception) {
          Log.e(TAG, "Error in fallback removal", e2)
        }
        view.detachFromFlutterEngine()
        overlayFlutterView = null
        overlayFlutterEngine?.destroy()
        overlayFlutterEngine = null
      }
    }
  }

  private fun cleanUpFlutterOverlay() {
    Log.d(TAG, "Executing cleanUpFlutterOverlay.")
    val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())
    mainHandler.post {
      hideFlutterOverlay()
    }
  }
}