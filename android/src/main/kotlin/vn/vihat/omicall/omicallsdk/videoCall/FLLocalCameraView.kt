package vn.vihat.omicall.omicallsdk.videoCall

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class FLLocalCameraView(
    private val context: Context,
    id: Int,
    @Suppress("UNUSED_PARAMETER") creationParams: Map<String?, Any?>?,
    messenger: BinaryMessenger,
) : FLVideoTextureView(context, id, messenger, "omicallsdk/local_camera_controller", isLocal = true) {

    override fun onExtraMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "permission") {
            val permission = ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA)
            result.success(permission == PackageManager.PERMISSION_GRANTED)
        } else {
            result.notImplemented()
        }
    }
}
