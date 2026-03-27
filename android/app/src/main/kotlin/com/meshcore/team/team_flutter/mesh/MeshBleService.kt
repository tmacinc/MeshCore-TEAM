package com.meshcore.team.mesh

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothProfile
import android.bluetooth.BluetoothStatusCodes
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.content.pm.ServiceInfo
import android.content.pm.PackageManager
import android.location.Location
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.ParcelUuid
import android.util.Log
import android.util.Base64
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.core.app.ServiceCompat
import com.meshcore.team.MainActivity
import com.meshcore.team.R
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.ArrayDeque
import java.util.UUID
import kotlin.math.min

class MeshBleService : Service() {

    private val telemetryDebugLogsEnabled: Boolean by lazy {
        (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
    }

    private fun logI(message: String, extra: Map<String, Any?> = emptyMap()) {
        Log.i("MeshBleService", message)
        MeshBleEventBus.send(
            mapOf(
                "type" to "log",
                "level" to "I",
                "msg" to message,
                "extra" to extra,
                "ts" to System.currentTimeMillis(),
            )
        )
    }

    private fun logW(message: String, extra: Map<String, Any?> = emptyMap()) {
        Log.w("MeshBleService", message)
        MeshBleEventBus.send(
            mapOf(
                "type" to "log",
                "level" to "W",
                "msg" to message,
                "extra" to extra,
                "ts" to System.currentTimeMillis(),
            )
        )
    }

    private fun logE(message: String, extra: Map<String, Any?> = emptyMap()) {
        Log.e("MeshBleService", message)
        MeshBleEventBus.send(
            mapOf(
                "type" to "log",
                "level" to "E",
                "msg" to message,
                "extra" to extra,
                "ts" to System.currentTimeMillis(),
            )
        )
    }

    private fun telemetryLogI(message: String, extra: Map<String, Any?> = emptyMap()) {
        if (!telemetryDebugLogsEnabled) return
        logI(message, extra)
    }

    private fun telemetryLogW(message: String, extra: Map<String, Any?> = emptyMap()) {
        if (!telemetryDebugLogsEnabled) return
        logW(message, extra)
    }

    private fun frameToHex(frame: ByteArray): String {
        return frame.joinToString(" ") { String.format("%02X", it) }
    }

    companion object {
        private const val channelId = "mesh_ble_channel"
        private const val notificationId = 1001

        // Pairing / bonding can require user interaction and can easily exceed 30s.
        // Keep this generous to avoid tearing down the GATT during pairing prompts.
        private const val CONNECT_TIMEOUT_MS: Long = 120_000L

        // If we detect an active bonding flow, defer the timeout instead of erroring out.
        private const val CONNECT_TIMEOUT_BONDING_DEFER_MS: Long = 30_000L

        private const val prefsName = "mesh_ble"
        private const val keyLastAddress = "last_address"
        private const val keyAutoReconnect = "auto_reconnect"

        private const val actionStartService = "com.meshcore.team.mesh.START"
        private const val actionStopService = "com.meshcore.team.mesh.STOP"
        private const val actionUserStop = "com.meshcore.team.mesh.USER_STOP"
        private const val actionStartScan = "com.meshcore.team.mesh.SCAN_START"
        private const val actionStopScan = "com.meshcore.team.mesh.SCAN_STOP"
        private const val actionConnect = "com.meshcore.team.mesh.CONNECT"
        private const val actionDisconnect = "com.meshcore.team.mesh.DISCONNECT"
        private const val actionSendFrame = "com.meshcore.team.mesh.SEND_FRAME"
        private const val actionConfigureNativeTelemetry = "com.meshcore.team.mesh.CONFIGURE_NATIVE_TELEMETRY"
        private const val actionStopNativeTelemetry = "com.meshcore.team.mesh.STOP_NATIVE_TELEMETRY"
        private const val actionUpdateCompanionLocation = "com.meshcore.team.mesh.UPDATE_COMPANION_LOCATION"

        private const val extraTimeoutMs = "timeoutMs"
        private const val extraAddress = "address"
        private const val extraData = "data"
        private const val extraTelemetryEnabled = "telemetryEnabled"
        private const val extraTelemetryChannelIndex = "telemetryChannelIndex"
        private const val extraTelemetryIntervalSeconds = "telemetryIntervalSeconds"
        private const val extraTelemetryMinDistanceMeters = "telemetryMinDistanceMeters"
        private const val extraTelemetryCompanionBatteryMilliVolts = "telemetryCompanionBatteryMilliVolts"
        private const val extraTelemetryNeedsForwarding = "telemetryNeedsForwarding"
        private const val extraTelemetryMaxPathObserved = "telemetryMaxPathObserved"
        private const val extraTelemetryLocationSource = "telemetryLocationSource"
        private const val extraTelemetryStrategyMode = "telemetryStrategyMode"
        private const val extraTelemetryNeighborBitmap = "telemetryNeighborBitmap"
        private const val extraTelemetryNodeCount = "telemetryNodeCount"
        private const val extraCompanionLatitude = "companionLatitude"
        private const val extraCompanionLongitude = "companionLongitude"

        private val nusServiceUuid: UUID = UUID.fromString("6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
        private val rxCharUuid: UUID = UUID.fromString("6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
        private val txCharUuid: UUID = UUID.fromString("6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
        private val cccdUuid: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")

        fun startService(context: Context) {
            val intent = Intent(context, MeshBleService::class.java).setAction(actionStartService)
            // Start as a normal service. We'll only promote to foreground (persistent
            // notification) once a device is actually connected.
            context.startService(intent)
        }

        fun stopService(context: Context) {
            val intent = Intent(context, MeshBleService::class.java).setAction(actionStopService)
            context.startService(intent)
        }

        fun userStop(context: Context) {
            val intent = Intent(context, MeshBleService::class.java).setAction(actionUserStop)
            context.startService(intent)
        }

        fun startScan(context: Context, timeoutMs: Long) {
            val intent = Intent(context, MeshBleService::class.java)
                .setAction(actionStartScan)
                .putExtra(extraTimeoutMs, timeoutMs)
            // Scanning should not start a foreground service / persistent notification.
            context.startService(intent)
        }

        fun stopScan(context: Context) {
            val intent = Intent(context, MeshBleService::class.java).setAction(actionStopScan)
            context.startService(intent)
        }

        fun connect(context: Context, address: String) {
            val intent = Intent(context, MeshBleService::class.java)
                .setAction(actionConnect)
                .putExtra(extraAddress, address)
            // Connecting should not start the persistent notification. We'll promote to
            // foreground only after the connection is fully established.
            context.startService(intent)
        }

        fun disconnect(context: Context) {
            val intent = Intent(context, MeshBleService::class.java).setAction(actionDisconnect)
            context.startService(intent)
        }

        fun sendFrame(context: Context, data: ByteArray) {
            val intent = Intent(context, MeshBleService::class.java)
                .setAction(actionSendFrame)
                .putExtra(extraData, data)
            context.startService(intent)
        }

        fun configureNativeTelemetry(
            context: Context,
            enabled: Boolean,
            channelIndex: Int,
            intervalSeconds: Int,
            minDistanceMeters: Int,
            companionBatteryMilliVolts: Int?,
            needsForwarding: Boolean,
            maxPathObserved: Int,
            locationSource: String,
            strategyMode: String,
            neighborBitmap: ByteArray?,
            nodeCount: Int,
        ) {
            val intent = Intent(context, MeshBleService::class.java)
                .setAction(actionConfigureNativeTelemetry)
                .putExtra(extraTelemetryEnabled, enabled)
                .putExtra(extraTelemetryChannelIndex, channelIndex)
                .putExtra(extraTelemetryIntervalSeconds, intervalSeconds)
                .putExtra(extraTelemetryMinDistanceMeters, minDistanceMeters)
                .putExtra(extraTelemetryNeedsForwarding, needsForwarding)
                .putExtra(extraTelemetryMaxPathObserved, maxPathObserved)
                .putExtra(extraTelemetryLocationSource, locationSource)
                .putExtra(extraTelemetryStrategyMode, strategyMode)
                .putExtra(extraTelemetryNodeCount, nodeCount)
            if (companionBatteryMilliVolts != null) {
                intent.putExtra(extraTelemetryCompanionBatteryMilliVolts, companionBatteryMilliVolts)
            }
            if (neighborBitmap != null) {
                intent.putExtra(extraTelemetryNeighborBitmap, neighborBitmap)
            }
            context.startService(intent)
        }

        fun updateCompanionLocation(context: Context, latitude: Double, longitude: Double) {
            val intent = Intent(context, MeshBleService::class.java)
                .setAction(actionUpdateCompanionLocation)
                .putExtra(extraCompanionLatitude, latitude)
                .putExtra(extraCompanionLongitude, longitude)
            context.startService(intent)
        }

        fun stopNativeTelemetry(context: Context) {
            val intent = Intent(context, MeshBleService::class.java)
                .setAction(actionStopNativeTelemetry)
            context.startService(intent)
        }

        private fun startForegroundCompat(context: Context, intent: Intent) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }

    private val mainHandler = Handler(Looper.getMainLooper())

    private var notificationTickRunnable: Runnable? = null
    private var lastNotificationText: String? = null
    private var lastNotificationPresent: Boolean? = null

    // Only run as a foreground service (persistent notification) once connected.
    private var isForegroundActive: Boolean = false

    private var pendingReconnectRunnable: Runnable? = null

    private fun cancelConnectionTimeout(reason: String) {
        connectionTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
        connectionTimeoutRunnable = null
        logI("connection timeout cancelled", mapOf("reason" to reason))
    }

    private fun resetConnectionTimeout(reason: String) {
        // Always cancel any prior runnable to avoid multiple timers.
        connectionTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }

        val address = targetAddress
        connectionTimeoutRunnable = Runnable {
            if (MeshBleState.state != "connecting") return@Runnable

            val bondState = try {
                if (address.isNullOrBlank()) {
                    null
                } else {
                    bluetoothAdapter?.getRemoteDevice(address)?.bondState
                }
            } catch (_: Throwable) {
                null
            }

            if (bondState == BluetoothDevice.BOND_BONDING) {
                logW(
                    "connection timeout deferred (bonding)",
                    mapOf("address" to (address ?: ""), "deferMs" to CONNECT_TIMEOUT_BONDING_DEFER_MS)
                )
                mainHandler.postDelayed(connectionTimeoutRunnable!!, CONNECT_TIMEOUT_BONDING_DEFER_MS)
                return@Runnable
            }

            logE(
                "connection timeout fired",
                mapOf(
                    "address" to (address ?: ""),
                    "hadGatt" to (gatt != null),
                    "bond" to (bondState ?: -1),
                )
            )
            MeshBleState.setState("error", "Connection timeout")
            disconnectInternal(manual = false)
            scheduleReconnect()
        }

        mainHandler.postDelayed(connectionTimeoutRunnable!!, CONNECT_TIMEOUT_MS)
        logI(
            "connection timeout armed",
            mapOf("reason" to reason, "timeoutMs" to CONNECT_TIMEOUT_MS, "address" to (address ?: ""))
        )
    }

    private var shouldRestartOnTaskRemoved: Boolean = true

    private var bluetoothAdapter: BluetoothAdapter? = null
    private var scanner: BluetoothLeScanner? = null
    private var isScanning: Boolean = false
    private var scanStopRunnable: Runnable? = null

    private var gatt: BluetoothGatt? = null
    private var rxChar: BluetoothGattCharacteristic? = null
    private var txChar: BluetoothGattCharacteristic? = null

    private val writeQueue: ArrayDeque<ByteArray> = ArrayDeque()
    private var writeInFlight: Boolean = false
    private var writeWatchdogRunnable: Runnable? = null
    private var inFlightFrame: ByteArray? = null

    private var targetAddress: String? = null
    private var autoReconnect: Boolean = false
    private var reconnectAttempt: Int = 0
    private var connectionTimeoutRunnable: Runnable? = null

    private val cmdSendChannelTxtMsg = 3
    private val telemetryPrefix = "#TEL:"
    private val topologyPrefix = "#T:"
    private val telemetryPayloadSize = 11

    private val nativeTelemetryTickMs = 5000L
    private val minTelemetrySendIntervalMs = 15_000L
    private val maxTelemetryLocationAgeMs = 20_000L
    private val nativeTelemetryWarnThrottleMs = 60_000L

    private var nativeTelemetryEnabled = false
    private var nativeTelemetryChannelIndex = 0
    private var nativeTelemetryIntervalSeconds = 60
    private var nativeTelemetryMinDistanceMeters = 100
    private var nativeTelemetryCompanionBatteryMilliVolts: Int? = null
    private var nativeTelemetryLocationSource = "phone"
    private var nativeTelemetryCompanionLat: Double? = null
    private var nativeTelemetryCompanionLon: Double? = null
    private var nativeTelemetryCompanionLocationAtMs = 0L
    private var nativeTelemetryNeedsForwarding = false
    private var nativeTelemetryMaxPathObserved = 0
    private var nativeTelemetryStrategyMode = "forwardingV1"
    private var nativeTelemetryNeighborBitmap: ByteArray? = null
    private var nativeTelemetryNodeCount = 0
    private var nativeTelemetryLastSendMs = 0L
    private var nativeTelemetryNextPeriodicDueMs = 0L
    private var nativeTelemetryLastSentLocation: Location? = null
    private var nativeTelemetryLatestLocation: Location? = null
    private var nativeTelemetryLatestLocationAtMs = 0L
    private var nativeTelemetryNoFixWarnAtMs = 0L
    private var nativeTelemetryStaleWarnAtMs = 0L
    private var nativeTelemetryRunnable: Runnable? = null
    private var nativeTelemetryLocationCallback: LocationCallback? = null

    private lateinit var fusedLocationClient: FusedLocationProviderClient

    override fun onCreate() {
        super.onCreate()
        logI("onCreate", mapOf("sdk" to Build.VERSION.SDK_INT))
        bluetoothAdapter = (getSystemService(BLUETOOTH_SERVICE) as android.bluetooth.BluetoothManager).adapter
        scanner = bluetoothAdapter?.bluetoothLeScanner
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)

        logI(
            "adapter/scanner init",
            mapOf(
                "adapter" to (bluetoothAdapter != null),
                "scanner" to (scanner != null),
                "isEnabled" to (bluetoothAdapter?.isEnabled ?: false),
            )
        )

        ensureNotificationChannel()

        // Attempt restore
        val prefs = getSharedPreferences(prefsName, MODE_PRIVATE)
        autoReconnect = prefs.getBoolean(keyAutoReconnect, false)
        targetAddress = prefs.getString(keyLastAddress, null)
        logI(
            "restore prefs",
            mapOf("autoReconnect" to autoReconnect, "targetAddress" to (targetAddress ?: ""))
        )
        if (autoReconnect && !targetAddress.isNullOrBlank()) {
            logI("auto-restore connect", mapOf("address" to targetAddress))
            connectInternal(targetAddress!!, fromRestore = true)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Defensive: if we are foreground-active, keep the notification present even
        // if an OEM skin allows the user to swipe it away.
        if (isForegroundActive) {
            refreshForegroundNotification(force = false)
        }

        logI(
            "onStartCommand",
            mapOf(
                "action" to (intent?.action ?: "null"),
                "hasAddress" to (intent?.hasExtra(extraAddress) ?: false),
                "hasData" to (intent?.hasExtra(extraData) ?: false),
            )
        )
        when (intent?.action) {
            actionStartService -> {
                logI("actionStartService")
                MeshBleState.setState(MeshBleState.state)

                // Only promote to foreground once we have an actual BLE connection.
                if (MeshBleState.state == "connected") {
                    ensureForegroundActive(reason = "actionStartService")
                } else {
                    logI(
                        "actionStartService: not promoting to foreground",
                        mapOf("state" to MeshBleState.state)
                    )
                }
            }
            actionStopService -> {
                logI("actionStopService")

                // If the app asked us to stop, don't restart on task removal.
                shouldRestartOnTaskRemoved = false

                // Also disable auto-reconnect persistence to avoid resurrecting the
                // foreground notification after an explicit stop.
                val prefs = getSharedPreferences(prefsName, MODE_PRIVATE)
                prefs.edit().putBoolean(keyAutoReconnect, false).apply()
                autoReconnect = false
                reconnectAttempt = 0
                cancelPendingReconnect(reason = "actionStopService")

                stopScanInternal(emitDisconnected = true)
                disconnectInternal(manual = true)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                } else {
                    @Suppress("DEPRECATION")
                    stopForeground(true)
                }
                deactivateForeground(reason = "actionStopService")
                stopSelf()
            }
            actionUserStop -> {
                logI("actionUserStop")

                // Disable reconnect now and across restarts
                val prefs = getSharedPreferences(prefsName, MODE_PRIVATE)
                prefs.edit().putBoolean(keyAutoReconnect, false).remove(keyLastAddress).apply()
                autoReconnect = false
                targetAddress = null
                reconnectAttempt = 0
                cancelPendingReconnect(reason = "userStop")

                // If the user explicitly stopped, don't restart service on task removal.
                shouldRestartOnTaskRemoved = false

                stopScanInternal(emitDisconnected = true)
                disconnectInternal(manual = true)

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                } else {
                    @Suppress("DEPRECATION")
                    stopForeground(true)
                }
                deactivateForeground(reason = "actionUserStop")
                stopSelf()
            }
            actionStartScan -> {
                val timeout = intent.getLongExtra(extraTimeoutMs, 10_000L)
                logI("actionStartScan", mapOf("timeoutMs" to timeout))
                startScanInternal(timeout)
            }
            actionStopScan -> {
                logI("actionStopScan")
                stopScanInternal(emitDisconnected = true)
            }
            actionConnect -> {
                val address = intent.getStringExtra(extraAddress)
                logI("actionConnect", mapOf("address" to (address ?: "")))
                if (!address.isNullOrBlank()) {
                    connectInternal(address, fromRestore = false)
                }
            }
            actionDisconnect -> {
                logI("actionDisconnect")
                // Treat explicit disconnect as manual: disable auto-reconnect
                val prefs = getSharedPreferences(prefsName, MODE_PRIVATE)
                prefs.edit().putBoolean(keyAutoReconnect, false).apply()
                autoReconnect = false
                reconnectAttempt = 0
                cancelPendingReconnect(reason = "actionDisconnect")
                disconnectInternal(manual = true)

                // If the app explicitly disconnected, we should not keep the foreground
                // service (and its persistent notification) running.
                shouldRestartOnTaskRemoved = false
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                } else {
                    @Suppress("DEPRECATION")
                    stopForeground(true)
                }
                deactivateForeground(reason = "actionDisconnect")
                stopSelf()
            }
            actionSendFrame -> {
                val data = intent.getByteArrayExtra(extraData)
                logI("actionSendFrame", mapOf("len" to (data?.size ?: -1)))
                if (data != null) {
                    enqueueFrameInternal(data)
                }
            }
            actionConfigureNativeTelemetry -> {
                val previousEnabled = nativeTelemetryEnabled
                val previousChannelIndex = nativeTelemetryChannelIndex
                val previousIntervalSeconds = nativeTelemetryIntervalSeconds
                val previousMinDistanceMeters = nativeTelemetryMinDistanceMeters

                nativeTelemetryEnabled = intent.getBooleanExtra(extraTelemetryEnabled, false)
                nativeTelemetryChannelIndex = intent.getIntExtra(extraTelemetryChannelIndex, 0)
                nativeTelemetryIntervalSeconds = intent.getIntExtra(extraTelemetryIntervalSeconds, 60).coerceAtLeast(5)
                nativeTelemetryMinDistanceMeters = intent.getIntExtra(extraTelemetryMinDistanceMeters, 0).coerceAtLeast(0)
                nativeTelemetryCompanionBatteryMilliVolts =
                    if (intent.hasExtra(extraTelemetryCompanionBatteryMilliVolts)) {
                        intent.getIntExtra(extraTelemetryCompanionBatteryMilliVolts, 0)
                    } else {
                        null
                    }
                nativeTelemetryNeedsForwarding = intent.getBooleanExtra(extraTelemetryNeedsForwarding, false)
                nativeTelemetryMaxPathObserved = intent.getIntExtra(extraTelemetryMaxPathObserved, 0).coerceIn(0, 127)
                nativeTelemetryLocationSource = intent.getStringExtra(extraTelemetryLocationSource) ?: "phone"
                nativeTelemetryStrategyMode = intent.getStringExtra(extraTelemetryStrategyMode) ?: "forwardingV1"
                nativeTelemetryNodeCount = intent.getIntExtra(extraTelemetryNodeCount, 0).coerceIn(0, 255)
                nativeTelemetryNeighborBitmap = intent.getByteArrayExtra(extraTelemetryNeighborBitmap)

                val shouldResetSchedule = nativeTelemetryEnabled && (
                    !previousEnabled ||
                        previousChannelIndex != nativeTelemetryChannelIndex ||
                        previousIntervalSeconds != nativeTelemetryIntervalSeconds ||
                        previousMinDistanceMeters != nativeTelemetryMinDistanceMeters
                    )

                if (shouldResetSchedule) {
                    nativeTelemetryLastSendMs = 0L
                    nativeTelemetryNextPeriodicDueMs =
                        System.currentTimeMillis() + (nativeTelemetryIntervalSeconds * 1000L)
                    nativeTelemetryLastSentLocation = null
                }
                telemetryLogI(
                    "actionConfigureNativeTelemetry",
                    mapOf(
                        "enabled" to nativeTelemetryEnabled,
                        "channelIndex" to nativeTelemetryChannelIndex,
                        "intervalSeconds" to nativeTelemetryIntervalSeconds,
                        "minDistanceMeters" to nativeTelemetryMinDistanceMeters,
                        "companionBatteryMilliVolts" to nativeTelemetryCompanionBatteryMilliVolts,
                        "needsForwarding" to nativeTelemetryNeedsForwarding,
                        "maxPathObserved" to nativeTelemetryMaxPathObserved,
                        "locationSource" to nativeTelemetryLocationSource,
                        "strategyMode" to nativeTelemetryStrategyMode,
                        "nodeCount" to nativeTelemetryNodeCount,
                        "hasBitmap" to (nativeTelemetryNeighborBitmap != null),
                        "scheduleReset" to shouldResetSchedule,
                    )
                )
                refreshNativeTelemetryLoop(reason = "configure")
                if (isForegroundActive) {
                    refreshForegroundNotification(force = true)
                }
            }
            actionUpdateCompanionLocation -> {
                val lat = intent.getDoubleExtra(extraCompanionLatitude, Double.NaN)
                val lon = intent.getDoubleExtra(extraCompanionLongitude, Double.NaN)
                if (!lat.isNaN() && !lon.isNaN()) {
                    nativeTelemetryCompanionLat = lat
                    nativeTelemetryCompanionLon = lon
                    nativeTelemetryCompanionLocationAtMs = System.currentTimeMillis()
                    telemetryLogI("updateCompanionLocation", mapOf("lat" to lat, "lon" to lon))
                }
            }
            actionStopNativeTelemetry -> {
                nativeTelemetryEnabled = false
                telemetryLogI("actionStopNativeTelemetry")
                refreshNativeTelemetryLoop(reason = "stop")
                if (isForegroundActive) {
                    refreshForegroundNotification(force = true)
                }
            }
        }

        return START_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // Keep service alive when app task is removed only if we're actively running
        // as a foreground (connected) service.
        if (shouldRestartOnTaskRemoved && isForegroundActive) {
            logI("onTaskRemoved: keeping foreground service alive")
        } else {
            logI(
                "onTaskRemoved: stopping",
                mapOf(
                    "shouldRestart" to shouldRestartOnTaskRemoved,
                    "foreground" to isForegroundActive,
                )
            )
            stopSelf()
        }
        super.onTaskRemoved(rootIntent)
    }

