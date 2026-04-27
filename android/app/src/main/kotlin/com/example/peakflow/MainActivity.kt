package com.joscha0.peakflow

import android.graphics.Rect
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val systemGestureExclusionChannel = "peakflow/system_gesture_exclusion"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            systemGestureExclusionChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setRects" -> {
                    setSystemGestureExclusionRects(call.arguments)
                    result.success(null)
                }
                "clear" -> {
                    setSystemGestureExclusionRects(emptyList<Map<String, Int>>())
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setSystemGestureExclusionRects(arguments: Any?) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return
        }

        val rects = (arguments as? List<*>)?.mapNotNull { item ->
            val rect = item as? Map<*, *> ?: return@mapNotNull null
            val left = (rect["left"] as? Number)?.toInt() ?: return@mapNotNull null
            val top = (rect["top"] as? Number)?.toInt() ?: return@mapNotNull null
            val right = (rect["right"] as? Number)?.toInt() ?: return@mapNotNull null
            val bottom = (rect["bottom"] as? Number)?.toInt() ?: return@mapNotNull null
            Rect(left, top, right, bottom)
        } ?: emptyList()

        window.decorView.post {
            window.decorView.systemGestureExclusionRects = rects
        }
    }
}
