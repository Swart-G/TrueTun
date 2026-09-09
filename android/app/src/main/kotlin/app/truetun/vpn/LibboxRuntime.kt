package app.truetun.vpn

import android.content.Context
import app.truetun.BuildConfig
import io.nekohasekai.libbox.Libbox
import io.nekohasekai.libbox.SetupOptions
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
        }
        Libbox.setup(options)
        initialized = true
    }

    fun version(context: Context): String {
        ensureInitialized(context)
        return Libbox.version()
    }
}
