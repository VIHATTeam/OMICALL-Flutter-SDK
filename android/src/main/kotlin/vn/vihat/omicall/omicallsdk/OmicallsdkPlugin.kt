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

/** OmicallsdkPlugin */
class OmicallsdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, OmiListener {

    private lateinit var channel: MethodChannel
    private var activity: FlutterActivity? = null
    private var applicationContext: Context? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "omicallsdk")
        channel.setMethodCallHandler(this)
        flutterPluginBinding
            .platformViewRegistry
            .registerViewFactory("local_camera_view", FLLocalCameraFactory())
        OmiClient(applicationContext!!)
    }


    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "action") {
            handleAction(call, result)
        } else {
            result.notImplemented()
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
                OmiClient.instance.setListener(this)
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
                if (!isVideo) {
                    OmiClient.instance.startCall(phoneNumber)
                }
                result.success(true)
            }
            END_CALL -> {
                OmiClient.instance.hangUp()
                result.success(true)
            }
            TOGGLE_MUTE -> {
                OmiClient.instance.toggleMute()
                result.success(true)
            }
            TOGGLE_SPEAK -> {
                val useSpeaker = dataOmi["useSpeaker"] as Boolean
                OmiClient.instance.toggleSpeaker(useSpeaker)
                result.success(true)
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
}
