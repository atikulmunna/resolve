package com.app.resolve

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.SweepGradient
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.TypedValue
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import kotlin.math.roundToInt

/// Home-screen widget for Resolve. Computes the day count and milestone ring in
/// Kotlin from the pushed `startedAt`, so it stays correct while the app is
/// closed (the app's "streak = now() - startedAt" rule). It picks one of three
/// layouts based on the size the user drags to, follows the system light/dark
/// theme (via resource qualifiers + a themed ring), and its PANIC pill deep-links
/// straight into the breathing tool.
class ResolveWidgetProvider : HomeWidgetProvider() {

    private val milestones = longArrayOf(30, 60, 90)

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (id in appWidgetIds) {
            render(context, appWidgetManager, id, widgetData)
        }
    }

    // Re-render a single widget when the user resizes it, so the layout tracks
    // the new dimensions.
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        render(context, appWidgetManager, appWidgetId, HomeWidgetPlugin.getData(context))
    }

    private fun render(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences
    ) {
        val startedAtMs = widgetData.getString("startedAtMs", null)?.toLongOrNull()
        val name = widgetData.getString("habitName", null)?.ifBlank { null } ?: "Resolve"

        val days: Long = if (startedAtMs != null && startedAtMs > 0L) {
            val elapsed = System.currentTimeMillis() - startedAtMs
            if (elapsed < 0L) 0L else elapsed / 86_400_000L
        } else {
            0L
        }

        // Ring fills toward the next milestone; full once all are cleared.
        val next = milestones.firstOrNull { days < it }
        val progress = if (next == null) 1f else (days.toFloat() / next.toFloat())

        val night = (context.resources.configuration.uiMode and
            Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

        val options = appWidgetManager.getAppWidgetOptions(widgetId)
        val minW = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0).toFloat()
        val minH = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0).toFloat()
        val density = context.resources.displayMetrics.density

        val layoutId = pickLayout(minW, minH)
        val views = RemoteViews(context.packageName, layoutId)

        // Day number, present in every layout.
        views.setTextViewText(R.id.widget_days, days.toString())

        // Text + ring scale with the widget's actual size so it fills the space.
        when (layoutId) {
            R.layout.widget_small -> {
                views.setTextViewText(
                    R.id.widget_days_label,
                    if (days == 1L) "DAY FREE" else "DAYS FREE"
                )
                val s = minOf(minW, minH).coerceAtLeast(80f)
                setSp(views, R.id.widget_days, (s * 0.44f).coerceIn(30f, 104f))
                setSp(views, R.id.widget_days_label, (s * 0.10f).coerceIn(9f, 18f))
                setSp(views, R.id.widget_streak_label, (s * 0.085f).coerceIn(8f, 14f))
            }
            R.layout.widget_wide -> {
                views.setTextViewText(R.id.widget_days_label, "DAYS")
                views.setTextViewText(R.id.widget_name, name)
                views.setOnClickPendingIntent(R.id.widget_panic, panicIntent(context))

                val ringDp = (minH - 30f).coerceIn(56f, 156f)
                val ringPx = (ringDp * density).roundToInt().coerceAtMost(440)
                views.setImageViewBitmap(R.id.widget_ring, ringBitmap(ringPx, progress, night))
                setBoxSize(views, R.id.widget_ring_box, ringDp)
                setSp(views, R.id.widget_days, ringDp * 0.34f)
                setSp(views, R.id.widget_days_label, (ringDp * 0.11f).coerceAtLeast(7f))
                setSp(views, R.id.widget_name, (minH * 0.14f).coerceIn(15f, 28f))
                setSp(views, R.id.widget_streak_label, (minH * 0.075f).coerceIn(8f, 12f))
                setSp(views, R.id.widget_panic_text, (minH * 0.08f).coerceIn(10f, 15f))
            }
            R.layout.widget_large -> {
                views.setTextViewText(R.id.widget_days_label, "DAYS")
                views.setTextViewText(R.id.widget_name, name.uppercase())
                views.setOnClickPendingIntent(R.id.widget_panic, panicIntent(context))

                val ringBoxDp = (minH - 96f).coerceIn(90f, 280f)
                val ringPx = (ringBoxDp * density).roundToInt().coerceAtMost(512)
                views.setImageViewBitmap(R.id.widget_ring, ringBitmap(ringPx, progress, night))
                setSp(views, R.id.widget_days, ringBoxDp * 0.30f)
                setSp(views, R.id.widget_days_label, (ringBoxDp * 0.085f).coerceIn(9f, 18f))
                setSp(views, R.id.widget_name, (minW * 0.05f).coerceIn(12f, 22f))
                setSp(views, R.id.widget_panic_text, (minW * 0.045f).coerceIn(12f, 17f))
            }
        }

        // Tapping anywhere else opens the app.
        views.setOnClickPendingIntent(
            R.id.widget_root,
            HomeWidgetLaunchIntent.getActivity(
                context, MainActivity::class.java, Uri.parse("resolve://open")
            )
        )

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun panicIntent(context: Context) =
        HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java, Uri.parse("resolve://panic")
        )

    // Choose a layout from the widget's current size (dp).
    private fun pickLayout(minW: Float, minH: Float): Int = when {
        minW >= 200 && minH >= 200 -> R.layout.widget_large
        minW >= 200 -> R.layout.widget_wide
        else -> R.layout.widget_small
    }

    private fun setSp(views: RemoteViews, id: Int, sp: Float) {
        views.setTextViewTextSize(id, TypedValue.COMPLEX_UNIT_SP, sp)
    }

    // Resize a view's layout box (API 31+); on older Androids the XML default
    // size stands.
    private fun setBoxSize(views: RemoteViews, id: Int, dp: Float) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            views.setViewLayoutWidth(id, dp, TypedValue.COMPLEX_UNIT_DIP)
            views.setViewLayoutHeight(id, dp, TypedValue.COMPLEX_UNIT_DIP)
        }
    }

    // The 60-second-style ring, drawn to a bitmap: a faint full track plus a
    // glowing emerald progress arc from the top, clockwise. Themed track.
    private fun ringBitmap(sizePx: Int, progress: Float, night: Boolean): Bitmap {
        val bmp = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val cx = sizePx / 2f
        val cy = sizePx / 2f
        val stroke = sizePx * 0.10f
        val pad = stroke / 2f + sizePx * 0.06f
        val rect = RectF(pad, pad, sizePx - pad, sizePx - pad)

        val track = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = stroke
            strokeCap = Paint.Cap.ROUND
            color = if (night) 0x1AFFFFFF else 0x14000000
        }
        canvas.drawArc(rect, 0f, 360f, false, track)

        if (progress > 0.001f) {
            val sweep = progress.coerceIn(0f, 1f) * 360f
            val grad = SweepGradient(
                cx, cy,
                intArrayOf(0xFF6EE7B7.toInt(), 0xFF10B981.toInt(), 0xFF059669.toInt()),
                floatArrayOf(0f, 0.5f, 0.86f)
            )
            grad.setLocalMatrix(Matrix().apply { setRotate(-90f, cx, cy) })
            val prog = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = stroke
                strokeCap = Paint.Cap.ROUND
                shader = grad
                setShadowLayer(sizePx * 0.05f, 0f, 0f, 0x8010B981.toInt())
            }
            canvas.drawArc(rect, -90f, sweep, false, prog)
        }
        return bmp
    }
}
