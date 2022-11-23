package com.koso.flasher

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Handler
import android.os.Looper
import androidx.annotation.UiThread
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.MethodChannel


class Talkie private constructor(val context: Context, engine: FlutterEngine) {

    private val CHANNEL_PATH = "com.koso/flasher"
    private var channel: MethodChannel
    private val handler = MethodChannel.MethodCallHandler { call, result ->
        when (call.method) {
            "ping" -> {

            }
        }
    }
    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent) {

            val state = intent.getIntExtra(WifiManager.EXTRA_WIFI_STATE, 0)
            intent.getIntExtra(WifiManager.EXTRA_BSSID, 0)

            val wifiManager =
                context!!.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val wifiInfo: WifiInfo = wifiManager.connectionInfo
            val ssid: String = wifiInfo.ssid
            _instance?.sendConnectState(ssid, state == WifiManager.WIFI_STATE_ENABLED)


        }

    }

    init {
        FlutterLoader().apply {
            startInitialization(context)
            ensureInitializationComplete(context, arrayOf())
        }
        channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_PATH)
        channel.setMethodCallHandler(handler)

        val intentFilter = IntentFilter()
        intentFilter.addAction(WifiManager.WIFI_STATE_CHANGED_ACTION)
        context.registerReceiver(receiver, intentFilter)
    }

    companion object {
        @JvmStatic
        fun instance(context: Context, engine: FlutterEngine): Talkie {
            _instance = Talkie(context, engine)
            return _instance!!
        }

        var _instance: Talkie? = null
    }

    @UiThread
    fun sendConnectState(name: String, connected: Boolean) {
        Handler(Looper.getMainLooper()).post {
            try {
                channel.invokeMethod(
                    "connectstate", hashMapOf(
                        "name" to name,
                        "connected" to connected,
                    )
                )
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    fun onDestory() {
        context.unregisterReceiver(receiver)
    }
}