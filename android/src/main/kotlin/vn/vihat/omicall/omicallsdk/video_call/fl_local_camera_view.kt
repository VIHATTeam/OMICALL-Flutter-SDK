package vn.vihat.omicall.omicallsdk.video_call

import android.content.Context
import android.view.Surface
import android.view.TextureView
import android.view.View
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.platform.PlatformView
import vn.vihat.omicall.omisdk.OmiClient
import io.flutter.plugin.common.MethodChannel

internal class FLLocalCameraView(context: Context, id: Int, creationParams: Map<String?, Any?>?,  messenger: BinaryMessenger) :
    PlatformView, MethodChannel.MethodCallHandler {
    private val view: TextureView
    private var methodChannel : MethodChannel

    override fun getView(): View {
        return view
    }

    override fun dispose() {}

    init {
        methodChannel = MethodChannel(messenger, "local_camera_controller/$id")
        methodChannel.setMethodCallHandler(this)
        view = TextureView(context)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "refresh") {
            view.surfaceTexture?.let {
                OmiClient.instance.setupLocalVideoFeed(Surface(it))
                view.scaleX = 1.5F
            }
        }
    }
}