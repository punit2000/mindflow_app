package com.antigravity.flow_notes_reminders

import android.content.Context
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import org.json.JSONArray
import java.time.OffsetDateTime
import java.time.format.DateTimeFormatter
import java.time.format.DateTimeParseException

/** Minimal data object for a reminder surfaced on the home screen widget. */
private data class WidgetReminder(val title: String, val time: String)

class MindFlowWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val reminders = loadUpcomingReminders(context)

        provideContent {
            Column(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .background(ColorProvider(Color(0xFF546E7A)))
                    .padding(14.dp),
                verticalAlignment = Alignment.Top,
            ) {
                Text(
                    text = "MindFlow",
                    style = TextStyle(
                        color = ColorProvider(Color.White),
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                )
                if (reminders.isEmpty()) {
                    Text(
                        text = "No upcoming reminders",
                        style = TextStyle(
                            color = ColorProvider(Color(0xFFE2E8F0)),
                            fontSize = 13.sp,
                        ),
                        modifier = GlanceModifier.padding(top = 8.dp),
                    )
                } else {
                    reminders.take(4).forEach { reminder ->
                        Text(
                            text = "${reminder.time}  ${reminder.title}",
                            maxLines = 1,
                            style = TextStyle(
                                color = ColorProvider(Color.White),
                                fontSize = 13.sp,
                            ),
                            modifier = GlanceModifier
                                .fillMaxWidth()
                                .padding(top = 6.dp),
                        )
                    }
                }
            }
        }
    }

    private fun loadUpcomingReminders(context: Context): List<WidgetReminder> {
        return try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val raw = prefs.getString("flutter.flow_reminders_data_v1", null) ?: return emptyList()
            val array = JSONArray(raw)
            val now = OffsetDateTime.now()
            val fmt = DateTimeFormatter.ofPattern("h:mm a")

            val result = mutableListOf<WidgetReminder>()
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                if (obj.optBoolean("isCompleted", false)) continue
                if (!obj.optBoolean("isActive", true)) continue
                val scheduledRaw = obj.optString("scheduledTime", "")
                val parsed = tryParse(scheduledRaw) ?: continue
                if (parsed.isBefore(now.minusHours(1))) continue
                val title = obj.optString("title", "Reminder")
                result.add(WidgetReminder(title, parsed.format(fmt)))
            }
            result.sortedBy { it.time }.take(6)
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun tryParse(value: String): OffsetDateTime? {
        return try {
            OffsetDateTime.parse(value)
        } catch (e: DateTimeParseException) {
            try {
                val local = java.time.LocalDateTime.parse(value)
                local.atOffset(OffsetDateTime.now().offset)
            } catch (_: Exception) {
                null
            }
        }
    }
}

class MindFlowWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = MindFlowWidget()
}