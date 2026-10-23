package com.corecrest.trackly

import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Color

/** The look of one widget: its background colour and how glassy it is. */
data class WidgetStyle(
    /** Null means "Auto": follow the system light or dark mode. */
    val color: Int?,
    /** 0.2 (very see-through) to 1.0 (solid). */
    val glass: Float,
) {
    /** Colours for text and accents that stay readable on this background. */
    class Palette(
        val background: Int,
        val primary: Int,
        val secondary: Int,
        val accent: Int,
        val overdue: Int,
    )

    fun palette(context: Context): Palette {
        val bg = color ?: run {
            val night = context.resources.configuration.uiMode and
                Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES
            if (night) Color.parseColor("#0B121C") else Color.WHITE
        }
        val dark = luminance(bg) < 0.5
        return if (dark) {
            Palette(bg, Color.parseColor("#F3F4F3"), Color.parseColor("#C4D0DE"),
                Color.parseColor("#D7B987"), Color.parseColor("#E38B91"))
        } else {
            Palette(bg, Color.parseColor("#0B1322"), Color.parseColor("#4A5568"),
                Color.parseColor("#8F6A22"), Color.parseColor("#BF3037"))
        }
    }

    companion object {
        const val PREFS = "trackly_widget_style"
        const val DEFAULT_GLASS = 0.72f
        private const val AUTO = 0 // 0 is never a real opaque colour here

        fun luminance(c: Int): Double =
            (0.2126 * Color.red(c) + 0.7152 * Color.green(c) + 0.0722 * Color.blue(c)) / 255.0

        private fun prefs(context: Context): SharedPreferences =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        fun load(context: Context, widgetId: Int): WidgetStyle {
            val p = prefs(context)
            val stored = p.getInt("color_$widgetId", AUTO)
            return WidgetStyle(
                color = if (stored == AUTO) null else stored,
                glass = p.getFloat("glass_$widgetId", DEFAULT_GLASS),
            )
        }

        fun save(context: Context, widgetId: Int, style: WidgetStyle) {
            prefs(context).edit()
                .putInt("color_$widgetId", style.color ?: AUTO)
                .putFloat("glass_$widgetId", style.glass)
                .apply()
        }

        fun delete(context: Context, widgetIds: IntArray) {
            val e = prefs(context).edit()
            for (id in widgetIds) e.remove("color_$id").remove("glass_$id")
            e.apply()
        }
    }
}
