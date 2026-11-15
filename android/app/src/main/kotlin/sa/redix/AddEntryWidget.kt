package sa.redix

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import androidx.core.widget.RemoteViewsCompat
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject

/**
 * The home-screen widget «إضافة قيد» (redix-app #86 D5, D8 to D10): the button on top, and under it the latest entries the app read, with when. The app saves every word
 * and link it shows through home_widget (LauncherAddEntry), so the widget holds no word of its own. The button opens the app's one link, /add-entry, and a row its
 * entry's own link, as a link tapped anywhere else would; with no rows, after signing out, it shows the button alone.
 */
class AddEntryWidget : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            appWidgetManager.updateAppWidget(appWidgetId, viewsOf(context, appWidgetId, widgetData))
        }
    }

    private fun viewsOf(context: Context, appWidgetId: Int, widgetData: SharedPreferences): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.add_entry_widget)
        views.setTextViewText(R.id.add_entry_label, widgetData.getString("addEntryLabel", ""))
        views.setOnClickPendingIntent(R.id.add_entry, PendingIntent.getActivity(context, 0, opening(context, widgetData.getString("addEntryLink", "").orEmpty()), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))

        val entries = JSONArray(widgetData.getString("addEntryEntries", null) ?: "[]")
        val rows = RemoteViewsCompat.RemoteCollectionItems.Builder().setViewTypeCount(1)
        for (index in 0 until entries.length()) {
            rows.addItem(index.toLong(), rowOf(context, entries.getJSONObject(index)))
        }
        RemoteViewsCompat.setRemoteAdapter(context, views, appWidgetId, R.id.entries, rows.build())
        views.setPendingIntentTemplate(R.id.entries, PendingIntent.getActivity(context, 1, opening(context), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE))
        views.setTextViewText(R.id.read_at, widgetData.getString("addEntryReadAt", ""))
        val shown = if (entries.length() == 0) View.GONE else View.VISIBLE
        views.setViewVisibility(R.id.entries, shown)
        views.setViewVisibility(R.id.read_at, shown)
        return views
    }

    /** One entry as its card says it: its title, its details line and its amount; a tap fills the list's template with the entry's link. */
    private fun rowOf(context: Context, entry: JSONObject): RemoteViews {
        val row = RemoteViews(context.packageName, R.layout.entry_widget_row)
        row.setTextViewText(R.id.entry_title, entry.getString("title"))
        row.setTextViewText(R.id.entry_details, entry.getString("details"))
        row.setTextViewText(R.id.entry_amount, entry.getString("amount"))
        row.setOnClickFillInIntent(R.id.entry_row, Intent().setData(Uri.parse(entry.getString("link"))))
        return row
    }

    /** The app opened on [link], the way a link reaches it (redix-app #83); with none, as the list's template a row fills or before the app has saved the button's, as its icon opens it. */
    private fun opening(context: Context, link: String = ""): Intent {
        val intent = Intent(context, MainActivity::class.java).setAction(Intent.ACTION_VIEW)
        if (link.isNotEmpty()) {
            intent.data = Uri.parse(link)
        }
        return intent
    }
}
