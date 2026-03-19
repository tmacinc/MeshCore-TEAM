package com.meshcore.team

import com.meshcore.team.mesh.MeshBleEventBus
import com.meshcore.team.mesh.MeshBleService
import com.meshcore.team.mesh.MeshBleState
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val methodChannelName = "com.meshcore.team/mesh_ble"
	private val eventChannelName = "com.meshcore.team/mesh_ble_events"
	private val appChannelName = "com.meshcore.team/app_lifecycle"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"configureNativeTelemetry" -> {
						val enabled = call.argument<Boolean>("enabled") ?: false
						val channelIndex = call.argument<Number>("channelIndex")?.toInt() ?: 0
						val intervalSeconds = call.argument<Number>("intervalSeconds")?.toInt() ?: 60
						val minDistanceMeters = call.argument<Number>("minDistanceMeters")?.toInt() ?: 100
						val companionBatteryMilliVolts = call.argument<Number>("companionBatteryMilliVolts")?.toInt()
						val needsForwarding = call.argument<Boolean>("needsForwarding") ?: false
						val maxPathObserved = call.argument<Number>("maxPathObserved")?.toInt() ?: 0
						val locationSource = call.argument<String>("locationSource") ?: "phone"
						MeshBleService.configureNativeTelemetry(
							this,
							enabled,
							channelIndex,
							intervalSeconds,
							minDistanceMeters,
							companionBatteryMilliVolts,
							needsForwarding,
							maxPathObserved,
							locationSource,
						)
						result.success(true)
					}
					"stopNativeTelemetry" -> {
						MeshBleService.stopNativeTelemetry(this)
						result.success(true)
					}
					"updateCompanionLocation" -> {
						val latitude = call.argument<Double>("latitude")
						val longitude = call.argument<Double>("longitude")
						if (latitude != null && longitude != null) {
							MeshBleService.updateCompanionLocation(this, latitude, longitude)
							result.success(true)
						} else {
							result.error("bad_args", "Missing latitude/longitude", null)
						}
					}
					"startScan" -> {
						val timeoutMs = (call.argument<Number>("timeoutMs")?.toLong() ?: 10_000L)
						MeshBleService.startScan(this, timeoutMs)
						result.success(true)
					}
					"stopScan" -> {
						MeshBleService.stopScan(this)
						result.success(true)
					}
					"connect" -> {
						val address = call.argument<String>("address")
						if (address.isNullOrBlank()) {
							result.error("bad_args", "Missing 'address'", null)
						} else {
							MeshBleService.connect(this, address)
							result.success(true)
						}
					}
					"disconnect" -> {
						MeshBleService.disconnect(this)
						result.success(true)
					}
					"sendFrame" -> {
						val data = call.argument<ByteArray>("data")
						if (data == null) {
							result.error("bad_args", "Missing 'data'", null)
						} else {
							MeshBleService.sendFrame(this, data)
							result.success(true)
						}
					}
					"getStatus" -> {
						result.success(MeshBleState.snapshot())
					}
					"startService" -> {
						MeshBleService.startService(this)
						result.success(true)
					}
					"stopService" -> {
						MeshBleService.stopService(this)
						result.success(true)
					}
					else -> result.notImplemented()
				}
			}

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, appChannelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"moveToBackground" -> {
						moveTaskToBack(true)
						result.success(true)
					}
					else -> result.notImplemented()
				}
			}

		EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
			.setStreamHandler(object : EventChannel.StreamHandler {
				override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
					MeshBleEventBus.setSink(events)
					// Push current status immediately on (re)attach
					events.success(MeshBleState.eventStatus())
				}

				override fun onCancel(arguments: Any?) {
					MeshBleEventBus.clearSink()
				}
			})
	}
}
