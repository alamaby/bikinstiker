package com.alamaby.bikin_stiker

import android.content.ContentProvider
import android.content.ContentValues
import android.content.UriMatcher
import android.database.Cursor
import android.database.MatrixCursor
import android.content.res.AssetFileDescriptor
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileNotFoundException

class StickerContentProvider : ContentProvider() {

    companion object {
        private const val TAG = "StickerCP"
        private const val METADATA = 1
        private const val METADATA_SINGLE = 2
        private const val STICKERS = 3
        private const val STICKERS_ASSET = 4

        private val METADATA_COLUMNS = arrayOf(
            "sticker_pack_identifier",
            "sticker_pack_name",
            "sticker_pack_publisher",
            "sticker_pack_icon",
            "android_play_store_link",
            "ios_app_download_link",
            "sticker_pack_publisher_email",
            "sticker_pack_publisher_website",
            "sticker_pack_privacy_policy_website",
            "sticker_pack_license_agreement_website",
            "image_data_version",
            "whatsapp_will_not_cache_stickers",
            "animated_sticker_pack",
        )

        private val STICKER_COLUMNS = arrayOf(
            "sticker_file_name",
            "sticker_emoji",
            "sticker_accessibility_text",
        )
    }

    private data class AssetInfo(
        val pfd: ParcelFileDescriptor,
        val length: Long,
        val mimeType: String,
    )

    private lateinit var authority: String
    private lateinit var filesDir: File

    private val uriMatcher by lazy {
        val matcher = UriMatcher(UriMatcher.NO_MATCH)
        matcher.addURI(authority, "metadata", METADATA)
        matcher.addURI(authority, "metadata/*", METADATA_SINGLE)
        matcher.addURI(authority, "stickers/*", STICKERS)
        matcher.addURI(authority, "stickers_asset/*/*", STICKERS_ASSET)
        matcher
    }

    override fun onCreate(): Boolean {
        context?.let {
            authority = it.applicationContext.packageName + ".stickercontentprovider"
            filesDir = it.filesDir
        } ?: run {
            Log.e(TAG, "onCreate: context is null")
            return false
        }
        return true
    }

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?,
    ): Cursor? {
        val match = uriMatcher.match(uri)
        return when (match) {
            METADATA -> queryAllPacks()
            METADATA_SINGLE -> {
                val identifier = uri.lastPathSegment ?: return null
                querySinglePack(identifier)
            }
            STICKERS -> {
                val identifier = uri.lastPathSegment ?: return null
                queryStickers(identifier)
            }
            else -> null
        }
    }

    override fun getType(uri: Uri): String? {
        val match = uriMatcher.match(uri)
        return when (match) {
            METADATA -> "vnd.android.cursor.dir/vnd.$authority.metadata"
            METADATA_SINGLE -> "vnd.android.cursor.item/vnd.$authority.metadata"
            STICKERS -> "vnd.android.cursor.dir/vnd.$authority.stickers"
            STICKERS_ASSET -> {
                val fileName = uri.lastPathSegment ?: ""
                if (fileName.endsWith(".png", ignoreCase = true)) "image/png" else "image/webp"
            }
            else -> null
        }
    }

    override fun openAssetFile(uri: Uri, mode: String): AssetFileDescriptor? {
        val match = uriMatcher.match(uri)
        val asset = when (match) {
            STICKERS_ASSET -> {
                val segments = uri.pathSegments
                if (segments.size < 3) throw FileNotFoundException("Invalid URI: $uri")
                val packId = segments[1]
                val fileName = segments[2]
                resolveAsset(packId, fileName)
            }
            else -> throw FileNotFoundException("Unknown URI: $uri")
        }
        return AssetFileDescriptor(asset.pfd, 0, asset.length)
    }

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?) = 0
    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?) = 0

    private fun readPacksIndex(): JSONArray {
        val indexFile = File(filesDir, "packs_index.json")
        if (!indexFile.exists()) return JSONArray()
        return try {
            JSONArray(indexFile.readText())
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse packs_index.json", e)
            JSONArray()
        }
    }

    private fun queryAllPacks(): Cursor {
        val cursor = MatrixCursor(METADATA_COLUMNS)
        val packs = readPacksIndex()
        for (i in 0 until packs.length()) {
            val pack = packs.getJSONObject(i)
            addPackRow(cursor, pack)
        }
        return cursor
    }

    private fun querySinglePack(identifier: String): Cursor {
        val cursor = MatrixCursor(METADATA_COLUMNS)
        val packs = readPacksIndex()
        for (i in 0 until packs.length()) {
            val pack = packs.getJSONObject(i)
            if (pack.optString("identifier") == identifier) {
                addPackRow(cursor, pack)
                break
            }
        }
        return cursor
    }

    private fun queryStickers(identifier: String): Cursor {
        val cursor = MatrixCursor(STICKER_COLUMNS)
        val packs = readPacksIndex()
        for (i in 0 until packs.length()) {
            val pack = packs.getJSONObject(i)
            if (pack.optString("identifier") == identifier) {
                val stickers = pack.optJSONArray("stickers") ?: JSONArray()
                for (j in 0 until stickers.length()) {
                    val sticker = stickers.getJSONObject(j)
                    cursor.addRow(arrayOf(
                        sticker.optString("file_name", ""),
                        sticker.optString("emoji", "🙂"),
                        sticker.optString("accessibility_text", "Sticker"),
                    ))
                }
                break
            }
        }
        return cursor
    }

    private fun addPackRow(cursor: MatrixCursor, pack: JSONObject) {
        val identifier = pack.optString("identifier", "")
        val trayIconFile = pack.optString("tray_icon_file", "$identifier.png")
        cursor.addRow(arrayOf(
            identifier,
            pack.optString("name", ""),
            pack.optString("publisher", "BikinStiker"),
            trayIconFile,
            pack.optString("android_play_store_link",
                "https://play.google.com/store/apps/details?id=com.alamaby.bikin_stiker"),
            pack.optString("ios_app_download_link", ""),
            pack.optString("sticker_pack_publisher_email", ""),
            pack.optString("sticker_pack_publisher_website", ""),
            pack.optString("sticker_pack_privacy_policy_website", ""),
            pack.optString("sticker_pack_license_agreement_website", ""),
            pack.optString("image_data_version", "1"),
            if (pack.optBoolean("whatsapp_will_not_cache_stickers", false)) 1 else 0,
            if (pack.optBoolean("animated_sticker_pack", false)) 1 else 0,
        ))
    }

    private fun resolveAsset(packId: String, fileName: String): AssetInfo {
        val trayFile = File(filesDir, "tray_icons/$packId.png")
        if (trayFile.exists() && fileName == "$packId.png") {
            return AssetInfo(
                pfd = ParcelFileDescriptor.open(trayFile, ParcelFileDescriptor.MODE_READ_ONLY),
                length = trayFile.length(),
                mimeType = "image/png",
            )
        }

        val stickerFile = File(filesDir, "pack_stickers/$packId/$fileName")
        if (!stickerFile.exists()) {
            throw FileNotFoundException("File not cached: $fileName (packId=$packId)")
        }
        return AssetInfo(
            pfd = ParcelFileDescriptor.open(stickerFile, ParcelFileDescriptor.MODE_READ_ONLY),
            length = stickerFile.length(),
            mimeType = "image/webp",
        )
    }
}
