package vn.vihat.omicall.omicallsdk.video_call

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.SurfaceTexture
import android.util.Log
import android.view.Surface
import android.view.TextureView
import android.view.View
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import vn.vihat.omicall.omisdk.OmiClient
import vn.vihat.omicall.omisdk.videoutils.ScaleManager
import vn.vihat.omicall.omisdk.videoutils.Size

internal class FLLocalCameraView(
    context: Context,
    id: Int,
    creationParams: Map<String?, Any?>?,
    messenger: BinaryMessenger,
) :
    PlatformView, MethodChannel.MethodCallHandler, TextureView.SurfaceTextureListener {
    private val localView: TextureView
    private var methodChannel: MethodChannel

    override fun getView(): View {
        return localView
    }

    override fun dispose() {}

    init {
        methodChannel = MethodChannel(messenger, "omicallsdk/local_camera_controller/$id")
        methodChannel.setMethodCallHandler(this)
        localView = TextureView(context)
        localView.surfaceTextureListener = this
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "refresh") {
            localView.surfaceTexture?.let {
                OmiClient.instance.setupLocalVideoFeed(Surface(it))
                ScaleManager.adjustAspectRatio(
                    localView,
                    Size(localView.width, localView.height),
                    Size(1280, 720)
                )
            }
        }
        if (call.method == "permission") {
            val permission = ContextCompat.checkSelfPermission(
                OmiClient.instance.context,
                Manifest.permission.CAMERA
            )
            val isGranted = permission != PackageManager.PERMISSION_GRANTED
            result.success(isGranted)
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