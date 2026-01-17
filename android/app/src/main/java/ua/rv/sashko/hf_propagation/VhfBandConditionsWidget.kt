package ua.rv.sashko.hf_propagation

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class VhfBandConditionsWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (appWidgetId in appWidgetIds) {
            val views =
                RemoteViews(context.packageName, R.layout.vhf_band_conditions_widget).apply {
                    // Get data from Flutter
                    val auroraLatString = widgetData.getString("auroraLat", null)
                    val aurora = widgetData.getString("aurora", "N/A")
                    val es6mEurope = widgetData.getString("es6mEurope", "N/A")
                    val es4mEurope = widgetData.getString("es4mEurope", "N/A")
                    val es2mEurope = widgetData.getString("es2mEurope", "N/A")
                    val es2mNorthAmerica = widgetData.getString("es2mNorthAmerica", "N/A")

                    // Format Aurora Lat value
                    val auroraLatValue = auroraLatString?.toDoubleOrNull()
                    val auroraLatText =
                        if (auroraLatValue != null) "%.1f°".format(auroraLatValue) else "N/A"

                    // Set text values
                    setTextViewText(R.id.auroraLat_text, auroraLatText)
                    setTextViewText(R.id.aurora_text, aurora)
                    setTextViewText(R.id.es6mEurope_text, es6mEurope)
                    setTextViewText(R.id.es4mEurope_text, es4mEurope)
                    setTextViewText(R.id.es2mEurope_text, es2mEurope)
                    setTextViewText(R.id.es2mNorthAmerica_text, es2mNorthAmerica)

                    // Set text colors
                    val auroraLatColor = getAuroraLatColor(auroraLatString)
                    setTextColor(R.id.auroraLat_text, auroraLatColor)
                    setTextColor(R.id.aurora_text, getColorForCondition(aurora ?: "N/A"))
                    setTextColor(R.id.es6mEurope_text, getColorForCondition(es6mEurope ?: "N/A"))
                    setTextColor(R.id.es4mEurope_text, getColorForCondition(es4mEurope ?: "N/A"))
                    setTextColor(R.id.es2mEurope_text, getColorForCondition(es2mEurope ?: "N/A"))
                    setTextColor(
                        R.id.es2mNorthAmerica_text,
                        getColorForCondition(es2mNorthAmerica ?: "N/A"),
                    )
                }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun getAuroraLatColor(auroraLatString: String?): Int {
        val value = auroraLatString?.toDoubleOrNull()
        return when {
            value == null -> Color.WHITE
            value >= 60.0 -> Color.parseColor("#D32F2F") // red
            value >= 40.0 -> Color.parseColor("#FFA000") // amber
            else -> Color.parseColor("#43A047") // green
        }
    }

    private fun getColorForCondition(condition: String): Int {
        return when (condition.trim()) {
            "Good",
            "MID LAT AUR",
            "50MHz ES",
            "70MHz ES",
            "144MHz ES" -> Color.parseColor("#43A047") // green
            "Fair",
            "High LAT AUR",
            "High MUF (2M only)",
            "High MUF" -> Color.parseColor("#FFA000") // amber
            "Poor",
            "Band Closed" -> Color.parseColor("#D32F2F") // red
            else -> Color.WHITE
        }
    }
}
