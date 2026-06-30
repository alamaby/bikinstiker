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
            Log.d(TAG, "onCreate: authority=$authority, filesDir=$filesDir")
            Log.d(TAG, "packs_index.json exists=${File(filesDir, "packs_index.json").exists()}")
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
        Log.d(TAG, "query: uri=$uri, match=$match")
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
            else -> {
                Log.w(TAG, "query: unknown URI: $uri")
                null
            }
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
        Log.d(TAG, "openAssetFile: uri=$uri, match=$match")
        val asset = when (match) {
            STICKERS_ASSET -> {
                val segments = uri.pathSegments
                if (segments.size < 3) throw FileNotFoundException("Invalid URI: $uri")
                val packId = segments[1]
                val fileName = segments[2]
                Log.d(TAG, "openAssetFile: packId=$packId, fileName=$fileName")
                resolveAsset(packId, fileName)
            }
            else -> throw FileNotFoundException("Unknown URI: $uri")
        }
        Log.d(TAG, "openAssetFile: returning length=${asset.length}, mimeType=${asset.mimeType}")
        return AssetFileDescriptor(asset.pfd, 0, asset.length)
    }

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?) = 0
    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?) = 0

    private fun readPacksIndex(): JSONArray {
        val indexFile = File(filesDir, "packs_index.json")
        if (!indexFile.exists()) {
            Log.w(TAG, "readPacksIndex: packs_index.json does not exist")
            return JSONArray()
        }
        return try {
            val text = indexFile.readText()
            Log.d(TAG, "readPacksIndex: ${text.length} chars")
            JSONArray(text)
        } catch (e: Exception) {
            Log.e(TAG, "readPacksIndex: failed to parse", e)
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
        Log.d(TAG, "queryAllPacks: returned ${cursor.count} packs")
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
        Log.d(TAG, "querySinglePack: identifier=$identifier, found=${cursor.count > 0}")
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
                Log.d(TAG, "queryStickers: identifier=$identifier, count=${stickers.length()}")
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
        Log.d(TAG, "addPackRow: identifier=$identifier, trayIconFile=$trayIconFile")
    }

    private fun resolveAsset(packId: String, fileName: String): AssetInfo {
        val trayFile = File(filesDir, "tray_icons/$packId.png")
        if (trayFile.exists() && fileName == "$packId.png") {
            val length = trayFile.length()
            val dims = readPngDims(trayFile)
            Log.d(TAG, "resolveAsset TRAY: path=${trayFile.absolutePath}, size=$length, dims=${dims?.first}x${dims?.second}")
            if (dims != null && dims != Pair(96, 96)) {
                Log.w(TAG, "resolveAsset TRAY: dims=${dims.first}x${dims.second} != expected 96x96")
            }
            if (length > 50 * 1024) {
                Log.w(TAG, "resolveAsset TRAY: size=$length exceeds 50KB limit")
            }
            return AssetInfo(
                pfd = ParcelFileDescriptor.open(trayFile, ParcelFileDescriptor.MODE_READ_ONLY),
                length = length,
                mimeType = "image/png",
            )
        }

        val stickerFile = File(filesDir, "pack_stickers/$packId/$fileName")
        val exists = stickerFile.exists()
        if (!exists) {
            val dir = File(filesDir, "pack_stickers/$packId")
            if (dir.exists()) {
                Log.d(TAG, "resolveAsset STICKER: dir contents=${dir.listFiles()?.map { it.name }}")
            } else {
                Log.d(TAG, "resolveAsset STICKER: dir ${dir.absolutePath} does not exist")
            }
            throw FileNotFoundException("File not cached: $fileName (packId=$packId)")
        }
        val length = stickerFile.length()
        val dims = readWebPDims(stickerFile)
        Log.d(TAG, "resolveAsset STICKER: path=${stickerFile.absolutePath}, size=$length, dims=${dims?.first}x${dims?.second}")
        if (dims != null && dims != Pair(512, 512)) {
            Log.w(TAG, "resolveAsset STICKER: dims=${dims.first}x${dims.second} != expected 512x512")
        }
        if (length > 100 * 1024) {
            Log.w(TAG, "resolveAsset STICKER: size=$length exceeds 100KB limit")
        }
        return AssetInfo(
            pfd = ParcelFileDescriptor.open(stickerFile, ParcelFileDescriptor.MODE_READ_ONLY),
            length = length,
            mimeType = "image/webp",
        )
    }

    private fun readPngDims(file: File): Pair<Int, Int>? {
        return try {
            file.inputStream().use { stream ->
                val header = ByteArray(24)
                stream.read(header)
                parsePngDimensions(header)
            }
        } catch (e: Exception) { null }
    }

    private fun readWebPDims(file: File): Pair<Int, Int>? {
        return try {
            file.inputStream().use { stream ->
                val header = ByteArray(30)
                stream.read(header)
                parseWebPDimensions(header)
            }
        } catch (e: Exception) { null }
    }

    private fun parsePngDimensions(bytes: ByteArray): Pair<Int, Int>? {
        if (bytes.size < 24) return null
        if (bytes[0] != 0x89.toByte() || bytes[1] != 'P'.code.toByte() ||
            bytes[2] != 'N'.code.toByte() || bytes[3] != 'G'.code.toByte()) return null
        val w = (bytes[16].toInt() and 0xff shl 24) or
                (bytes[17].toInt() and 0xff shl 16) or
                (bytes[18].toInt() and 0xff shl 8) or
                (bytes[19].toInt() and 0xff)
        val h = (bytes[20].toInt() and 0xff shl 24) or
                (bytes[21].toInt() and 0xff shl 16) or
                (bytes[22].toInt() and 0xff shl 8) or
                (bytes[23].toInt() and 0xff)
        return Pair(w, h)
    }

    private fun parseWebPDimensions(bytes: ByteArray): Pair<Int, Int>? {
        if (bytes.size < 30) return null
        if (bytes[0] != 'R'.code.toByte() || bytes[1] != 'I'.code.toByte() ||
            bytes[2] != 'F'.code.toByte() || bytes[3] != 'F'.code.toByte()) return null
        if (bytes[8] != 'W'.code.toByte() || bytes[9] != 'E'.code.toByte() ||
            bytes[10] != 'B'.code.toByte() || bytes[11] != 'P'.code.toByte()) return null

        val chunk = String(bytes, 12, 4)
        return when (chunk) {
            "VP8X" -> {
                val w = (bytes[24].toInt() and 0xff) or
                        ((bytes[25].toInt() and 0xff) shl 8) or
                        ((bytes[26].toInt() and 0xff) shl 16)
                val h = (bytes[27].toInt() and 0xff) or
                        ((bytes[28].toInt() and 0xff) shl 8) or
                        ((bytes[29].toInt() and 0xff) shl 16)
                Pair(w + 1, h + 1)
            }
            "VP8L" -> {
                if (bytes.size < 27) return null
                val bits0 = bytes[21].toInt() and 0xff
                val bits1 = bytes[22].toInt() and 0xff
                val bits2 = bytes[23].toInt() and 0xff
                val w = bits0 or (bits1 shl 8) or ((bits2 and 0x3f) shl 16)
                val bits3 = bytes[24].toInt() and 0xff
                val bits4 = bytes[25].toInt() and 0xff
                val bits5 = bytes[26].toInt() and 0xff
                val h = bits3 or (bits4 shl 8) or ((bits5 and 0x3f) shl 16)
                Pair(w + 1, h + 1)
            }
            "VP8 " -> null
            else -> null
        }
    }
}
