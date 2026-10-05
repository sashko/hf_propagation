package ua.rv.sashko.hf_propagation

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import androidx.core.content.ContextCompat

class VhfBandConditionsWidget : SyncedWidgetProvider(VhfSyncWorker::class.java, "solar-sync") {
  override fun buildViews(context: Context, widgetData: SharedPreferences): RemoteViews {
    return RemoteViews(context.packageName, R.layout.vhf_band_conditions_widget).apply {
      setOnClickPendingIntent(R.id.widget_container, launchAppIntent(context))

      val auroraLatString = widgetData.getString("auroraLat", null)
      val auroraLatText =
          when {
            auroraLatString == "No Report" -> "No Report"
            auroraLatString?.toDoubleOrNull() != null -> "%.1f°".format(auroraLatString.toDouble())
            else -> "N/A"
          }

      setTextViewText(R.id.auroraLat_text, auroraLatText)
      setTextColor(R.id.auroraLat_text, getAuroraLatColor(context, auroraLatString))

      for ((key, id) in
          listOf(
              "aurora" to R.id.aurora_text,
              "es6mEurope" to R.id.es6mEurope_text,
              "es4mEurope" to R.id.es4mEurope_text,
              "es2mEurope" to R.id.es2mEurope_text,
              "es2mNorthAmerica" to R.id.es2mNorthAmerica_text,
          )) {
        val value = widgetData.getString(key, "N/A") ?: "N/A"
        setTextViewText(id, value)
        setTextColor(id, getColorForCondition(context, value))
      }
    }
  }

  companion object {
    private fun getAuroraLatColor(context: Context, auroraLatString: String?): Int {
      val value = auroraLatString?.toDoubleOrNull()
      val colorRes =
          when {
            auroraLatString == "No Report" -> R.color.condition_poor
            value == null -> return Color.WHITE
            value >= 65.0 -> R.color.condition_poor
            value >= 60.0 -> R.color.condition_fair
            else -> R.color.condition_good
          }
      return ContextCompat.getColor(context, colorRes)
    }

    private fun getColorForCondition(context: Context, condition: String): Int {
      val colorRes =
          when (condition.trim()) {
            "Good",
            "MID LAT AUR",
            "50MHz ES",
            "70MHz ES",
            "144MHz ES" -> R.color.condition_good
            "Fair",
            "High LAT AUR",
            "High MUF (2M only)",
            "High MUF" -> R.color.condition_fair
            "Poor",
            "Band Closed" -> R.color.condition_poor
            else -> return Color.WHITE
          }
      return ContextCompat.getColor(context, colorRes)
    }
  }
}
