package ua.rv.sashko.hf_propagation

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import java.net.HttpURLConnection
import java.net.URL
import javax.xml.parsers.DocumentBuilderFactory
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.w3c.dom.Element

class HfSyncWorker(
    context: Context,
    params: WorkerParameters,
) : CoroutineWorker(context, params) {
  override suspend fun doWork(): Result =
      withContext(Dispatchers.IO) {
        try {
          val values = parseHfValues(fetchXml())
          saveToWidgetPreferences(values)
          HfBandConditionsWidget.updateAllWidgets(applicationContext)
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

  private fun parseHfValues(xml: String): Map<String, String?> {
    val document =
        DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(xml.byteInputStream())
    document.documentElement.normalize()

    val updated = document.getElementsByTagName("updated").item(0)?.textContent?.trim()

    val result = mutableMapOf<String, String?>("hf_updated" to updated)

    val bands = document.getElementsByTagName("band")
    for (i in 0 until bands.length) {
      val node = bands.item(i) as? Element ?: continue
      val name = node.getAttribute("name") ?: continue
      val time = node.getAttribute("time") ?: continue
      val condition = node.textContent.trim()

      val key =
          when (name) {
            "80m-40m" -> "hf_80m40m"
            "30m-20m" -> "hf_30m20m"
            "17m-15m" -> "hf_17m15m"
            "12m-10m" -> "hf_12m10m"
            else -> continue
          }

      result["${key}_$time"] = condition
    }

    return result
  }

  private fun saveToWidgetPreferences(values: Map<String, String?>) {
    val prefs =
        applicationContext.getSharedPreferences(HOME_WIDGET_PREFERENCES, Context.MODE_PRIVATE)
    prefs
        .edit()
        .apply { values.forEach { (key, value) -> if (value != null) putString(key, value) } }
        .apply()
  }

  companion object {
    private const val SOLAR_XML_URL = "https://www.hamqsl.com/solarxml.php"
    private const val HOME_WIDGET_PREFERENCES = "HomeWidgetPreferences"
  }
}
