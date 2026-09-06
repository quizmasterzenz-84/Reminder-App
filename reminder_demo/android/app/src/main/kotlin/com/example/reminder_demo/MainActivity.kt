package com.example.reminder_demo

import android.media.RingtoneManager
import android.net.Uri
import android.content.ContentValues
import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Environment
import android.provider.Settings
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File

private const val SYSTEM_ALARM_CHANNEL = "reminder_demo/system_alarms"
private const val AUDIO_EXPORT_CHANNEL = "reminder_demo/audio_export"
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

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_EXPORT_CHANNEL)
			.setMethodCallHandler { call, result ->
				if (call.method != "exportToPublicMusic") {
					result.notImplemented()
					return@setMethodCallHandler
				}
				try {
					val path = call.argument<String>("path")
					val displayName = call.argument<String>("displayName")
					if (path == null || displayName == null) {
						result.error("INVALID_AUDIO", "Audio path is missing", null)
					} else {
						result.success(exportToPublicMusic(path, displayName))
					}
				} catch (error: Exception) {
					result.error("AUDIO_EXPORT_FAILED", error.message, null)
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

	private fun exportToPublicMusic(path: String, displayName: String): Boolean {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
		val source = File(path)
		if (!source.exists()) return false
		val values = ContentValues().apply {
			put(MediaStore.Audio.Media.DISPLAY_NAME, displayName)
			put(MediaStore.Audio.Media.MIME_TYPE, mimeTypeFor(displayName))
			put(MediaStore.Audio.Media.RELATIVE_PATH, "${Environment.DIRECTORY_MUSIC}/ReminderApp")
			put(MediaStore.Audio.Media.IS_PENDING, 1)
		}
		val collection = MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
		val uri = contentResolver.insert(collection, values) ?: return false
		return try {
			contentResolver.openOutputStream(uri)?.use { output ->
				source.inputStream().use { input -> input.copyTo(output) }
			} ?: return false
			contentResolver.update(
				uri,
				ContentValues().apply { put(MediaStore.Audio.Media.IS_PENDING, 0) },
				null,
				null,
			)
			true
		} catch (error: Exception) {
			contentResolver.delete(uri, null, null)
			throw error
		}
	}

	private fun mimeTypeFor(name: String): String = when {
		name.endsWith(".m4a", ignoreCase = true) -> "audio/mp4"
		name.endsWith(".wav", ignoreCase = true) -> "audio/wav"
		else -> "audio/mp4"
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
