package vn.vihat.omicall.omicallsdk.videoCall

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger

class FLRemoteCameraView(
    context: Context,
    id: Int,
    @Suppress("UNUSED_PARAMETER") creationParams: Map<String?, Any?>?,
    messenger: BinaryMessenger,
) : FLVideoTextureView(context, id, messenger, "omicallsdk/remote_camera_controller", isLocal = false)
