package com.meshcore.team.mesh

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class MeshBleNotificationDismissReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        Log.i("MeshBleNotif", "notification dismissed -> restart foreground")

        // Best-effort: re-assert the foreground service. On Android O+, use startForegroundService.
        val startIntent = Intent(context, MeshBleService::class.java)
            .setAction("com.meshcore.team.mesh.START")

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(startIntent)
            } else {
                context.startService(startIntent)
            }
        } catch (t: Throwable) {
            Log.e("MeshBleNotif", "failed to restart service", t)
        }
    }
}
