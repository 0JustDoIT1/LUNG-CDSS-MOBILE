package com.lungcdss.medical

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * 간호사용 — 예약요청 대기 건수를 홈스크린에 보여주는 위젯. Flutter(HomeWidgetService)가
 * 예약큐를 새로고침할 때마다 appointment_request_count를 저장 + updateWidget을 호출해서 갱신한다.
 */
class PendingAppointmentsWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val requestCount = widgetData.getInt("appointment_request_count", 0)

            val views = RemoteViews(context.packageName, R.layout.pending_cases_widget).apply {
                setTextViewText(R.id.widget_title, "예약요청 대기")
                setTextViewText(R.id.widget_count, "${requestCount}건")
                setViewVisibility(R.id.widget_urgent, android.view.View.GONE)

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