    private fun cancelPendingReconnect(reason: String) {
        pendingReconnectRunnable?.let {
            mainHandler.removeCallbacks(it)
            pendingReconnectRunnable = null
            logI("cancelPendingReconnect", mapOf("reason" to reason))
        }
    }

    override fun onDestroy() {
        logI("onDestroy")
        stopNativeTelemetryLoop(reason = "onDestroy")
        stopNotificationTicker()
        isForegroundActive = false
        stopScanInternal(emitDisconnected = true)
        disconnectInternal(manual = true)
        super.onDestroy()
    }

    private fun ensureForegroundActive(reason: String) {
        if (isForegroundActive) return
        isForegroundActive = true
        logI("foreground active", mapOf("reason" to reason, "state" to MeshBleState.state))
        refreshForegroundNotification(force = true)
        startNotificationTicker()
    }

    private fun deactivateForeground(reason: String) {
        if (!isForegroundActive) return
        isForegroundActive = false
        logI("foreground inactive", mapOf("reason" to reason, "state" to MeshBleState.state))
        stopNotificationTicker()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startScanInternal(timeoutMs: Long) {
        if (isScanning) {
            logW("startScanInternal ignored (already scanning)")
            return
        }
        val scannerLocal = scanner ?: run {
            logE("startScanInternal failed: scanner null")
            MeshBleState.setState("error", "BLE scanner unavailable")
            return
        }

        logI(
            "startScanInternal",
            mapOf(
                "timeoutMs" to timeoutMs,
                "state" to MeshBleState.state,
            )
        )

        val filters = listOf(
            ScanFilter.Builder().setServiceUuid(ParcelUuid(nusServiceUuid)).build()
        )
        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()

        isScanning = true
        MeshBleState.setState("scanning")

        val callback = scanCallback
        scannerLocal.startScan(filters, settings, callback)
        logI("scan started")

        scanStopRunnable?.let { mainHandler.removeCallbacks(it) }
        scanStopRunnable = Runnable {
            stopScanInternal(emitDisconnected = true)
        }
        mainHandler.postDelayed(scanStopRunnable!!, timeoutMs)
    }

    private fun stopScanInternal(emitDisconnected: Boolean = true) {
        if (!isScanning) {
            logI("stopScanInternal ignored (not scanning)")
            return
        }
        logI("stopScanInternal", mapOf("emitDisconnected" to emitDisconnected))
        isScanning = false
        scanStopRunnable?.let { mainHandler.removeCallbacks(it) }
        scanStopRunnable = null

        try {
            scanner?.stopScan(scanCallback)
        } catch (_: Throwable) {
        }

        if (emitDisconnected && MeshBleState.state == "scanning") {
            MeshBleState.setState("disconnected")
        }
    }

    private fun cleanupGattSilent(reason: String) {
        val gattLocal = gatt ?: return
        logI("cleanupGattSilent", mapOf("reason" to reason))

        // Cancel any pending connection timeout
        cancelConnectionTimeout(reason = "cleanupGattSilent:$reason")

        clearWriteQueue(reason = "cleanupGattSilent:$reason")

        try {
            try {
                txChar?.let { gattLocal.setCharacteristicNotification(it, false) }
            } catch (_: Throwable) {
            }

            try {
                gattLocal.disconnect()
            } catch (_: Throwable) {
            }

            try {
                gattLocal.close()
            } catch (_: Throwable) {
            }
        } finally {
            gatt = null
            rxChar = null
            txChar = null
        }
    }

    private fun connectInternal(address: String, fromRestore: Boolean) {
        logI(
            "connectInternal",
            mapOf(
                "address" to address,
                "fromRestore" to fromRestore,
                "autoReconnect" to autoReconnect,
                "prevState" to MeshBleState.state,
                "hadGatt" to (gatt != null),
            )
        )

        // If the user is explicitly connecting, cancel any scheduled auto-reconnect
        // to avoid racing two connectInternal() calls.
        cancelPendingReconnect(reason = "connectInternal")
        // Stop any ongoing scan without emitting a transient "disconnected".
        // A scan stop during connect should not be treated as a device disconnect.
        stopScanInternal(emitDisconnected = false)

        targetAddress = address
        MeshBleState.deviceAddress = address
        MeshBleState.deviceName = null

        if (!fromRestore) {
            val prefs = getSharedPreferences(prefsName, MODE_PRIVATE)
            prefs.edit()
                .putString(keyLastAddress, address)
                .putBoolean(keyAutoReconnect, true)
                .apply()
            autoReconnect = true
        }

        // Clean up any previous GATT without emitting disconnect transitions.
        cleanupGattSilent(reason = "preconnect")

        val adapter = bluetoothAdapter ?: run {
            logE("connectInternal failed: adapter null")
            MeshBleState.setState("error", "Bluetooth adapter unavailable")
            return
        }

        val device: BluetoothDevice = try {
            adapter.getRemoteDevice(address)
        } catch (e: IllegalArgumentException) {
            logE("connectInternal failed: invalid address", mapOf("address" to address))
            MeshBleState.setState("error", "Invalid device address")
            return
        }

        // Proactively kick off bonding if needed so pairing prompts happen before
        // we start the app handshake writes.
        if (device.bondState == BluetoothDevice.BOND_NONE) {
            try {
                val started = device.createBond()
                logI("createBond", mapOf("started" to started))
            } catch (e: SecurityException) {
                logW("createBond SecurityException", mapOf("msg" to (e.message ?: "")))
            } catch (e: Throwable) {
                logW("createBond Throwable", mapOf("msg" to (e.message ?: "")))
            }
        }

        logI(
            "connectGatt",
            mapOf(
                "name" to (device.name ?: ""),
                "bond" to device.bondState,
                "sdk" to Build.VERSION.SDK_INT,
            )
        )

        MeshBleState.deviceName = device.name
        MeshBleState.setState("connecting")

        reconnectAttempt = 0

        resetConnectionTimeout(reason = "connectInternal")

        gatt = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            device.connectGatt(this, false, gattCallback, BluetoothDevice.TRANSPORT_LE)
        } else {
            device.connectGatt(this, false, gattCallback)
        }

        logI("connectGatt invoked", mapOf("gattNull" to (gatt == null)))
    }

