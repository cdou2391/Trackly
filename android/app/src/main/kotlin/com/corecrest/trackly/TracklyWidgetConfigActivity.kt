package com.corecrest.trackly

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.SeekBar
import android.widget.TextView

/**
 * Shown when the widget is added (and when it is reconfigured): pick the
 * background colour and how glassy it is. Built in code to stay dependency-free.
 */
class TracklyWidgetConfigActivity : Activity() {

    private var widgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private var color: Int? = null
    private var glass = WidgetStyle.DEFAULT_GLASS

    private val swatches = mutableListOf<Pair<View, Int?>>()
    private lateinit var previewTint: View
    private lateinit var previewText: TextView
    private lateinit var glassLabel: TextView

    private val presets = listOf(
        null, // Auto
        Color.parseColor("#0B121C"), Color.parseColor("#1D3557"),
        Color.parseColor("#2D6A4F"), Color.parseColor("#6D2E46"),
        Color.parseColor("#C99A3D"), Color.parseColor("#FFFFFF"),
        Color.parseColor("#F4EFE6"), Color.parseColor("#475569"),
        Color.parseColor("#000000"),
    )

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Cancelled unless the user saves, so the widget is not added.
        setResult(RESULT_CANCELED)

        widgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val current = WidgetStyle.load(this, widgetId)
        color = current.color
        glass = current.glass

        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(24), dp(24), dp(16))
        }

        column.addView(TextView(this).apply {
            text = getString(R.string.widget_config_title)
            textSize = 20f
            setTextColor(Color.parseColor("#0B1322"))
            setTypeface(typeface, android.graphics.Typeface.BOLD)
        })

        // Preview: the chosen tint over a colourful strip, so the glass shows.
        val preview = FrameLayout(this).apply {
            background = GradientDrawable(
                GradientDrawable.Orientation.LEFT_RIGHT,
                intArrayOf(Color.parseColor("#E8B04A"), Color.parseColor("#4A86D8"),
                    Color.parseColor("#3FB488")),
            ).apply { cornerRadius = dp(18).toFloat() }
        }
        previewTint = View(this)
        previewText = TextView(this).apply {
            text = getString(R.string.widget_config_preview)
            textSize = 16f
            gravity = Gravity.CENTER
            setTypeface(typeface, android.graphics.Typeface.BOLD)
        }
        preview.addView(previewTint, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT))
        preview.addView(previewText, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT))
        column.addView(preview, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, dp(84)).apply { topMargin = dp(16) })

        // Swatches, two rows of five.
        val rows = presets.chunked(5)
        for (row in rows) {
            val line = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
            for (c in row) line.addView(makeSwatch(c))
            column.addView(line, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT).apply { topMargin = dp(14) })
        }

        // Glass level.
        glassLabel = TextView(this).apply {
            textSize = 14f
            setTextColor(Color.parseColor("#4A5568"))
        }
        column.addView(glassLabel, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT).apply { topMargin = dp(20) })
        column.addView(SeekBar(this).apply {
            max = 80 // 20%..100%
            progress = ((glass * 100).toInt() - 20).coerceIn(0, 80)
            setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(s: SeekBar?, p: Int, fromUser: Boolean) {
                    glass = (p + 20) / 100f
                    refresh()
                }
                override fun onStartTrackingTouch(s: SeekBar?) {}
                override fun onStopTrackingTouch(s: SeekBar?) {}
            })
        })

        column.addView(Button(this).apply {
            text = getString(R.string.widget_config_save)
            setOnClickListener { save() }
        }, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT).apply { topMargin = dp(16) })

        setContentView(ScrollView(this).apply { addView(column) })

        // The dialog theme wraps its content narrowly, which squeezes the
        // swatches: give it nearly the full width, with rounded corners.
        val width = (resources.displayMetrics.widthPixels * 0.92f).toInt().coerceAtMost(dp(420))
        window.setLayout(width, android.view.ViewGroup.LayoutParams.WRAP_CONTENT)
        window.setBackgroundDrawable(
            GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadius = dp(28).toFloat()
            },
        )
        refresh()
    }

    private fun makeSwatch(c: Int?): View {
        val size = dp(44)
        val holder = FrameLayout(this)
        val dot = TextView(this).apply {
            gravity = Gravity.CENTER
            textSize = 12f
            if (c == null) {
                text = getString(R.string.widget_config_auto)
                setTextColor(Color.WHITE)
            }
            setOnClickListener {
                color = c
                refresh()
            }
        }
        holder.addView(dot, FrameLayout.LayoutParams(size, size, Gravity.CENTER))
        swatches.add(dot to c)
        return holder.also {
            it.layoutParams = LinearLayout.LayoutParams(0, dp(52), 1f)
        }
    }

    private fun refresh() {
        val style = WidgetStyle(color, glass)
        val palette = style.palette(this)

        // Swatch faces, with a ring around the chosen one.
        val chosen = color
        for ((view, c) in swatches) {
            val face = c ?: Color.parseColor("#0B121C")
            val selected = c == chosen
            view.background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(face)
                setStroke(
                    if (selected) dp(3) else dp(1),
                    if (selected) Color.parseColor("#C99A3D") else Color.parseColor("#33000000"),
                )
            }
        }

        previewTint.background = GradientDrawable().apply {
            cornerRadius = dp(18).toFloat()
            setColor(palette.background)
            alpha = (glass * 255).toInt()
            setStroke(dp(1), Color.parseColor("#66FFFFFF"))
        }
        previewText.setTextColor(palette.primary)
        glassLabel.text = "${getString(R.string.widget_config_glass)}  ${(glass * 100).toInt()}%"
    }

    private fun save() {
        WidgetStyle.save(this, widgetId, WidgetStyle(color, glass))
        TracklyWidgetProvider.refresh(this, intArrayOf(widgetId))
        setResult(
            RESULT_OK,
            Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId),
        )
        finish()
    }
}
