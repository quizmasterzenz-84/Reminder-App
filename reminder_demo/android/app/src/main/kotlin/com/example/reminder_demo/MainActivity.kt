package com.example.reminder_demo

import android.media.RingtoneManager
import android.net.Uri
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File

private const val SYSTEM_ALARM_CHANNEL = "reminder_demo/system_alarms"

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
	}

	private fun copySystemAlarmTones(): List<String> {
		val outputDirectory = File(filesDir, "ReminderApp/SystemTones")
		if (!outputDirectory.exists()) outputDirectory.mkdirs()

		val ringtoneManager = RingtoneManager(this)
		ringtoneManager.setType(RingtoneManager.TYPE_ALARM)
		val cursor = ringtoneManager.cursor ?: return emptyList()
		val copied = mutableListOf<String>()

		cursor.use {
			while (it.moveToNext()) {
				val title = it.getString(RingtoneManager.TITLE_COLUMN_INDEX) ?: "alarm"
				val uri = ringtoneManager.getRingtoneUri(it.position) ?: continue
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
		return copied
	}

	private fun extensionFor(uri: Uri): String {
		val lastSegment = uri.lastPathSegment ?: return ".ogg"
		val dot = lastSegment.lastIndexOf('.')
		return if (dot >= 0) lastSegment.substring(dot) else ".ogg"
	}
}