    private fun disconnectInternal(manual: Boolean) {
        if (MeshBleState.state == "disconnecting") {
            logW("disconnectInternal ignored (already disconnecting)", mapOf("manual" to manual))
            return
        }

        logI(
            "disconnectInternal",
            mapOf(
                "manual" to manual,
                "state" to MeshBleState.state,
                "hadGatt" to (gatt != null),
                "hadTx" to (txChar != null),
            )
        )

        // Cancel connection timeout
        cancelConnectionTimeout(reason = "disconnectInternal")

        clearWriteQueue(reason = "disconnectInternal")

        if (gatt == null) {
            rxChar = null
            txChar = null
            refreshNativeTelemetryLoop(reason = "disconnect_no_gatt")
            if (manual) {
                MeshBleState.deviceName = null
                MeshBleState.deviceAddress = null
                MeshBleState.setState("disconnected")
            }
            return
        }

        MeshBleState.setState("disconnecting")

        try {
            try {
                txChar?.let {
                    gatt?.setCharacteristicNotification(it, false)
                }
            } catch (_: Throwable) {
            }

            gatt?.disconnect()
            gatt?.close()
        } catch (_: Throwable) {
        } finally {
            gatt = null
            rxChar = null
            txChar = null
            refreshNativeTelemetryLoop(reason = "disconnect")
            if (manual) {
                MeshBleState.deviceName = null
                MeshBleState.deviceAddress = null
            }
            MeshBleState.setState("disconnected")
        }
    }

