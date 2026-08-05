package ua.rv.sashko.hf_propagation

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequest
import androidx.work.PeriodicWorkRequest
import androidx.work.WorkManager
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.concurrent.TimeUnit

class HfBandConditionsWidget : HomeWidgetProvider() {
  override fun onEnabled(context: Context) {
    super.onEnabled(context)
    scheduleSync(context)
  }

  override fun onDisabled(context: Context) {
    super.onDisabled(context)
    WorkManager.getInstance(context).cancelUniqueWork(PERIODIC_SYNC_NAME)
  }

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    scheduleSync(context)

    val views = buildViews(context, widgetData)
    for (appWidgetId in appWidgetIds) {
      appWidgetManager.updateAppWidget(appWidgetId, views)
    }
  }

  companion object {
    private const val IMMEDIATE_SYNC_NAME = "hf-sync-on-widget-add"
    private const val PERIODIC_SYNC_NAME = "hf-sync-periodic"

    private fun scheduleSync(context: Context) {
      val constraints = Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build()

      WorkManager.getInstance(context)
          .enqueueUniqueWork(
              IMMEDIATE_SYNC_NAME,
              ExistingWorkPolicy.KEEP,
              OneTimeWorkRequest.Builder(HfSyncWorker::class.java)
                  .setConstraints(constraints)
                  .build(),
          )

      WorkManager.getInstance(context)
          .enqueueUniquePeriodicWork(
              PERIODIC_SYNC_NAME,
              ExistingPeriodicWorkPolicy.KEEP,
              PeriodicWorkRequest.Builder(HfSyncWorker::class.java, 1, TimeUnit.HOURS)
                  .setConstraints(constraints)
                  .build(),
          )
    }

    fun updateAllWidgets(context: Context) {
      val appWidgetManager = AppWidgetManager.getInstance(context)
      val widgetData = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
      val ids =
          appWidgetManager.getAppWidgetIds(
              ComponentName(context, HfBandConditionsWidget::class.java)
          )
      val views = buildViews(context, widgetData)
      for (id in ids) {
        appWidgetManager.updateAppWidget(id, views)
      }
    }

    private fun buildViews(
        context: Context,
        widgetData: SharedPreferences,
    ): RemoteViews {
      val launchIntent =
          Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
          }
      val pendingIntent =
          PendingIntent.getActivity(
              context,
              1,
              launchIntent,
              PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
          )

      return RemoteViews(context.packageName, R.layout.hf_band_conditions_widget).apply {
        setOnClickPendingIntent(R.id.widget_container, pendingIntent)

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
          setTextColor(dayId, getColorForCondition(day))
          setTextColor(nightId, getColorForCondition(night))
        }
      }
    }

    private fun getColorForCondition(condition: String): Int {
      return when (condition.trim()) {
        "Good" -> Color.parseColor("#43A047")
        "Fair" -> Color.parseColor("#FFA000")
        "Poor",
        "Band Closed" -> Color.parseColor("#D32F2F")
        else -> Color.WHITE
      }
    }
  }
}
