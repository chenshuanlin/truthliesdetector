package com.example.truthliesdetector

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Bundle

// 定義常數，供 ScreenshotService.kt 使用
const val ACTION_MEDIA_PROJECTION_RESULT = "ACTION_MEDIA_PROJECTION_RESULT"
const val EXTRA_RESULT_CODE = "EXTRA_RESULT_CODE"
const val EXTRA_RESULT_DATA = "EXTRA_RESULT_DATA"

// 媒體投影權限請求碼
private const val REQUEST_MEDIA_PROJECTION = 101

class ScreenshotHelperActivity : Activity() {

    private lateinit var mediaProjectionManager: MediaProjectionManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 設置為透明
        setTheme(android.R.style.Theme_Translucent_NoTitleBar)
        
        mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        
        // 請求 MediaProjection 權限
        val intent = mediaProjectionManager.createScreenCaptureIntent()
        startActivityForResult(intent, REQUEST_MEDIA_PROJECTION)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == REQUEST_MEDIA_PROJECTION) {
            
            val intent = Intent(ACTION_MEDIA_PROJECTION_RESULT).apply {
                // 將結果回傳給 Service
                putExtra(EXTRA_RESULT_CODE, resultCode)
                // 傳輸 MediaProjection 相關的 Intent
                putExtra(EXTRA_RESULT_DATA, data) 
            }
            
            // 使用廣播將結果發送給 Service
            sendBroadcast(intent)
            
            // 立即結束此透明 Activity
            finish()
        }
    }
}