package app.truetun.vpn

import android.os.Handler
import android.os.Looper
import java.util.concurrent.CopyOnWriteArraySet

object TrueTunRuntime {
    enum class State(val wireName: String) {
        STOPPED("stopped"),
        STARTING("starting"),
        RUNNING("running"),
        STOPPING("stopping"),
        FAILED("failed"),
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val listeners = CopyOnWriteArraySet<(Map<String, Any?>) -> Unit>()

    @Volatile
    var state: State = State.STOPPED
        private set

    @Volatile
    var lastError: String? = null
        private set

    @Volatile
    var upload: Long = 0
        private set

    @Volatile
    var download: Long = 0
        private set

    @Volatile
    var uploadPerSecond: Long = 0
        private set

    @Volatile
    var downloadPerSecond: Long = 0
        private set

    fun addListener(listener: (Map<String, Any?>) -> Unit) {
        listeners.add(listener)
    }

    fun removeListener(listener: (Map<String, Any?>) -> Unit) {
        listeners.remove(listener)
    }

    @Synchronized
    fun setState(value: State, error: String? = null) {
        state = value
        lastError = error
        emit(
            mapOf(
                "type" to "state",
                "state" to value.wireName,
                "error" to error,
            ),
        )
    }

    fun fail(message: String) {
        setState(State.FAILED, message)
        emit(mapOf("type" to "failure", "message" to message))
    }

    fun log(message: String, isError: Boolean = false) {
        emit(
            mapOf(
                "type" to "log",
                "message" to message,
                "isError" to isError,
            ),
        )
    }

    @Synchronized
    fun traffic(
        uploadTotal: Long,
        downloadTotal: Long,
        uploadRate: Long,
        downloadRate: Long,
    ) {
        upload = uploadTotal.coerceAtLeast(0)
        download = downloadTotal.coerceAtLeast(0)
        uploadPerSecond = uploadRate.coerceAtLeast(0)
        downloadPerSecond = downloadRate.coerceAtLeast(0)
        emit(
            mapOf(
                "type" to "traffic",
                "upload" to upload,
                "download" to download,
                "uploadPerSecond" to uploadPerSecond,
                "downloadPerSecond" to downloadPerSecond,
            ),
        )
    }

    fun snapshot(): Map<String, Any?> =
        mapOf(
            "state" to state.wireName,
            "error" to lastError,
            "upload" to upload,
            "download" to download,
            "uploadPerSecond" to uploadPerSecond,
            "downloadPerSecond" to downloadPerSecond,
        )

    private fun emit(event: Map<String, Any?>) {
        for (listener in listeners) {
            mainHandler.post { listener(event) }
        }
    }
}
