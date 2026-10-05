package ua.rv.sashko.hf_propagation

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import androidx.core.content.ContextCompat

class HfBandConditionsWidget : SyncedWidgetProvider(HfSyncWorker::class.java, "hf-sync") {
  override fun buildViews(context: Context, widgetData: SharedPreferences): RemoteViews {
    return RemoteViews(context.packageName, R.layout.hf_band_conditions_widget).apply {
      setOnClickPendingIntent(R.id.widget_container, launchAppIntent(context))

      val updated = widgetData.getString("hf_updated", "N/A")
      setTextViewText(R.id.updated_text, updated)

      val bands =
          listOf(
              Triple("hf_80m40m", R.id.band_80m40m_day, R.id.band_80m40m_night),
              Triple("hf_30m20m", R.id.band_30m20m_day, R.id.band_30m20m_night),
              Triple("hf_17m15m", R.id.band_17m15m_day, R.id.band_17m15m_night),
              Triple("hf_12m10m", R.id.band_12m10m_day, R.id.band_12m10m_night),
          )

      for ((key, dayId, nightId) in bands) {
        val day = widgetData.getString("${key}_day", "N/A") ?: "N/A"
        val night = widgetData.getString("${key}_night", "N/A") ?: "N/A"
        setTextViewText(dayId, day)
        setTextViewText(nightId, night)
        setTextColor(dayId, getColorForCondition(context, day))
        setTextColor(nightId, getColorForCondition(context, night))
      }
    }
  }

  companion object {
    private fun getColorForCondition(context: Context, condition: String): Int {
      val colorRes =
          when (condition.trim()) {
            "Good" -> R.color.condition_good
            "Fair" -> R.color.condition_fair
            "Poor",
            "Band Closed" -> R.color.condition_poor
            else -> return Color.WHITE
          }
      return ContextCompat.getColor(context, colorRes)
    }
  }
}
