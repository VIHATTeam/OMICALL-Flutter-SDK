package vn.vihat.omicall.omicallsdk

import android.app.Activity
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import vn.vihat.omicall.omicallsdk.constants.*
import vn.vihat.omicall.omisdk.OmiClient
import vn.vihat.omicall.omisdk.OmiSDKUtils
import java.util.*

/** OmicallsdkPlugin */
class OmicallsdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "omicallsdk")
        channel.setMethodCallHandler(this)

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
                OmiClient.instance.register(userName, password, realm)
            }
            UPDATE_TOKEN -> {
                val deviceTokenAndroid = dataOmi["deviceTokenAndroid"] as String
                val tokenVoipIos = dataOmi["tokenVoipIos"] as String
                val appId = dataOmi["appId"] as String
                val deviceId = dataOmi["deviceId"] as String
                OmiClient.instance.updatePushToken(
                    tokenVoipIos,
                    deviceTokenAndroid,
                    deviceId,
                    appId
                );
            }
            START_OMI_SERVICE -> {
                activity?.let {
                    OmiSDKUtils.startOmiService(it)

                }
            }
            START_CALL -> {
                val phoneNumber = dataOmi["phoneNumber"] as String
                val isTransfer = dataOmi["isTransfer"] as Boolean
                OmiClient.instance.startCall(phoneNumber, isTransfer)
            }
            END_CALL -> {
                OmiClient.instance.hangUp()
            }
            TOGGLE_MUTE -> {
                OmiClient.instance.toggleMute()
            }
            TOGGLE_SPEAK -> {
                val useSpeaker = dataOmi["useSpeaker"] as Boolean
                OmiClient.instance.toggleSpeaker(useSpeaker)

            }
            CHECK_ON_GOING_CALL -> {}
            DECLINE -> {
                OmiClient.instance.decline()
            }
            FORWARD_CALL_TO -> {}
            HANGUP -> {
                val callId = dataOmi["callId"] as Int
                OmiClient.instance.hangUp(callId)

            }
            ON_CALL_STARTED -> {
                val callId = dataOmi["callId"] as Int
                OmiClient.instance.onCallStarted(callId)
            }
            ON_HOLD -> {
                val isHold = dataOmi["isHold"] as Boolean
                OmiClient.instance.onHold(isHold)
            }
            ON_IN_COMING_RECEIVE -> {}
            ON_MUTE -> {
                val isMute = dataOmi["isMute"] as Boolean
                OmiClient.instance.onMuted(isMute)
            }
            ON_OUT_GOING -> {}
            REGISTER -> {}
        }

        result.success(true)


    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {

    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {

    }

    override fun onDetachedFromActivity() {

    }
}