    private fun scheduleReconnect() {
        if (!autoReconnect) {
            logI("scheduleReconnect skipped (autoReconnect=false)")
            return
        }
        val address = targetAddress ?: return

        logI("scheduleReconnect", mapOf("address" to address, "attemptPrev" to reconnectAttempt))

        reconnectAttempt += 1
        val backoffMs = min(30_000L, 2_000L * (1L shl min(4, reconnectAttempt - 1)))

        MeshBleEventBus.send(
            mapOf(
                "type" to "reconnect",
                "attempt" to reconnectAttempt,
                "backoffMs" to backoffMs,
                "address" to address,
            )
        )

        cancelPendingReconnect(reason = "reschedule")
        pendingReconnectRunnable = Runnable {
            logI("reconnect firing", mapOf("address" to address, "attempt" to reconnectAttempt))
            connectInternal(address, fromRestore = true)
        }
        mainHandler.postDelayed(pendingReconnectRunnable!!, backoffMs)
    }

    private fun writeFrameInternal(data: ByteArray) {
        // Legacy entrypoint used by older codepaths. Keep it, but route through the
        // write queue so we don't fail the whole connection on transient busy.
        enqueueFrameInternal(data)
    }

    private fun clearWriteQueue(reason: String) {
        writeWatchdogRunnable?.let { mainHandler.removeCallbacks(it) }
        writeWatchdogRunnable = null
        writeQueue.clear()
        writeInFlight = false
        inFlightFrame = null
        logI("write queue cleared", mapOf("reason" to reason))
    }

