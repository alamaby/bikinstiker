package com.alamaby.bikin_stiker

import android.content.Intent
import android.content.pm.PackageManager
import android.util.Log
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val TAG = "MainActivity"
        private const val CHANNEL = "com.alamaby.bikin_stiker/whatsapp"
    }

    private var pendingResult: MethodChannel.Result? = null

    private val stickerLauncher: ActivityResultLauncher<Intent> =
        registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
            Log.d(TAG, "Sticker activity result: resultCode=${result.resultCode}")
            val r = pendingResult
            pendingResult = null
            if (r != null) {
                r.success(result.resultCode)
            }
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isWhatsAppInstalled" -> {
                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            data = android.net.Uri.parse("whatsapp://")
                        }
                        val resolved = packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
                        result.success(resolved != null)
                    }
                    "launchWhatsAppStickerActivity" -> {
                        val packId = call.argument<String>("sticker_pack_id") ?: ""
                        val authority = call.argument<String>("sticker_pack_authority") ?: ""
                        val name = call.argument<String>("sticker_pack_name") ?: ""
                        val publisher = call.argument<String>("sticker_pack_publisher") ?: ""

                        Log.d(TAG, "launchWhatsAppStickerActivity: id=$packId, authority=$authority")

                        val intent = Intent().apply {
                            action = "com.whatsapp.intent.action.ENABLE_STICKER_PACK"
                            putExtra("sticker_pack_id", packId)
                            putExtra("sticker_pack_authority", authority)
                            putExtra("sticker_pack_name", name)
                            putExtra("sticker_pack_publisher", publisher)
                            setPackage("com.whatsapp")
                        }

                        pendingResult = result
                        try {
                            stickerLauncher.launch(intent)
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to launch sticker activity", e)
                            pendingResult = null
                            result.error("LAUNCH_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
