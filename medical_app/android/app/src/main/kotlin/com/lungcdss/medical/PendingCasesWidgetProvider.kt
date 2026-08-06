package com.lungcdss.medical

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * 검토대기 건수를 홈스크린에 보여주는 위젯. Flutter(HomeWidgetService)가 로그인 상태에서 케이스
 * 목록을 새로고침할 때마다 pending_count/urgent_count를 저장 + updateWidget을 호출해서 갱신한다.
 */
class PendingCasesWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val pendingCount = widgetData.getInt("pending_count", 0)
            val urgentCount = widgetData.getInt("urgent_count", 0)

            val views = RemoteViews(context.packageName, R.layout.pending_cases_widget).apply {
                setTextViewText(R.id.widget_count, "${pendingCount}건")
                if (urgentCount > 0) {
                    setTextViewText(R.id.widget_urgent, "긴급 ${urgentCount}건 포함")
                    setViewVisibility(R.id.widget_urgent, android.view.View.VISIBLE)
                } else {
                    setViewVisibility(R.id.widget_urgent, android.view.View.GONE)
                }

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
