package ua.rv.sashko.hf_propagation

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.w3c.dom.Element
import java.net.HttpURLConnection
import java.net.URL
import javax.xml.parsers.DocumentBuilderFactory

/**
 * Fetches VHF band conditions natively and writes them straight to the widget's
 * SharedPreferences + RemoteViews. This has no dependency on the Flutter engine or
 * Dart callbacks, so it works even if the app has never been opened on this install.
 */
class VhfSyncWorker(
    context: Context,
    params: WorkerParameters,
) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result =
        withContext(Dispatchers.IO) {
            try {
                val values = parseVhfValues(fetchXml())
                saveToWidgetPreferences(values)
                VhfBandConditionsWidget.updateAllWidgets(applicationContext)
                Result.success()
            } catch (e: Exception) {
                Result.retry()
            }
        }

    private fun fetchXml(): String {
        val connection = URL(SOLAR_XML_URL).openConnection() as HttpURLConnection
        connection.connectTimeout = 15_000
        connection.readTimeout = 15_000
        return try {
            connection.inputStream.bufferedReader().use { it.readText() }
        } finally {
            connection.disconnect()
        }
    }

    private fun parseVhfValues(xml: String): Map<String, String?> {
        val document =
            DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(xml.byteInputStream())
        document.documentElement.normalize()

        val auroraLat = document.getElementsByTagName("latdegree").item(0)?.textContent?.trim()

        var aurora: String? = null
        var es6mEurope: String? = null
        var es4mEurope: String? = null
        var es2mEurope: String? = null
        var es2mNorthAmerica: String? = null

        val phenomena = document.getElementsByTagName("phenomenon")
        for (i in 0 until phenomena.length) {
            val node = phenomena.item(i) as? Element ?: continue
            val condition = node.textContent.trim()
            when (node.getAttribute("location")) {
                "northern_hemi" -> aurora = condition
                "europe" -> es2mEurope = condition
                "europe_4m" -> es4mEurope = condition
                "europe_6m" -> es6mEurope = condition
                "north_america" -> es2mNorthAmerica = condition
            }
        }

        return mapOf(
            "auroraLat" to auroraLat,
            "aurora" to aurora,
            "es6mEurope" to es6mEurope,
            "es4mEurope" to es4mEurope,
            "es2mEurope" to es2mEurope,
            "es2mNorthAmerica" to es2mNorthAmerica,
        )
    }

    private fun saveToWidgetPreferences(values: Map<String, String?>) {
        val prefs = applicationContext.getSharedPreferences(HOME_WIDGET_PREFERENCES, Context.MODE_PRIVATE)
        prefs.edit().apply {
            values.forEach { (key, value) -> if (value != null) putString(key, value) }
        }.apply()
    }

    companion object {
        private const val SOLAR_XML_URL = "https://www.hamqsl.com/solarxml.php"

        // Must match es.antonborri.home_widget.HomeWidgetPlugin.PREFERENCES so data saved
        // here is visible to HomeWidget.getWidgetData() if the Flutter app is ever opened.
        private const val HOME_WIDGET_PREFERENCES = "HomeWidgetPreferences"
    }
}
