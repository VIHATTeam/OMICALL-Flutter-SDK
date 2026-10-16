package vn.vihat.omicall.omicallsdk.videoCall

import android.content.Context
import android.graphics.SurfaceTexture
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Surface
import android.view.TextureView
import android.view.View
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import vn.vihat.omicall.omisdk.OmiClient
import vn.vihat.omicall.omisdk.videoutils.ScaleManager
import vn.vihat.omicall.omisdk.videoutils.Size
import java.lang.ref.WeakReference

/**
 * TextureView platform view for one video feed, following the production Android-Client
 * (CallSessionActivity): attach as soon as the surface exists, fit 9:16 portrait, remote ratio
 * from onVideoSize, re-fit whenever the view is resized (PiP, layout).
 */
abstract class FLVideoTextureView(
    context: Context,
    id: Int,
    messenger: BinaryMessenger,
    channelName: String,
    private val isLocal: Boolean,
) : PlatformView, MethodChannel.MethodCallHandler, TextureView.SurfaceTextureListener {

    private val appContext: Context = context.applicationContext
    private val textureView = TextureView(context)
    private val methodChannel = MethodChannel(messenger, "$channelName/$id")

    // One Surface per SurfaceTexture: refresh / re-attach reuse it instead of leaking a new one
    private var surface: Surface? = null
    private var surfaceOwner: SurfaceTexture? = null

    init {
        methodChannel.setMethodCallHandler(this)
        textureView.surfaceTextureListener = this
        register()
    }

    override fun getView(): View = textureView

    override fun dispose() {
        methodChannel.setMethodCallHandler(null)
        unregister()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "refresh" -> result.success(attach())
            else -> onExtraMethodCall(call, result)
        }
    }

    protected open fun onExtraMethodCall(call: MethodCall, result: MethodChannel.Result) {
        result.notImplemented()
    }

    /** Hand the surface to the SDK. Safe to repeat; false while the surface does not exist yet. */
    fun attach(): Boolean {
        val texture = textureView.surfaceTexture ?: return false
        return try {
            if (surfaceOwner !== texture) {
                surface = Surface(texture)
                surfaceOwner = texture
            }
            val client = OmiClient.getInstance(appContext)
            if (isLocal) client.setupLocalVideoFeed(surface!!) else client.setupIncomingVideoFeed(surface!!)
            fitVideo()
            true
        } catch (e: Throwable) {
            Log.e(TAG, "attach(isLocal=$isLocal) failed", e)
            false
        }
    }

    /** Fit (letterbox) the video into the view; remote uses the size reported by onVideoSize. */
    fun fitVideo() {
        val w = textureView.width
        val h = textureView.height
        if (w <= 0 || h <= 0) return
        val video = if (isLocal) DEFAULT_SIZE else remoteSize
        ScaleManager.adjustAspectRatio(textureView, Size(w, h), video)
    }

    override fun onSurfaceTextureAvailable(surface: SurfaceTexture, width: Int, height: Int) {
        attach()
    }

    override fun onSurfaceTextureSizeChanged(surface: SurfaceTexture, width: Int, height: Int) {
        fitVideo()
    }

    override fun onSurfaceTextureDestroyed(surface: SurfaceTexture): Boolean {
        this.surface = null
        surfaceOwner = null
        return true // let the TextureView release its SurfaceTexture
    }

    override fun onSurfaceTextureUpdated(surface: SurfaceTexture) {}

    private fun register() {
        if (isLocal) localView = WeakReference(this) else remoteView = WeakReference(this)
    }

    private fun unregister() {
        if (isLocal && localView?.get() === this) localView = null
        if (!isLocal && remoteView?.get() === this) remoteView = null
    }

    companion object {
        private const val TAG = "OmiVideoView"

        // SDK default portrait capture size, as used by the Android-Client
        private val DEFAULT_SIZE = Size(480, 854)

        private var localView: WeakReference<FLVideoTextureView>? = null
        private var remoteView: WeakReference<FLVideoTextureView>? = null
        private var remoteSize: Size = DEFAULT_SIZE
        private val mainHandler = Handler(Looper.getMainLooper())

        /** Call established as video: (re)attach the views that already exist. */
        fun attachAll() = runOnMain {
            localView?.get()?.attach()
            remoteView?.get()?.attach()
        }

        /**
         * Remote picture size from OmiListener.onVideoSize. Square sizes are decoder buffer
         * sizes (e.g. 976x976), not the picture, and do not change the fit.
         */
        fun updateRemoteSize(width: Int, height: Int) {
            if (width <= 0 || height <= 0 || width == height) return
            runOnMain {
                remoteSize = Size(width, height)
                remoteView?.get()?.fitVideo()
            }
        }

        /** New call: forget the previous peer's size. */
        fun resetRemoteSize() = runOnMain { remoteSize = DEFAULT_SIZE }

        private fun runOnMain(block: () -> Unit) {
            if (Looper.myLooper() == Looper.getMainLooper()) block() else mainHandler.post(block)
        }
    }
}
