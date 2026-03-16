package com.meshcore.team.mesh

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel

object MeshBleEventBus {
    @Volatile
    private var sink: EventChannel.EventSink? = null

    private val mainHandler = Handler(Looper.getMainLooper())
    private const val tag = "MeshBleEventBus"

    fun setSink(eventSink: EventChannel.EventSink) {
        sink = eventSink
    }

    fun clearSink() {
        sink = null
    }

    fun send(event: Map<String, Any?>) {
        val currentSink = sink ?: return
        val deliver = Runnable {
            try {
                currentSink.success(event)
            } catch (t: Throwable) {
                Log.e(tag, "Failed to deliver event", t)
            }
        }

        if (Looper.myLooper() == Looper.getMainLooper()) {
            deliver.run()
        } else {
            mainHandler.post(deliver)
        }
    }
}
