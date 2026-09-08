package app.truetun.vpn

import android.content.Context
import android.os.Build
import app.truetun.BuildConfig
import io.nekohasekai.libbox.Libbox
import io.nekohasekai.libbox.SetupOptions
import org.json.JSONObject
import java.util.Locale

object LibboxRuntime {
    @Volatile
    private var initialized = false

    @Synchronized
    fun ensureInitialized(context: Context) {
        if (initialized) return

        val appContext = context.applicationContext
        val baseDir = appContext.filesDir.apply { mkdirs() }
        val workingDir = (appContext.getExternalFilesDir(null) ?: baseDir).apply { mkdirs() }
        val tempDir = appContext.cacheDir.apply { mkdirs() }

        runCatching {
            Libbox.setLocale(Locale.getDefault().toLanguageTag())
        }

        val options = SetupOptions().also {
            it.basePath = baseDir.path
            it.workingPath = workingDir.path
            it.tempPath = tempDir.path
            it.logMaxLines = 2000
            it.debug = BuildConfig.DEBUG
            it.crashReportSource = "TrueTun"
            it.appVersion = BuildConfig.VERSION_CODE.toString()
            it.appMarketingVersion = BuildConfig.VERSION_NAME
            it.platformMetadata = JSONObject()
                .put("os", "Android ${Build.VERSION.RELEASE}")
                .put("sdk", Build.VERSION.SDK_INT)
                .put("manufacturer", Build.MANUFACTURER)
                .put("model", Build.MODEL)
                .toString()
        }
        Libbox.setup(options)
        initialized = true
    }

    fun version(context: Context): String {
        ensureInitialized(context)
        return Libbox.version()
    }
}
