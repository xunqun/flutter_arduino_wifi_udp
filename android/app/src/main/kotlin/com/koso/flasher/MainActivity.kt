package com.koso.flasher

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Talkie.instance(this, flutterEngine)
    }

    override fun onDestroy() {
        super.onDestroy()
        Talkie._instance?.onDestory()
    }
}
