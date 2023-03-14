package vn.vihat.omicall.omicallsdk

import android.Manifest
import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.EventChannel.StreamHandler
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import vn.vihat.omicall.omicallsdk.constants.*
import vn.vihat.omicall.omicallsdk.video_call.FLLocalCameraFactory
import vn.vihat.omicall.omisdk.OmiClient
import vn.vihat.omicall.omisdk.OmiListener
import vn.vihat.omicall.omisdk.utils.OmiSDKUtils
import java.util.*
import kotlin.collections.HashMap

/** OmicallsdkPlugin */
class OmicallsdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, StreamHandler  {

    private lateinit var channel: MethodChannel
    private lateinit var cameraEventChannel: EventChannel
    private lateinit var onMicEventChannel: EventChannel
    private lateinit var onMuteEventChannel: EventChannel
    private var cameraEventSink: EventSink? = null
    private var onMicEventSink: EventSink? = null
    private var onMuteEventSink: EventSink? = null
    private var activity: FlutterActivity? = null
    private var applicationContext: Context? = null
    private var icSpeaker = false
    private var isMute = false

    private val callListener = object : OmiListener {
        override fun onCallEstablished() {
            val sipNumber = OmiClient.instance.callUUID
            channel.invokeMethod(onCallEstablished, mapOf(
                "callerNumber" to sipNumber,
                "isVideo" to false,
            ))

            Log.d("omikit", "onCallEstablished: ")

        }

        override fun onCallEnd() {
            channel.invokeMethod(onCallEnd, null)
        }

        override fun incomingReceived(callerId: Int, phoneNumber: String?) {
            channel.invokeMethod(
                incomingReceived, mapOf(
                    "isVideo" to false,
                    "callerNumber" to phoneNumber,
                )
            )
            Log.d("omikit", "incomingReceived: ")
        }

        override fun onRinging() {
        }

        override fun onVideoSize(width: Int, height: Int) {

        }

        override fun onConnectionTimeout() {
            channel.invokeMethod(onConnectionTimeout, null)
            Log.d("omikit", "onConnectionTimeout: ")

        }

        override fun onHold(isHold: Boolean) {
            channel.invokeMethod(
                onHold, mapOf(
                    "isHold" to isHold,
                )
            )
            Log.d("omikit", "onHold: $isHold")

        }

        override fun onMuted(isMuted: Boolean) {
            channel.invokeMethod(
                onMuted, mapOf(
                    "isMuted" to isMuted,
                )
            )
            Log.d("omikit", "onMuted: $isMuted")
        }

        override fun onOutgoingStarted(callerId: Int, phoneNumber: String?, isVideo: Boolean?) {
            Log.d("aa", "aa")
        }
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "omicallsdk")
        channel.setMethodCallHandler(this)
        cameraEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "event/camera")
        cameraEventChannel.setStreamHandler(this)
        onMicEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "event/on_mic")
        onMicEventChannel.setStreamHandler(this)
        onMuteEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "event/on_mute")
        onMuteEventChannel.setStreamHandler(this)
        flutterPluginBinding
            .platformViewRegistry
            .registerViewFactory("local_camera_view", FLLocalCameraFactory(flutterPluginBinding.binaryMessenger))
        OmiClient(applicationContext!!)
        OmiClient.instance.setListener(callListener)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "action") {
            handleAction(call, result)
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun handleAction(call: MethodCall, result: Result) {
        val data = call.arguments as HashMap<String, Any>
        val dataOmi = data["data"] as HashMap<String, Any>

        when (data["actionName"]) {
            INIT_CALL -> {
                val userName = dataOmi["userName"] as String
                val password = dataOmi["password"] as String
                val realm = dataOmi["realm"] as String
                OmiClient.register(
                    applicationContext!!,
                    userName,
                    password,
                    false,
                    realm,
                    customUI = true,
                    isTcp = true
                )
                ActivityCompat.requestPermissions(
                    activity!!,
                    arrayOf(
                        Manifest.permission.USE_SIP,
                        Manifest.permission.CALL_PHONE,
                        Manifest.permission.CAMERA,
                        Manifest.permission.MODIFY_AUDIO_SETTINGS,
                        Manifest.permission.RECORD_AUDIO,
                    ),
                    0,
                )
                result.success(true)
            }
            UPDATE_TOKEN -> {
                val deviceTokenAndroid = dataOmi["fcmToken"] as String
                val deviceId = dataOmi["deviceId"] as String
                val appId = dataOmi["appId"] as String
                OmiClient.instance.updatePushToken(
                    "",
                    deviceTokenAndroid,
                    deviceId,
                    appId,
                )
                result.success(true)
            }
            START_CALL -> {
                val phoneNumber = dataOmi["phoneNumber"] as String
                val isVideo = dataOmi["isVideo"] as Boolean
                OmiClient.instance.startCall(phoneNumber, isVideo)
                result.success(true)
            }
            END_CALL -> {
                OmiClient.instance.hangUp()
                result.success(true)
            }
            TOGGLE_MUTE -> {
                OmiClient.instance.toggleMute()
                result.success(true)
                isMute = !isMute
                onMuteEventSink?.success(isMute)
            }
            TOGGLE_SPEAK -> {
                icSpeaker = !icSpeaker
                OmiClient.instance.toggleSpeaker(icSpeaker)
                result.success(true)
                onMicEventSink?.success(icSpeaker)
            }
            REGISTER -> {}
            SEND_DTMF -> {
                val character = dataOmi["character"] as String
                var characterCode: Int? = character.toIntOrNull()
                if (character == "*") {
                    characterCode = 10
                }
                if (character == "#") {
                    characterCode = 11
                }
                if (characterCode != null) {
                    OmiClient.instance.sendDtmf(characterCode)
                }
                result.success(true)
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.activity = binding.activity as FlutterActivity
    }

    override fun onDetachedFromActivityForConfigChanges() {

    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {

    }

    override fun onDetachedFromActivity() {

    }

    companion object {
        fun onDestroy() {
            OmiClient.instance.disconnect()
        }

        fun onRequestPermissionsResult(
            requestCode: Int,
            permissions: Array<out String>,
            grantResults: IntArray,
            act: FlutterActivity,
        ) {
            OmiSDKUtils.handlePermissionRequest(requestCode, permissions, grantResults, act)
        }
    }

    override fun onListen(arguments: Any?, events: EventSink?) {
        val args = arguments as HashMap<*, *>
        val name = args["name"] as String
        if (name == "camera") {
            cameraEventSink = events
        }
        if (name == "on_mute") {
            onMuteEventSink = events
        }
        if (name == "on_mic") {
            onMicEventSink = events
        }
    }

    override fun onCancel(arguments: Any?) {
//        cameraEventSink = null
//        onMicEventSink = null
//        onMuteEventSink = null
    }
}
