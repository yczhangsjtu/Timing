package com.yczhang.flutter_timing

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat;

import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

var methodChannel: MethodChannel? = null
var notificationChannel: NotificationChannel? = null
var notificationManager: NotificationManager? = null

class MainActivity: FlutterActivity() {
  private val CHANNEL = "notification_panel"
  private val NOTIFICATION_CHANNEL_ID = "timing_persistent"

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(this)
    notificationManager = getSystemService(NotificationManager::class.java)

    methodChannel = MethodChannel(flutterView, CHANNEL)
    methodChannel?.setMethodCallHandler {
      call, result ->
      if(call.method == "show") {
        if(notificationChannel == null) {
          notificationChannel = NotificationChannel(
                  NOTIFICATION_CHANNEL_ID,
                  NOTIFICATION_CHANNEL_ID,
                  NotificationManager.IMPORTANCE_HIGH)
          notificationChannel?.enableVibration(false)
          notificationChannel?.setSound(null, null)

          notificationManager?.createNotificationChannel(notificationChannel)
        }
        print("Show")

        val nBuilder = NotificationCompat.Builder(applicationContext, NOTIFICATION_CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_action_alarm)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
        val remoteView = RemoteViews(packageName, R.layout.notification_layout)
        remoteView.setTextViewText(R.id.title, call.arguments as String)

        val intent = Intent(applicationContext, NotificationReturn::class.java)
                .setAction("add")
        remoteView.setOnClickPendingIntent(R.id.add,
                PendingIntent.getBroadcast(applicationContext,
                        0, intent, PendingIntent.FLAG_UPDATE_CURRENT))

        nBuilder.setContent(remoteView)
        val notification = nBuilder.build()
        notificationManager?.notify(1, notification)
        result.success(null)
      }
      if(call.method == "hide") {
        notificationManager?.cancel(1)
        result.success(null)
      }
    }
  }
}

public class NotificationReturn: BroadcastReceiver() {
  override fun onReceive(context: Context?, intent: Intent?) {
    print("OnReceive")
    methodChannel?.invokeMethod("add", "")
  }
}