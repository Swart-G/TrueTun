package app.truetun.vpn

import android.content.Context
import java.io.File

object TrueTunConfigStore {
    private const val PREFS = "truetun_vpn_runtime"
    private const val KEY_STARTED = "started"
    private const val KEY_PROFILE_NAME = "profile_name"
    private const val FILE_NAME = "active-sing-box.json"

    fun save(context: Context, configJson: String, profileName: String?) {
        val target = File(context.noBackupFilesDir, FILE_NAME)
        val temporary = File(context.noBackupFilesDir, "$FILE_NAME.tmp")
        temporary.writeText(configJson)
        if (!temporary.renameTo(target)) {
            temporary.copyTo(target, overwrite = true)
            temporary.delete()
        }
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_PROFILE_NAME, profileName.orEmpty())
            .apply()
    }

    fun readConfig(context: Context): String? {
        val file = File(context.noBackupFilesDir, FILE_NAME)
        if (!file.isFile) return null
        return file.readText().takeIf { it.isNotBlank() }
    }

    fun profileName(context: Context): String =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_PROFILE_NAME, null)
            ?.takeIf { it.isNotBlank() }
            ?: "TrueTun"

    fun markStarted(context: Context, value: Boolean) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_STARTED, value)
            .apply()
    }

    fun wasStarted(context: Context): Boolean =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getBoolean(KEY_STARTED, false)
}
