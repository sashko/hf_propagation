package ua.rv.sashko.hf_propagation

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.ListenableWorker
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequest
import androidx.work.PeriodicWorkRequest
import androidx.work.WorkManager
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.concurrent.TimeUnit

/** Shared sync scheduling and update plumbing for the HF and VHF widgets. */
abstract class SyncedWidgetProvider(
    private val workerClass: Class<out ListenableWorker>,
    syncPrefix: String,
) : HomeWidgetProvider() {
  private val immediateSyncName = "$syncPrefix-on-widget-add"
  private val periodicSyncName = "$syncPrefix-periodic"

  protected abstract fun buildViews(context: Context, widgetData: SharedPreferences): RemoteViews

  override fun onEnabled(context: Context) {
    super.onEnabled(context)
    scheduleSync(context)
  }

  override fun onDisabled(context: Context) {
    super.onDisabled(context)
    WorkManager.getInstance(context).cancelUniqueWork(periodicSyncName)
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
    // ensured here too. Enqueueing is idempotent (KEEP), so this is a cheap no-op
    // once sync is already scheduled.
    scheduleSync(context)

    val views = buildViews(context, widgetData)
    for (appWidgetId in appWidgetIds) {
      appWidgetManager.updateAppWidget(appWidgetId, views)
    }
  }

  fun updateAllWidgets(context: Context) {
    val appWidgetManager = AppWidgetManager.getInstance(context)
    val widgetData = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
    val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, this::class.java))
    val views = buildViews(context, widgetData)
    for (id in ids) {
      appWidgetManager.updateAppWidget(id, views)
    }
  }

  protected fun launchAppIntent(context: Context): PendingIntent =
      PendingIntent.getActivity(
          context,
          0,
          Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
          },
          PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
      )

  private fun scheduleSync(context: Context) {
    val constraints = Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build()
    val workManager = WorkManager.getInstance(context)

    workManager.enqueueUniqueWork(
        immediateSyncName,
        ExistingWorkPolicy.KEEP,
        OneTimeWorkRequest.Builder(workerClass).setConstraints(constraints).build(),
    )

    workManager.enqueueUniquePeriodicWork(
        periodicSyncName,
        ExistingPeriodicWorkPolicy.KEEP,
        PeriodicWorkRequest.Builder(workerClass, 1, TimeUnit.HOURS)
            .setConstraints(constraints)
            .build(),
    )
  }
}
