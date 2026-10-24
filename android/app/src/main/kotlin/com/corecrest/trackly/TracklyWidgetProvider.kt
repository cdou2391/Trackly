package com.corecrest.trackly

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.time.LocalDate
import java.time.temporal.ChronoUnit

/**
 * Home-screen widget: the next upcoming payment, its amount and the days left.
 *
 * The app writes the name, amount and due date; the days left are counted
 * here, so the widget stays correct after midnight even if the app is closed.
 */
class TracklyWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, buildViews(context, widgetData, id))
        }
    }

    // A new day (or a clock/time-zone change) changes the days left.
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> {
                val manager = AppWidgetManager.getInstance(context)
                val ids = manager.getAppWidgetIds(ComponentName(context, javaClass))
                if (ids.isNotEmpty()) {
                    onUpdate(
                        context,
                        manager,
                        ids,
                        es.antonborri.home_widget.HomeWidgetPlugin.getData(context),
                    )
                }
            }
            else -> super.onReceive(context, intent)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        WidgetStyle.delete(context, appWidgetIds)
        super.onDeleted(context, appWidgetIds)
    }

    internal fun buildViews(context: Context, data: SharedPreferences, widgetId: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.trackly_widget)
        val style = WidgetStyle.load(context, widgetId)
        val palette = style.palette(context)

        // Glass: the chosen colour, translucent, under the sheen.
        views.setInt(R.id.widget_bg, "setColorFilter", palette.background)
        views.setFloat(R.id.widget_bg, "setAlpha", style.glass)
        views.setTextColor(R.id.widget_label, palette.secondary)
        views.setTextColor(R.id.widget_name, palette.primary)
        views.setTextColor(R.id.widget_date, palette.secondary)
        views.setTextColor(R.id.widget_amount, palette.accent)

        val name = data.getString("widget_name", null)
        val due = data.getString("widget_due", null)?.let {
            try {
                LocalDate.parse(it)
            } catch (e: Exception) {
                null
            }
        }

        if (name == null || due == null) {
            views.setTextViewText(R.id.widget_name, context.getString(R.string.widget_empty_title))
            // The date sits beside the label, so the empty hint takes the label's place.
            views.setTextViewText(R.id.widget_label, context.getString(R.string.widget_empty_body))
            views.setViewVisibility(R.id.widget_date, View.GONE)
            views.setViewVisibility(R.id.widget_row, View.GONE)
        } else {
            val days = ChronoUnit.DAYS.between(LocalDate.now(), due).toInt()
            val overdue = days < 0

            views.setTextViewText(R.id.widget_name, name)
            views.setTextViewText(R.id.widget_amount, data.getString("widget_amount", "") ?: "")
            views.setTextViewText(R.id.widget_days, daysText(context, days))
            views.setTextViewText(R.id.widget_date, data.getString("widget_due_label", "") ?: "")
            views.setViewVisibility(R.id.widget_row, View.VISIBLE)
            views.setViewVisibility(R.id.widget_date, View.VISIBLE)
            val chip = if (overdue) palette.overdue else palette.accent
            views.setTextColor(R.id.widget_days, chip)
        }

        // Tapping anywhere opens the app.
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
        if (launch != null) {
            val pending = PendingIntent.getActivity(
                context,
                0,
                launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pending)
        }
        return views
    }

    private fun daysText(context: Context, days: Int): String = when {
        days == 0 -> context.getString(R.string.widget_due_today)
        days == 1 -> context.getString(R.string.widget_due_tomorrow)
        days > 1 -> context.resources.getQuantityString(R.plurals.widget_in_days, days, days)
        else -> context.resources.getQuantityString(
            R.plurals.widget_overdue_days,
            -days,
            -days,
        )
    }

    companion object {
        /** Redraws the given widgets, for example after their style changed. */
        fun refresh(context: Context, ids: IntArray) {
            val manager = AppWidgetManager.getInstance(context)
            val data = es.antonborri.home_widget.HomeWidgetPlugin.getData(context)
            for (id in ids) {
                manager.updateAppWidget(id, TracklyWidgetProvider().buildViews(context, data, id))
            }
        }
    }
}