    private fun enqueueFrameInternal(data: ByteArray) {
        // Always serialize queue ops on the main thread.
        mainHandler.post {
            if (data.isEmpty()) return@post
            if (writeQueue.size >= 200) {
                logE("write queue overflow", mapOf("size" to writeQueue.size))
                MeshBleState.setState("error", "Write queue overflow")
                clearWriteQueue(reason = "overflow")
                return@post
            }
            writeQueue.addLast(data)
            drainWriteQueueLocked(reason = "enqueue")
        }
    }

    private fun armWriteWatchdog() {
        writeWatchdogRunnable?.let { mainHandler.removeCallbacks(it) }
        writeWatchdogRunnable = Runnable {
            if (!writeInFlight) return@Runnable
            // Some devices/stack combos don't reliably fire onCharacteristicWrite for
            // WRITE_TYPE_NO_RESPONSE. Don't deadlock the queue.
            logW("write watchdog fired")
            inFlightFrame = null
            writeInFlight = false
            drainWriteQueueLocked(reason = "watchdog")
        }
        mainHandler.postDelayed(writeWatchdogRunnable!!, 600L)
    }

    private fun drainWriteQueueLocked(reason: String) {
        if (writeInFlight) return
        if (MeshBleState.state != "connected") return

        val gattLocal = gatt ?: return
        val rx = rxChar ?: return
        if (writeQueue.isEmpty()) return

        val frame = writeQueue.removeFirst()
        logI("drainWriteQueue", mapOf("reason" to reason, "len" to frame.size, "q" to writeQueue.size, "hex" to frameToHex(frame)))

        try {
            rx.value = frame
            val props = rx.properties
            rx.writeType = if ((props and BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE) != 0) {
                BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
            } else {
                BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
            }

            writeInFlight = true
            inFlightFrame = frame
            armWriteWatchdog()
            val ok = gattLocal.writeCharacteristic(rx)
            if (!ok) {
                // Usually indicates the GATT is busy; retry shortly.
                logW("writeCharacteristic returned false (will retry)")
                writeWatchdogRunnable?.let { mainHandler.removeCallbacks(it) }
                writeWatchdogRunnable = null
                writeInFlight = false
                inFlightFrame = null
                writeQueue.addFirst(frame)
                mainHandler.postDelayed({ drainWriteQueueLocked(reason = "retry") }, 30L)
            }
        } catch (e: SecurityException) {
            logE("write SecurityException", mapOf("msg" to (e.message ?: "")))
            MeshBleState.setState("error", "Missing Bluetooth permission")
            disconnectInternal(manual = false)
            scheduleReconnect()
        } catch (e: Throwable) {
            logE("write Throwable", mapOf("msg" to (e.message ?: "")))
            MeshBleState.setState("error", "Write error")
            disconnectInternal(manual = false)
            scheduleReconnect()
        }
    }

