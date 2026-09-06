package com.gdelataillade.alarm.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONObject

internal object AlarmScheduleStore {
    private const val preferencesName = "alarm_boot_schedule"
    private const val idsKey = "ids"

    fun save(context: Context, id: Int, triggerTime: Long, intent: Intent) {
        val values = JSONObject().apply {
            put("triggerTime", triggerTime)
            put("assetAudioPath", intent.getStringExtra("assetAudioPath"))
            put("loopAudio", intent.getBooleanExtra("loopAudio", true))
            put("vibrate", intent.getBooleanExtra("vibrate", true))
            put("volume", intent.getDoubleExtra("volume", -1.0))
            put("fadeDuration", intent.getDoubleExtra("fadeDuration", 0.0))
            put("notificationTitle", intent.getStringExtra("notificationTitle"))
            put("notificationBody", intent.getStringExtra("notificationBody"))
            put("fullScreenIntent", intent.getBooleanExtra("fullScreenIntent", true))
            put("ringDurationSeconds", intent.getIntExtra("ringDurationSeconds", 0))
            put("snoozeDelaySeconds", intent.getIntExtra("snoozeDelaySeconds", 0))
            put("remainingRings", intent.getIntExtra("remainingRings", 1))
        }
        val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        val ids = preferences.getStringSet(idsKey, emptySet())!!.toMutableSet().apply {
            add(id.toString())
        }
        preferences.edit()
            .putStringSet(idsKey, ids)
            .putString(id.toString(), values.toString())
            .apply()
    }

    fun remove(context: Context, id: Int) {
        val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        val ids = preferences.getStringSet(idsKey, emptySet())!!.toMutableSet().apply {
            remove(id.toString())
        }
        preferences.edit()
            .putStringSet(idsKey, ids)
            .remove(id.toString())
            .apply()
    }

    fun rescheduleFutureAlarms(context: Context) {
        val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        val ids = preferences.getStringSet(idsKey, emptySet())!!.toSet()
        for (idText in ids) {
            val id = idText.toIntOrNull() ?: continue
            val values = preferences.getString(idText, null) ?: continue
            try {
                val alarm = JSONObject(values)
                val triggerTime = alarm.getLong("triggerTime")
                if (triggerTime <= System.currentTimeMillis()) {
                    remove(context, id)
                    continue
                }
                val intent = Intent(context, AlarmReceiver::class.java).apply {
                    putExtra("id", id)
                    putExtra("assetAudioPath", alarm.optString("assetAudioPath"))
                    putExtra("loopAudio", alarm.optBoolean("loopAudio", true))
                    putExtra("vibrate", alarm.optBoolean("vibrate", true))
                    putExtra("volume", alarm.optDouble("volume", -1.0))
                    putExtra("fadeDuration", alarm.optDouble("fadeDuration", 0.0))
                    putExtra("notificationTitle", alarm.optString("notificationTitle"))
                    putExtra("notificationBody", alarm.optString("notificationBody"))
                    putExtra("fullScreenIntent", alarm.optBoolean("fullScreenIntent", true))
                    putExtra("ringDurationSeconds", alarm.optInt("ringDurationSeconds", 0))
                    putExtra("snoozeDelaySeconds", alarm.optInt("snoozeDelaySeconds", 0))
                    putExtra("remainingRings", alarm.optInt("remainingRings", 1))
                }
                schedule(context, id, triggerTime, intent)
            } catch (_: Exception) {
                remove(context, id)
            }
        }
    }

    fun schedule(context: Context, id: Int, triggerTime: Long, intent: Intent) {
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
        } else {
            alarmManager.set(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
        }
    }
}