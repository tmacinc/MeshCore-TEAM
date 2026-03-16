package com.meshcore.team.mesh

import android.util.Log

object MeshBleState {
    @Volatile var state: String = "disconnected" // disconnected|scanning|connecting|connected|disconnecting|error
    @Volatile var deviceName: String? = null
    @Volatile var deviceAddress: String? = null
    @Volatile var errorMessage: String? = null

    private const val tag = "MeshBleState"

    fun snapshot(): Map<String, Any?> {
        return mapOf(
            "state" to state,
            "deviceName" to deviceName,
            "deviceAddress" to deviceAddress,
            "errorMessage" to errorMessage,
        )
    }

    fun eventStatus(): Map<String, Any?> {
        return mapOf(
            "type" to "status",
            "status" to snapshot(),
        )
    }

    fun setState(newState: String, error: String? = null) {
        Log.i(tag, "state=$newState addr=${deviceAddress ?: "-"} name=${deviceName ?: "-"} err=${error ?: "-"}")
        state = newState
        errorMessage = error
        MeshBleEventBus.send(eventStatus())
    }
}
