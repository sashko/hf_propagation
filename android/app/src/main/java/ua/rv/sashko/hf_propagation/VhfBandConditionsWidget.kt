package ua.rv.sashko.hf_propagation

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequest
import androidx.work.PeriodicWorkRequest
import androidx.work.WorkManager
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.concurrent.TimeUnit

class VhfBandConditionsWidget : HomeWidgetProvider() {
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
    // onEnabled() only fires when the first instance of this widget is added, so it
    // never re-runs for widgets that already existed before an app update. onUpdate()
    // does fire in that case (and periodically thereafter), so scheduling has to be
    // ensured here too — enqueueing is idempotent (KEEP), so this is a cheap no-op
    // once sync is already scheduled.
    scheduleSync(context)

    val views = buildViews(context, widgetData)
    for (appWidgetId in appWidgetIds) {
      appWidgetManager.updateAppWidget(appWidgetId, views)
    }
  }

  companion object {
    private const val IMMEDIATE_SYNC_NAME = "solar-sync-on-widget-add"
    private const val PERIODIC_SYNC_NAME = "solar-sync-periodic"

    private fun scheduleSync(context: Context) {
      val constraints = Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build()

      // Immediate fetch so the widget shows real data as soon as possible.
      WorkManager.getInstance(context)
          .enqueueUniqueWork(
              IMMEDIATE_SYNC_NAME,
              ExistingWorkPolicy.KEEP,
              OneTimeWorkRequest.Builder(VhfSyncWorker::class.java)
                  .setConstraints(constraints)
                  .build(),
          )

      // Recurring sync, scheduled natively so it works even if the Flutter app
      // (and its Dart-side scheduling) never runs on this install.
      WorkManager.getInstance(context)
          .enqueueUniquePeriodicWork(
              PERIODIC_SYNC_NAME,
              ExistingPeriodicWorkPolicy.KEEP,
              PeriodicWorkRequest.Builder(VhfSyncWorker::class.java, 1, TimeUnit.HOURS)
                  .setConstraints(constraints)
                  .build(),
          )
    }

    fun updateAllWidgets(context: Context) {
      val appWidgetManager = AppWidgetManager.getInstance(context)
      val widgetData = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
      val ids =
          appWidgetManager.getAppWidgetIds(
              ComponentName(context, VhfBandConditionsWidget::class.java)
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
              0,
              launchIntent,
              PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
          )

      return RemoteViews(context.packageName, R.layout.vhf_band_conditions_widget).apply {
        setOnClickPendingIntent(R.id.widget_container, pendingIntent)

        // Get data from widget SharedPreferences
        val auroraLatString = widgetData.getString("auroraLat", null)
        val aurora = widgetData.getString("aurora", "N/A")
        val es6mEurope = widgetData.getString("es6mEurope", "N/A")
        val es4mEurope = widgetData.getString("es4mEurope", "N/A")
        val es2mEurope = widgetData.getString("es2mEurope", "N/A")
        val es2mNorthAmerica = widgetData.getString("es2mNorthAmerica", "N/A")

        val auroraLatText =
            when {
              auroraLatString == "No Report" -> "No Report"
              auroraLatString?.toDoubleOrNull() != null ->
                  "%.1f°".format(auroraLatString.toDouble())
              else -> "N/A"
            }

        // Set text values
        setTextViewText(R.id.auroraLat_text, auroraLatText)
        setTextViewText(R.id.aurora_text, aurora)
        setTextViewText(R.id.es6mEurope_text, es6mEurope)
        setTextViewText(R.id.es4mEurope_text, es4mEurope)
        setTextViewText(R.id.es2mEurope_text, es2mEurope)
        setTextViewText(R.id.es2mNorthAmerica_text, es2mNorthAmerica)

        // Set text colors
        setTextColor(R.id.auroraLat_text, getAuroraLatColor(context, auroraLatString))
        setTextColor(R.id.aurora_text, getColorForCondition(context, aurora ?: "N/A"))
        setTextColor(R.id.es6mEurope_text, getColorForCondition(context, es6mEurope ?: "N/A"))
        setTextColor(R.id.es4mEurope_text, getColorForCondition(context, es4mEurope ?: "N/A"))
        setTextColor(R.id.es2mEurope_text, getColorForCondition(context, es2mEurope ?: "N/A"))
        setTextColor(
            R.id.es2mNorthAmerica_text,
            getColorForCondition(context, es2mNorthAmerica ?: "N/A"),
        )
      }
    }

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