    private val scanCallback: ScanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult?) {
            if (result == null) return
            val device = result.device
            val name = device.name ?: ""
            if (name.isNotEmpty() && name.startsWith("MeshCore-")) {
                logI("scan result", mapOf("name" to name, "address" to device.address))
                MeshBleEventBus.send(
                    mapOf(
                        "type" to "scan",
                        "name" to name,
                        "address" to device.address,
                    )
                )
            }
        }

        override fun onScanFailed(errorCode: Int) {
            logE("scan failed", mapOf("errorCode" to errorCode))
            MeshBleState.setState("error", "Scan failed: $errorCode")
            stopScanInternal()
        }
    }

    private val gattCallback: BluetoothGattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            logI(
                "onConnectionStateChange",
                mapOf(
                    "status" to status,
                    "newState" to newState,
                    "addr" to (gatt.device?.address ?: ""),
                    "name" to (gatt.device?.name ?: ""),
                )
            )
            // Check for connection errors
            if (status != BluetoothGatt.GATT_SUCCESS && newState == BluetoothProfile.STATE_DISCONNECTED) {
                cancelConnectionTimeout(reason = "onConnectionStateChange:error")
                clearWriteQueue(reason = "onConnectionStateChange:error")
                rxChar = null
                txChar = null
                this@MeshBleService.gatt = null
                try {
                    gatt.close()
                } catch (_: Throwable) {
                }
                logE("connection failed", mapOf("status" to status))
                MeshBleState.setState("error", "Connection failed (status: $status)")
                scheduleReconnect()
                return
            }
            
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                MeshBleState.setState("connecting")
                resetConnectionTimeout(reason = "STATE_CONNECTED")
                try {
                    // TEAM-style ordering: request MTU first, then discover services.
                    // 185 MTU => ~182 byte ATT payload (MTU-3), enough for MeshCore frames.
                    val mtuRequested = try {
                        gatt.requestMtu(185)
                    } catch (_: Throwable) {
                        false
                    }

                    logI("requestMtu", mapOf("requested" to mtuRequested))

                    if (!mtuRequested) {
                        // Fallback: proceed with default MTU.
                        val success = gatt.discoverServices()
                        logI("discoverServices (fallback)", mapOf("started" to success))
                        if (!success) {
                            MeshBleState.setState("error", "Failed to start service discovery")
                            disconnectInternal(manual = false)
                            scheduleReconnect()
                        }
                    }
                } catch (e: Throwable) {
                    logE("discoverServices exception", mapOf("msg" to (e.message ?: "")))
                    MeshBleState.setState("error", "Service discovery exception: ${e.message}")
                    disconnectInternal(manual = false)
                    scheduleReconnect()
                }
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                cancelConnectionTimeout(reason = "STATE_DISCONNECTED")
                clearWriteQueue(reason = "STATE_DISCONNECTED")
                rxChar = null
                txChar = null
                this@MeshBleService.gatt = null
                try {
                    gatt.close()
                } catch (_: Throwable) {
                }
                logW("disconnected", mapOf("status" to status))
                MeshBleState.setState("disconnected")
                scheduleReconnect()

                // If we aren't going to auto-reconnect, there's no reason to keep a
                // foreground service + persistent notification running.
                if (!autoReconnect) {
                    logI("autoReconnect=false after disconnect -> stopping service")
                    shouldRestartOnTaskRemoved = false
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        stopForeground(STOP_FOREGROUND_REMOVE)
                    } else {
                        @Suppress("DEPRECATION")
                        stopForeground(true)
                    }
                    deactivateForeground(reason = "gattDisconnected_noReconnect")
                    stopSelf()
                }
            }
        }

        override fun onMtuChanged(gatt: BluetoothGatt, mtu: Int, status: Int) {
            logI("onMtuChanged", mapOf("mtu" to mtu, "status" to status))
            resetConnectionTimeout(reason = "onMtuChanged")
            // Whether MTU negotiation succeeded or not, proceed with service discovery.
            try {
                val success = gatt.discoverServices()
                logI("discoverServices", mapOf("started" to success))
                if (!success) {
                    MeshBleState.setState("error", "Failed to start service discovery")
                    disconnectInternal(manual = false)
                    scheduleReconnect()
                }
            } catch (e: Throwable) {
                logE("discoverServices exception", mapOf("msg" to (e.message ?: "")))
                MeshBleState.setState("error", "Service discovery exception: ${e.message}")
                disconnectInternal(manual = false)
                scheduleReconnect()
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            logI("onServicesDiscovered", mapOf("status" to status))
            resetConnectionTimeout(reason = "onServicesDiscovered")
            if (status != BluetoothGatt.GATT_SUCCESS) {
                MeshBleState.setState("error", "Service discovery failed")
                disconnectInternal(manual = false)
                scheduleReconnect()
                return
            }

            val service = gatt.getService(nusServiceUuid) ?: run {
                logE("NUS service not found")
                MeshBleState.setState("error", "NUS service not found")
                disconnectInternal(manual = false)
                scheduleReconnect()
                return
            }

            logI("NUS service found")

            val rx = service.getCharacteristic(rxCharUuid)
            val tx = service.getCharacteristic(txCharUuid)

            if (rx == null || tx == null) {
                logE("UART characteristics missing")
                MeshBleState.setState("error", "UART characteristics missing")
                disconnectInternal(manual = false)
                scheduleReconnect()
                return
            }

            logI("UART characteristics found")

            rxChar = rx
            txChar = tx

            val ok = gatt.setCharacteristicNotification(tx, true)
            logI("setCharacteristicNotification", mapOf("ok" to ok))
            if (!ok) {
                MeshBleState.setState("error", "Notify enable failed")
                disconnectInternal(manual = false)
                scheduleReconnect()
                return
            }

            val cccd = tx.getDescriptor(cccdUuid)
            if (cccd != null) {
                val writeOk: Boolean = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    val statusCode = gatt.writeDescriptor(
                        cccd,
                        BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                    )
                    statusCode == BluetoothStatusCodes.SUCCESS
                } else {
                    cccd.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                    gatt.writeDescriptor(cccd)
                }

                logI(
                    "write CCCD",
                    mapOf(
                        "sdk" to Build.VERSION.SDK_INT,
                        "writeOk" to writeOk,
                    )
                )
                if (!writeOk) {
                    MeshBleState.setState("error", "Failed to write CCCD descriptor")
                    disconnectInternal(manual = false)
                    scheduleReconnect()
                }
                // NOTE: Don't set connected state here - wait for onDescriptorWrite callback
            } else {
                logE("CCCD descriptor not found")
                MeshBleState.setState("error", "CCCD descriptor not found")
                disconnectInternal(manual = false)
                scheduleReconnect()
            }
        }

        @Deprecated("Deprecated in Java")
        override fun onDescriptorWrite(gatt: BluetoothGatt, descriptor: BluetoothGattDescriptor, status: Int) {
            logI(
                "onDescriptorWrite",
                mapOf(
                    "uuid" to descriptor.uuid.toString(),
                    "status" to status,
                )
            )
            if (descriptor.uuid != cccdUuid) return

            if (status == BluetoothGatt.GATT_SUCCESS) {
                // Notifications successfully enabled - now we're truly connected
                cancelConnectionTimeout(reason = "onDescriptorWrite:connected")
                logI("notifications enabled -> connected")
                MeshBleState.setState("connected")
                refreshNativeTelemetryLoop(reason = "connected")

                // Drain any queued frames now that we can write.
                mainHandler.post { drainWriteQueueLocked(reason = "connected") }

                // Only now do we promote to a foreground service / persistent notification.
                ensureForegroundActive(reason = "connected")
            } else {
                logE("descriptor write failed", mapOf("status" to status))
                MeshBleState.setState("error", "Failed to enable notifications (status: $status)")
                refreshNativeTelemetryLoop(reason = "descriptor_failed")
                disconnectInternal(manual = false)
                scheduleReconnect()
            }
        }

        @Deprecated("Deprecated in Java")
        override fun onCharacteristicWrite(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            status: Int
        ) {
            if (characteristic.uuid != rxCharUuid) return
            logI("onCharacteristicWrite", mapOf("status" to status))
            mainHandler.post {
                writeWatchdogRunnable?.let { mainHandler.removeCallbacks(it) }
                writeWatchdogRunnable = null
                writeInFlight = false

                val frame = inFlightFrame
                if (frame != null) {
                    logI("[BLE TX] wrote", mapOf("len" to frame.size, "hex" to frameToHex(frame)))
                }
                inFlightFrame = null

                if (status != BluetoothGatt.GATT_SUCCESS) {
                    // If bonding/pairing is in progress, some stacks report auth/encryption
                    // required for early writes. Treat these as retryable.
                    if (status == 5 || status == 15) {
                        logW("write deferred (auth/encryption required)", mapOf("status" to status))
                        if (frame != null) {
                            writeQueue.addFirst(frame)
                        }
                        mainHandler.postDelayed({ drainWriteQueueLocked(reason = "auth_retry") }, 750L)
                        return@post
                    }
                    logE("characteristic write failed", mapOf("status" to status))
                    MeshBleState.setState("error", "Write failed (status: $status)")
                    disconnectInternal(manual = false)
                    scheduleReconnect()
                    return@post
                }

                drainWriteQueueLocked(reason = "onCharacteristicWrite")
            }
        }

        @Deprecated("Deprecated in Java")
        override fun onCharacteristicChanged(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
            if (characteristic.uuid != txCharUuid) return
            val value = characteristic.value ?: return
            MeshBleEventBus.send(
                mapOf(
                    "type" to "frame",
                    "data" to value,
                )
            )
        }

        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray
        ) {
            if (characteristic.uuid != txCharUuid) return
            logI("notify frame", mapOf("len" to value.size, "hex" to frameToHex(value)))
            MeshBleEventBus.send(
                mapOf(
                    "type" to "frame",
                    "data" to value,
                )
            )
        }
    }

    private fun startNotificationTicker() {
        stopNotificationTicker()
        notificationTickRunnable = object : Runnable {
            override fun run() {
                try {
                    refreshForegroundNotification(force = false)
                } finally {
                    // Keep it reasonably fresh without being noisy.
                    mainHandler.postDelayed(this, 1500)
                }
            }
        }
        mainHandler.post(notificationTickRunnable!!)
    }

    private fun stopNotificationTicker() {
        notificationTickRunnable?.let { mainHandler.removeCallbacks(it) }
        notificationTickRunnable = null
    }

    private fun notificationTextForState(): String {
        val nameOrAddr = MeshBleState.deviceName
            ?: MeshBleState.deviceAddress
            ?: "companion"

        val baseText = when (MeshBleState.state) {
            "connected" -> "Connected to $nameOrAddr"
            "connecting" -> "Connecting to $nameOrAddr"
            "scanning" -> "Scanning for devices…"
            "disconnecting" -> "Disconnecting…"
            "error" -> MeshBleState.errorMessage ?: "Connection error"
            "disconnected" -> "Disconnected"
            else -> "Mesh service active"
        }

        val trackingLine = trackingNotificationLine()
        if (trackingLine == null) {
            return baseText
        }

        return "$baseText\n$trackingLine"
    }

    private fun trackingNotificationLine(): String? {
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val telemetryEnabled = prefs.getBoolean("flutter.telemetry_enabled", false)
        if (!telemetryEnabled) return null

        val companionKey = prefs.getString("flutter.current_companion_public_key", null)
        val perCompanionName = if (!companionKey.isNullOrBlank()) {
            prefs.getString("flutter.telemetry_channel_name_$companionKey", null)
        } else {
            null
        }
        val channelName = perCompanionName ?: prefs.getString("flutter.telemetry_channel_name", null)

        val normalizedName = channelName?.trim()?.takeIf { it.isNotEmpty() }
        if (normalizedName != null) {
            return "Tracking enabled on channel:$normalizedName"
        }

        val perCompanionHash = if (!companionKey.isNullOrBlank()) {
            prefs.getString("flutter.telemetry_channel_hash_$companionKey", null)
        } else {
            null
        }
        val hash = perCompanionHash ?: prefs.getString("flutter.telemetry_channel_hash", null)
        val normalizedHash = hash?.trim()?.takeIf { it.isNotEmpty() } ?: return null

        return "Tracking enabled on channel:$normalizedHash"
    }

    private fun refreshForegroundNotification(force: Boolean) {
        if (!isForegroundActive) return
        val isPresent = isForegroundNotificationPresent()
        if (lastNotificationPresent == null || lastNotificationPresent != isPresent) {
            logI(
                "notif presence",
                mapOf(
                    "present" to isPresent,
                    "state" to MeshBleState.state,
                )
            )
            lastNotificationPresent = isPresent
        }

        val text = notificationTextForState()
        // If the notification is missing, force a re-assert even if text didn't change.
        if (!force && isPresent && text == lastNotificationText) return
        lastNotificationText = text

        ensureNotificationChannel()
        val notification = buildNotification(text)

        // Re-assert foreground status so the notification can't be permanently dismissed.
        try {
            ServiceCompat.startForeground(
                this,
                notificationId,
                notification,
                if (nativeTelemetryEnabled) {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE or
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
                } else {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
                },
            )
            logI(
                "startForeground(refreshed)",
                mapOf(
                    "force" to force,
                    "presentBefore" to isPresent,
                    "text" to text,
                    "state" to MeshBleState.state,
                )
            )
        } catch (t: Throwable) {
            logE(
                "startForeground failed",
                mapOf(
                    "force" to force,
                    "presentBefore" to isPresent,
                    "text" to text,
                    "state" to MeshBleState.state,
                    "err" to (t.message ?: ""),
                )
            )
        }
    }

    private fun isForegroundNotificationPresent(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        return try {
            val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            manager.activeNotifications.any { it.id == notificationId }
        } catch (_: Throwable) {
            true
        }
    }

    private fun refreshNativeTelemetryLoop(reason: String) {
        val connected = MeshBleState.state == "connected" && rxChar != null
        if (nativeTelemetryEnabled && connected) {
            startNativeTelemetryLoop(reason)
            // Manage phone location updates based on source. This runs on every
            // config change (not just initial start) so switching between phone
            // and companion correctly starts/stops the FusedLocationProviderClient.
            if (nativeTelemetryLocationSource == "companion") {
                stopNativeLocationUpdates("companion_source")
            } else {
                startNativeLocationUpdates(reason)
            }
        } else {
            stopNativeTelemetryLoop(reason)
        }
    }

    private fun startNativeTelemetryLoop(reason: String) {
        if (nativeTelemetryRunnable != null) return
        telemetryLogI(
            "native telemetry loop start",
            mapOf(
                "reason" to reason,
                "intervalSeconds" to nativeTelemetryIntervalSeconds,
                "minDistanceMeters" to nativeTelemetryMinDistanceMeters,
                "channelIndex" to nativeTelemetryChannelIndex,
            )
        )
        if (nativeTelemetryNextPeriodicDueMs == 0L) {
            nativeTelemetryNextPeriodicDueMs = System.currentTimeMillis() + (nativeTelemetryIntervalSeconds * 1000L)
        }

        if (nativeTelemetryLocationSource != "companion") {
            startNativeLocationUpdates(reason)
        }

        nativeTelemetryRunnable = object : Runnable {
            override fun run() {
                if (!nativeTelemetryEnabled || MeshBleState.state != "connected") {
                    stopNativeTelemetryLoop(reason = "ticker_guard")
                    return
                }

                evaluateAndSendTelemetryFromLatest()
                mainHandler.postDelayed(this, nativeTelemetryTickMs)
            }
        }
        mainHandler.post(nativeTelemetryRunnable!!)
    }

    private fun stopNativeTelemetryLoop(reason: String) {
        nativeTelemetryRunnable?.let {
            mainHandler.removeCallbacks(it)
            nativeTelemetryRunnable = null
            telemetryLogI("native telemetry loop stop", mapOf("reason" to reason))
        }
        stopNativeLocationUpdates(reason)
    }

    private fun startNativeLocationUpdates(reason: String) {
        if (nativeTelemetryLocationCallback != null) return
        if (!hasLocationPermission()) {
            telemetryLogW("native telemetry location updates skipped: permission missing")
            return
        }

        val request = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, nativeTelemetryTickMs)
            .setMinUpdateIntervalMillis(2_000L)
            .setWaitForAccurateLocation(true)
            .build()

        val callback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                val location = result.lastLocation ?: return
                nativeTelemetryLatestLocation = location
                nativeTelemetryLatestLocationAtMs = System.currentTimeMillis()
            }
        }

        try {
            fusedLocationClient.requestLocationUpdates(request, callback, Looper.getMainLooper())
            nativeTelemetryLocationCallback = callback
            telemetryLogI("native telemetry location updates started", mapOf("reason" to reason))
        } catch (security: SecurityException) {
            telemetryLogW("native telemetry location updates denied", mapOf("err" to (security.message ?: "")))
        } catch (error: Throwable) {
            telemetryLogW("native telemetry location updates failed", mapOf("err" to (error.message ?: "")))
        }
    }

    private fun stopNativeLocationUpdates(reason: String) {
        val callback = nativeTelemetryLocationCallback ?: return
        try {
            fusedLocationClient.removeLocationUpdates(callback)
        } catch (_: Throwable) {
        }
        nativeTelemetryLocationCallback = null
        nativeTelemetryLatestLocation = null
        nativeTelemetryLatestLocationAtMs = 0L
        nativeTelemetryNoFixWarnAtMs = 0L
        nativeTelemetryStaleWarnAtMs = 0L
        telemetryLogI("native telemetry location updates stopped", mapOf("reason" to reason))
    }

    private fun evaluateAndSendTelemetryFromLatest() {
        val location = resolveCurrentLocation()
        if (location == null) {
            maybeLogNativeTelemetrySkip(
                reason = "no location fix yet",
                lastLoggedAtMs = nativeTelemetryNoFixWarnAtMs,
                updateLastLogged = { nativeTelemetryNoFixWarnAtMs = it },
            )
            return
        }

        val ageMs = System.currentTimeMillis() - location.time
        if (ageMs > maxTelemetryLocationAgeMs) {
            maybeLogNativeTelemetrySkip(
                reason = "stale location",
                extra = mapOf("ageMs" to ageMs, "source" to nativeTelemetryLocationSource),
                lastLoggedAtMs = nativeTelemetryStaleWarnAtMs,
                updateLastLogged = { nativeTelemetryStaleWarnAtMs = it },
            )
            return
        }

        evaluateAndSendTelemetry(location)
    }

    /**
     * Resolves the best available location based on the configured source.
     * When source is "companion", builds a Location from the pushed companion
     * coordinates. Falls back to phone GPS if companion coords are unavailable.
     */
    private fun resolveCurrentLocation(): Location? {
        if (nativeTelemetryLocationSource == "companion") {
            val lat = nativeTelemetryCompanionLat
            val lon = nativeTelemetryCompanionLon
            val atMs = nativeTelemetryCompanionLocationAtMs
            if (lat != null && lon != null && atMs > 0) {
                return Location("companion").apply {
                    latitude = lat
                    longitude = lon
                    time = atMs
                }
            }
            // Companion coords not available yet — fall through to phone GPS
        }

        val loc = nativeTelemetryLatestLocation ?: return null
        return Location(loc).apply { time = nativeTelemetryLatestLocationAtMs }
    }

    private fun maybeLogNativeTelemetrySkip(
        reason: String,
        extra: Map<String, Any?> = emptyMap(),
        lastLoggedAtMs: Long,
        updateLastLogged: (Long) -> Unit,
    ) {
        val now = System.currentTimeMillis()
        if (now - lastLoggedAtMs < nativeTelemetryWarnThrottleMs) {
            return
        }

        updateLastLogged(now)
        telemetryLogW("native telemetry skipped: $reason", extra)
    }

    private fun evaluateAndSendTelemetry(location: Location) {
        val now = System.currentTimeMillis()

        if (now - nativeTelemetryLastSendMs < minTelemetrySendIntervalMs) {
            return
        }

        val periodicDue = now >= nativeTelemetryNextPeriodicDueMs
        val distanceTriggered = nativeTelemetryMinDistanceMeters > 0 &&
            nativeTelemetryLastSentLocation?.distanceTo(location)?.let {
                it >= nativeTelemetryMinDistanceMeters
            } == true

        val reason = when {
            periodicDue -> "PERIODIC"
            distanceTriggered -> "DISTANCE"
            else -> null
        } ?: return

        if (sendNativeTelemetry(location, reason)) {
            nativeTelemetryLastSendMs = now
            nativeTelemetryLastSentLocation = location
            nativeTelemetryNextPeriodicDueMs = now + (nativeTelemetryIntervalSeconds * 1000L)
        }
    }

    private fun sendNativeTelemetry(location: Location, reason: String): Boolean {
        val phoneBatteryMv = readPhoneBatteryMilliVolts()
        val useTopology = nativeTelemetryStrategyMode == "topology"
        telemetryLogI(
            "[TELSEND] building",
            mapOf(
                "reason" to reason,
                "gpsSource" to location.provider,
                "lat" to location.latitude,
                "lon" to location.longitude,
                "channelIndex" to nativeTelemetryChannelIndex,
                "companionBatteryMilliVolts" to nativeTelemetryCompanionBatteryMilliVolts,
                "phoneBatteryMilliVolts" to phoneBatteryMv,
                "needsForwarding" to nativeTelemetryNeedsForwarding,
                "maxPathObserved" to nativeTelemetryMaxPathObserved,
                "strategy" to nativeTelemetryStrategyMode,
            )
        )

        val frame = if (useTopology) {
            buildTopologyFrame(
                channelIndex = nativeTelemetryChannelIndex,
                latitude = location.latitude,
                longitude = location.longitude,
                companionBatteryMilliVolts = nativeTelemetryCompanionBatteryMilliVolts,
                phoneBatteryMilliVolts = phoneBatteryMv,
                neighborBitmap = nativeTelemetryNeighborBitmap,
                nodeCount = nativeTelemetryNodeCount,
            )
        } else {
            buildTelemetryFrame(
                channelIndex = nativeTelemetryChannelIndex,
                latitude = location.latitude,
                longitude = location.longitude,
                companionBatteryMilliVolts = nativeTelemetryCompanionBatteryMilliVolts,
                phoneBatteryMilliVolts = phoneBatteryMv,
                needsForwarding = nativeTelemetryNeedsForwarding,
                maxPathObserved = nativeTelemetryMaxPathObserved,
            )
        }

        enqueueFrameInternal(frame)
        telemetryLogI(
            "[TELSEND] queued",
            mapOf(
                "reason" to reason,
                "strategy" to nativeTelemetryStrategyMode,
                "frameLen" to frame.size,
                "frameHex" to frameToHex(frame),
            )
        )
        return true
    }

    private fun buildTelemetryFrame(
        channelIndex: Int,
        latitude: Double,
        longitude: Double,
        companionBatteryMilliVolts: Int?,
        phoneBatteryMilliVolts: Int?,
        needsForwarding: Boolean,
        maxPathObserved: Int,
    ): ByteArray {
        val payload = ByteArray(telemetryPayloadSize)
        val data = ByteBuffer.wrap(payload).order(ByteOrder.BIG_ENDIAN)

        data.putInt((latitude * 1e7).toInt())
        data.putInt((longitude * 1e7).toInt())
        payload[8] = encodeBatteryVoltage(companionBatteryMilliVolts).toByte()
        payload[9] = encodeBatteryVoltage(phoneBatteryMilliVolts).toByte()
        payload[10] = encodeForwardingStatus(needsForwarding, maxPathObserved).toByte()

        val b64 = Base64.encodeToString(payload, Base64.NO_WRAP).trimEnd('=')
        val telemetryText = telemetryPrefix + b64
        val telemetryBytes = telemetryText.toByteArray(Charsets.ISO_8859_1)

        val frame = ByteArray(1 + 1 + 1 + 4 + telemetryBytes.size)
        val writer = ByteBuffer.wrap(frame).order(ByteOrder.LITTLE_ENDIAN)
        writer.put(cmdSendChannelTxtMsg.toByte())
        writer.put(0)
        writer.put(channelIndex.toByte())
        writer.putInt((System.currentTimeMillis() / 1000L).toInt())
        writer.put(telemetryBytes)

        telemetryLogI(
            "[TELSEND] frame built",
            mapOf(
                "telemetryText" to telemetryText,
                "payloadHex" to payload.joinToString("") { String.format("%02X", it) },
                "frameLen" to frame.size,
                "channelIndex" to channelIndex,
            )
        )
        return frame
    }

    private fun encodeBatteryVoltage(millivolts: Int?): Int {
        if (millivolts == null || millivolts == 0) return 1
        val clamped = millivolts.coerceIn(2750, 4280)
        val encoded = ((clamped - 2750) / 6) + 2
        // Clamp to 254 max — 0xFF (255) is reserved as the autonomous sentinel.
        // KEEP IN SYNC: TelemetryMessage._encodeBatteryVoltage (Dart)
        //               TopologyMessage._encodeBattery (Dart)
        return encoded.coerceIn(2, 254)
    }

    private fun encodeForwardingStatus(needsForwarding: Boolean, maxPathObserved: Int): Int {
        val flag = if (needsForwarding) 1 else 0
        val path = maxPathObserved.coerceIn(0, 127)
        return (((path shl 1) or flag) + 1) and 0xFF
    }

    private fun buildTopologyFrame(
        channelIndex: Int,
        latitude: Double,
        longitude: Double,
        companionBatteryMilliVolts: Int?,
        phoneBatteryMilliVolts: Int?,
        neighborBitmap: ByteArray?,
        nodeCount: Int,
    ): ByteArray {
        val bitmap = neighborBitmap ?: ByteArray(0)
        val payloadSize = 11 + bitmap.size
        val payload = ByteArray(payloadSize)
        val data = ByteBuffer.wrap(payload).order(ByteOrder.BIG_ENDIAN)

        data.putInt((latitude * 1e7).toInt())
        data.putInt((longitude * 1e7).toInt())
        payload[8] = encodeBatteryVoltage(companionBatteryMilliVolts).toByte()
        payload[9] = encodeBatteryVoltage(phoneBatteryMilliVolts).toByte()
        payload[10] = (nodeCount and 0xFF).toByte()
        if (bitmap.isNotEmpty()) {
            System.arraycopy(bitmap, 0, payload, 11, bitmap.size)
        }

        val b64 = Base64.encodeToString(payload, Base64.NO_WRAP).trimEnd('=')
        val telemetryText = topologyPrefix + b64
        val telemetryBytes = telemetryText.toByteArray(Charsets.ISO_8859_1)

        val frame = ByteArray(1 + 1 + 1 + 4 + telemetryBytes.size)
        val writer = ByteBuffer.wrap(frame).order(ByteOrder.LITTLE_ENDIAN)
        writer.put(cmdSendChannelTxtMsg.toByte())
        writer.put(0)
        writer.put(channelIndex.toByte())
        writer.putInt((System.currentTimeMillis() / 1000L).toInt())
        writer.put(telemetryBytes)

        telemetryLogI(
            "[TELSEND] topology frame built",
            mapOf(
                "telemetryText" to telemetryText,
                "payloadHex" to payload.joinToString("") { String.format("%02X", it) },
                "frameLen" to frame.size,
                "channelIndex" to channelIndex,
                "nodeCount" to nodeCount,
                "bitmapLen" to bitmap.size,
            )
        )
        return frame
    }

    private fun hasLocationPermission(): Boolean {
        val fine = ContextCompat.checkSelfPermission(
            this,
            android.Manifest.permission.ACCESS_FINE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        val coarse = ContextCompat.checkSelfPermission(
            this,
            android.Manifest.permission.ACCESS_COARSE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        return fine || coarse
    }

    private fun readPhoneBatteryMilliVolts(): Int? {
        return try {
            val batteryIntent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
                ?: return null
            val value = batteryIntent.getIntExtra(android.os.BatteryManager.EXTRA_VOLTAGE, -1)
            if (value <= 0) null else value
        } catch (_: Throwable) {
            null
        }
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        val existing = manager.getNotificationChannel(channelId)
        if (existing != null) return

        val channel = NotificationChannel(
            channelId,
            "Mesh Connection",
            NotificationManager.IMPORTANCE_LOW
        )
        channel.description = "Maintains Mesh BLE connection"
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(text: String): Notification {
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        val openAppPendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val deleteIntent = Intent(this, MeshBleNotificationDismissReceiver::class.java)
        val deletePendingIntent = PendingIntent.getBroadcast(
            this,
            0,
            deleteIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val stopIntent = Intent(this, MeshBleService::class.java).setAction(actionUserStop)
        val stopPendingIntent = PendingIntent.getService(
            this,
            1,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("Mesh network")
            .setContentText(text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(text))
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(openAppPendingIntent)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Stop reconnect",
                stopPendingIntent,
            )
            .setDeleteIntent(deletePendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}
