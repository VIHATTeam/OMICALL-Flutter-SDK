package vn.vihat.omicall.omicallsdk.video_call

import android.content.Context
import android.graphics.SurfaceTexture
import android.util.Log
import android.view.Surface
import android.view.TextureView
import android.view.View
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import vn.vihat.omicall.omisdk.OmiClient

internal class FLRemoteCameraView(context: Context, id: Int, creationParams: Map<String?, Any?>?,  messenger: BinaryMessenger) :
    PlatformView, MethodChannel.MethodCallHandler, TextureView.SurfaceTextureListener {
    private val remoteView : TextureView
    private var methodChannel : MethodChannel

    override fun getView(): View {
        return remoteView
    }

    override fun dispose() {}

    init {
        methodChannel = MethodChannel(messenger, "remote_camera_controller/$id")
        methodChannel.setMethodCallHandler(this)
        remoteView = TextureView(context)
        remoteView.surfaceTextureListener = this
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "refresh") {
            remoteView.surfaceTexture?.let {
                OmiClient.instance.setupIncomingVideoFeed(Surface(it))
                remoteView.scaleX = 1.5F
            }
        }
    }

    override fun onSurfaceTextureAvailable(surface: SurfaceTexture, width: Int, height: Int) {
        Log.d("a", "onSurfaceTextureAvailable")
    }

    override fun onSurfaceTextureSizeChanged(surface: SurfaceTexture, width: Int, height: Int) {
        Log.d("a", "onSurfaceTextureSizeChanged")
    }

    override fun onSurfaceTextureDestroyed(surface: SurfaceTexture): Boolean {
        Log.d("a", "onSurfaceTextureDestroyed")
        return false
    }

    override fun onSurfaceTextureUpdated(surface: SurfaceTexture) {
        Log.d("a", "onSurfaceTextureUpdated")
    }
}