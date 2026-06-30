package com.alamaby.bikin_stiker

import android.content.ContentProvider
import android.content.ContentValues
import android.content.UriMatcher
import android.database.Cursor
import android.database.MatrixCursor
import android.content.res.AssetFileDescriptor
import android.net.Uri
import android.os.ParcelFileDescriptor
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileNotFoundException

/**
 * ContentProvider that serves sticker pack metadata and sticker assets
 * to WhatsApp via the com.whatsapp.sticker.READ permission.
 *
 * Authority: ${applicationId}.stickercontentprovider
 *
 * Supported URI paths:
 *   /metadata                                    -> all packs (cursor)
 *   /metadata/{pack_identifier}                  -> single pack (cursor)
 *   /stickers/{pack_identifier}/{sticker_file}   -> sticker WebP bytes (openable)
 *   /sticker_asset/{pack_identifier}/{sticker_file} -> alias for above
 *   /sticker_tray/{pack_identifier}              -> tray icon PNG bytes (openable)
 */
class StickerContentProvider : ContentProvider() {

    companion object {
        private const val METADATA = 1
        private const val METADATA_SINGLE = 2
        private const val STICKER_ASSET = 3
        private const val STICKER_TRAY = 4

        private val COLUMNS = arrayOf(
            "sticker_pack_identifier",
            "sticker_pack_name",
            "sticker_pack_publisher",
            "sticker_pack_icon",
            "android_play_store_link",
            "ios_app_store_link",
            "animated_sticker_pack",
        )
    }

    private lateinit var authority: String
    private lateinit var filesDir: File

    private val uriMatcher by lazy {
        val matcher = UriMatcher(UriMatcher.NO_MATCH)
        matcher.addURI(authority, "metadata", METADATA)
        matcher.addURI(authority, "metadata/*", METADATA_SINGLE)
        matcher.addURI(authority, "stickers/*/*", STICKER_ASSET)
        matcher.addURI(authority, "sticker_asset/*/*", STICKER_ASSET)
        matcher.addURI(authority, "sticker_tray/*", STICKER_TRAY)
        matcher
    }

    override fun onCreate(): Boolean {
        context?.let {
            authority = it.applicationContext.packageName + ".stickercontentprovider"
            filesDir = it.filesDir
        } ?: return false
        return true
    }

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?,
    ): Cursor? {
        return when (uriMatcher.match(uri)) {
            METADATA -> queryAllPacks()
            METADATA_SINGLE -> {
                val identifier = uri.lastPathSegment ?: return null
                querySinglePack(identifier)
            }
            else -> null
        }
    }

    override fun getType(uri: Uri): String? {
        return when (uriMatcher.match(uri)) {
            METADATA, METADATA_SINGLE -> "vnd.android.cursor.dir/vnd.$authority.sticker_pack"
            STICKER_ASSET -> "image/webp"
            STICKER_TRAY -> "image/png"
            else -> null
        }
    }

    override fun openAssetFile(uri: Uri, mode: String): AssetFileDescriptor? {
        val pfd = when (uriMatcher.match(uri)) {
            STICKER_ASSET -> {
                val segments = uri.pathSegments
                if (segments.size < 3) throw FileNotFoundException("Invalid sticker URI: $uri")
                val packId = segments[1]
                val fileName = segments[2]
                openStickerFile(packId, fileName)
            }
            STICKER_TRAY -> {
                val packId = uri.lastPathSegment ?: throw FileNotFoundException("Invalid tray URI: $uri")
                openTrayFile(packId)
            }
            else -> throw FileNotFoundException("Unknown URI: $uri")
        }
        return AssetFileDescriptor(pfd, 0, AssetFileDescriptor.UNKNOWN_LENGTH)
    }

    // --- Not used for read-only provider ---

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?) = 0
    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?) = 0

    // --- Private helpers ---

    private fun readPacksIndex(): JSONArray {
        val indexFile = File(filesDir, "packs_index.json")
        if (!indexFile.exists()) return JSONArray()
        return try {
            JSONArray(indexFile.readText())
        } catch (_: Exception) {
            JSONArray()
        }
    }

    private fun queryAllPacks(): Cursor {
        val cursor = MatrixCursor(COLUMNS)
        val packs = readPacksIndex()
        for (i in 0 until packs.length()) {
            val pack = packs.getJSONObject(i)
            addPackRow(cursor, pack)
        }
        return cursor
    }

    private fun querySinglePack(identifier: String): Cursor {
        val cursor = MatrixCursor(COLUMNS)
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

    private fun addPackRow(cursor: MatrixCursor, pack: JSONObject) {
        val identifier = pack.optString("identifier", "")
        val trayIconUri = "content://$authority/sticker_tray/$identifier"
        cursor.addRow(arrayOf(
            identifier,
            pack.optString("name", ""),
            pack.optString("publisher", "BikinStiker"),
            trayIconUri,
            pack.optString("android_play_store_link",
                "https://play.google.com/store/apps/details?id=com.alamaby.bikin_stiker"),
            pack.optString("ios_app_store_link", ""),
            if (pack.optBoolean("animated_sticker_pack", false)) 1 else 0,
        ))
    }

    private fun openStickerFile(packId: String, fileName: String): ParcelFileDescriptor {
        val file = File(filesDir, "pack_stickers/$packId/$fileName")
        if (!file.exists()) throw FileNotFoundException("Sticker not cached: $fileName")
        return ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
    }

    private fun openTrayFile(packId: String): ParcelFileDescriptor {
        val file = File(filesDir, "tray_icons/$packId.png")
        if (!file.exists()) throw FileNotFoundException("Tray icon not cached for pack: $packId")
        return ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
    }
}
