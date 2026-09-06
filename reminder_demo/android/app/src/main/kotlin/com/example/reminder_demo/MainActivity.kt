package com.example.reminder_demo

import android.media.RingtoneManager
import android.net.Uri
import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File

private const val SYSTEM_ALARM_CHANNEL = "reminder_demo/system_alarms"
private const val EXACT_ALARM_CHANNEL = "reminder_demo/exact_alarms"

class MainActivity : FlutterActivity() {
	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SYSTEM_ALARM_CHANNEL)
			.setMethodCallHandler { call, result ->
				if (call.method != "getSystemAlarmTones") {
					result.notImplemented()
					return@setMethodCallHandler
				}

				try {
					result.success(copySystemAlarmTones())
				} catch (error: Exception) {
					result.error("SYSTEM_ALARMS_UNAVAILABLE", error.message, null)
				}
			}

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EXACT_ALARM_CHANNEL)
			.setMethodCallHandler { call, result ->
				if (call.method != "ensurePermission") {
					result.notImplemented()
					return@setMethodCallHandler
				}
				if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
					result.success(true)
					return@setMethodCallHandler
				}
				val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
				if (alarmManager.canScheduleExactAlarms()) {
					result.success(true)
				} else {
					startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM))
					result.success(false)
				}
			}
	}

	private fun copySystemAlarmTones(): List<String> {
		val outputDirectory = File(filesDir, "ReminderApp/SystemTones")
		if (!outputDirectory.exists()) outputDirectory.mkdirs()

		val copied = mutableListOf<String>()
		val seenUris = mutableSetOf<String>()
		val toneTypes = listOf(
			RingtoneManager.TYPE_ALARM,
			RingtoneManager.TYPE_RINGTONE,
			RingtoneManager.TYPE_NOTIFICATION,
		)

		for (toneType in toneTypes) {
			val ringtoneManager = RingtoneManager(this)
			ringtoneManager.setType(toneType)
			val cursor = ringtoneManager.cursor ?: continue
			cursor.use {
				while (it.moveToNext()) {
					val title = it.getString(RingtoneManager.TITLE_COLUMN_INDEX) ?: "tone"
					val uri = ringtoneManager.getRingtoneUri(it.position) ?: continue
					if (!seenUris.add(uri.toString())) continue
					val extension = extensionFor(uri)
					val safeTitle = title.replace(Regex("[^A-Za-z0-9._-]"), "_")
					val target = File(
						outputDirectory,
						"${safeTitle}_${uri.toString().hashCode().toUInt()}$extension",
					)

					if (!target.exists()) {
						contentResolver.openInputStream(uri)?.use { input ->
							target.outputStream().use { output -> input.copyTo(output) }
						} ?: continue
					}
					copied.add(target.absolutePath)
				}
			}
		}
		return copied
	}

	private fun extensionFor(uri: Uri): String {
		return when (contentResolver.getType(uri)?.lowercase()) {
			"audio/mpeg", "audio/mp3" -> ".mp3"
			"audio/mp4", "audio/m4a", "audio/aac" -> ".m4a"
			"audio/wav", "audio/x-wav" -> ".wav"
			"audio/ogg", "audio/opus" -> ".ogg"
			else -> ".ogg"
		}
	}
}
