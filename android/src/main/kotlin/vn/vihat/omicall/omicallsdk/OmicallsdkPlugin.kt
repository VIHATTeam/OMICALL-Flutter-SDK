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
import vn.vihat.omicall.omisdk.OmiSDKUtils
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
    }


    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "action") {
            handleAction(call, result);
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
                    realm,
                    customUI = true,
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
                val appId = dataOmi["appId"] as String
                val deviceId = dataOmi["deviceId"] as String
                OmiClient.instance.updatePushToken(
                    "",
                    deviceTokenAndroid,
                    deviceId,
                    appId
                )
                result.success(true)
            }
            START_OMI_SERVICE -> {
                activity?.let {
                    OmiSDKUtils.startOmiService(it)
                    result.success(true)
                }
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
            CHECK_ON_GOING_CALL -> {}
            DECLINE -> {
                OmiClient.instance.decline()
                result.success(true)
            }
            FORWARD_CALL_TO -> {}
            HANGUP -> {
                val callId = dataOmi["callId"] as Int
                OmiClient.instance.hangUp(callId)
                result.success(true)
            }
            ON_CALL_STARTED -> {
                val callId = dataOmi["callId"] as Int
                OmiClient.instance.onCallStarted(callId)
                result.success(true)
            }
            ON_HOLD -> {
                val isHold = dataOmi["isHold"] as Boolean
                OmiClient.instance.onHold(isHold)
                result.success(true)
            }
            ON_IN_COMING_RECEIVE -> {}
            ON_MUTE -> {
                val isMute = dataOmi["isMute"] as Boolean
                OmiClient.instance.onMuted(isMute)
                result.success(true)
            }
            ON_OUT_GOING -> {}
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
//        val sipNumber = OmiClient.instance.currentCallerId
        channel.invokeMethod(onCallEstablished, mapOf(
            "callerNumber" to "100",
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
                "phoneNumber" to phoneNumber,
                "isIncoming" to true,
            )
        )
        Log.d("omikit", "incomingReceived: ")
    }

    override fun onRinging() {
        channel.invokeMethod(onRinging, null)
        Log.d("omikit", "onRinging: ")

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
