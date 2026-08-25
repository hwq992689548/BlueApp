package com.feixiang.blueapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var classicSppPlugin: ClassicSppPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        classicSppPlugin = ClassicSppPlugin(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        classicSppPlugin?.dispose()
        classicSppPlugin = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
