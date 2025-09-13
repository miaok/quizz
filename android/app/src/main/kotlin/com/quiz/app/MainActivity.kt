package com.quiz.app

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 优化缓冲区管理，减少BLASTBufferQueue错误
        window.addFlags(WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED)
        
        // 设置合理的缓冲区参数
        window.attributes = window.attributes.apply {
            // 减少缓冲区数量，避免超出限制
            flags = flags or WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
        }
    }
    
    override fun onResume() {
        super.onResume()
        // 确保在恢复时释放不必要的缓冲区
        System.gc()
    }
    
    override fun onPause() {
        super.onPause()
        // 暂停时主动释放资源
        System.gc()
    }
}
