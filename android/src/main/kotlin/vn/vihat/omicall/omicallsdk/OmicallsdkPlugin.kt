package vn.vihat.omicall.omicallsdk

import android.Manifest
import android.content.Context
import android.hardware.camera2.CameraManager
import android.os.Build
import android.os.Handler
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat.requestPermissions
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
import kotlinx.coroutines.*
import vn.vihat.omicall.omicallsdk.constants.*
import vn.vihat.omicall.omicallsdk.video_call.FLLocalCameraFactory
import vn.vihat.omicall.omicallsdk.video_call.FLRemoteCameraFactory
import vn.vihat.omicall.omisdk.OmiAccountListener
import vn.vihat.omicall.omisdk.OmiClient
import vn.vihat.omicall.omisdk.OmiListener
import vn.vihat.omicall.omisdk.utils.OmiSDKUtils
import java.util.*

/** OmicallsdkPlugin */
class OmicallsdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var cameraEventChannel: EventChannel
    private lateinit var onMicEventChannel: EventChannel
    private lateinit var onMuteEventChannel: EventChannel
    private var activity: FlutterActivity? = null
    private var applicationContext: Context? = null
    private val mainScope = CoroutineScope(Dispatchers.Main)

    private val callListener = object : OmiListener {

        override fun incomingReceived(callerId: Int, phoneNumber: String?, isVideo: Boolean?) {
            channel.invokeMethod(
                INCOMING_RECEIVED, mapOf(
                    "isVideo" to isVideo,
                    "callerNumber" to phoneNumber,
                )
            )
            Log.d("omikit", "incomingReceived: ")
        }

        override fun onCallEnd() {
            Log.d("omikit-endCall", "onCallEnd: ")
            print("omikit-endCall");
            channel.invokeMethod(CALL_END, null)
        }

        override fun onCallEstablished(
            callerId: Int,
            phoneNumber: String?,
            isVideo: Boolean?,
            startTime: Long,
        ) {
            Handler().postDelayed({
                channel.invokeMethod(
                    CALL_ESTABLISHED, mapOf(
                        "callerNumber" to phoneNumber,
                        "isVideo" to isVideo,
                    )
                )
            }, 500)
            Log.d("omikit", "onCallEstablished: ")
        }

        override fun onHold(isHold: Boolean) {
        }

        override fun onMuted(isMuted: Boolean) {
            channel.invokeMethod(
                MUTED, mapOf(
                    "isMuted" to isMuted,
                )
            )
            Log.d("omikit", "onMuted: $isMuted")
        }

        override fun onRinging() {
        }

        override fun onVideoSize(width: Int, height: Int) {

        }

        override fun onConnectionTimeout() {
//            channel.invokeMethod(onConnectionTimeout, null)
//            Log.d("omikit", "onConnectionTimeout: ")
        }

        override fun onOutgoingStarted(callerId: Int, phoneNumber: String?, isVideo: Boolean?) {
            Log.d("aa", "aa")
        }
    }

    private val accountListener = object : OmiAccountListener {
        override fun onAccountStatus(online: Boolean) {
            Log.d("aaa", "Account status $online")
//            initResult?.success(online)
//            initResult = null
        }
    }


    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "omicallsdk")
        channel.setMethodCallHandler(this)
        flutterPluginBinding
            .platformViewRegistry
            .registerViewFactory(
                "omicallsdk/local_camera_view",
                FLLocalCameraFactory(flutterPluginBinding.binaryMessenger)
            )
        flutterPluginBinding
            .platformViewRegistry
            .registerViewFactory(
                "omicallsdk/remote_camera_view",
                FLRemoteCameraFactory(flutterPluginBinding.binaryMessenger)
            )
//        setupSIP()
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
            START_SERVICES -> {
                OmiClient(applicationContext!!)
                OmiClient.instance.setListener(callListener)
                OmiClient.instance.addAccountListener(accountListener)
                result.success(true)
            }
            CONFIG_NOTIFICATION -> {
                val prefix = dataOmi["prefix"] as? String
                val declineTitle = dataOmi["declineTitle"] as? String
                val acceptTitle = dataOmi["acceptTitle"] as? String
                val acceptBackgroundColor = dataOmi["acceptBackgroundColor"] as? String
                val declineBackgroundColor = dataOmi["declineBackgroundColor"] as? String
                val incomingBackgroundColor = dataOmi["incomingBackgroundColor"] as? String
                val incomingAcceptButtonImage = dataOmi["incomingAcceptButtonImage"] as? String
                val incomingDeclineButtonImage = dataOmi["incomingDeclineButtonImage"] as? String
                val backImage = dataOmi["backImage"] as? String
                val userImage = dataOmi["userImage"] as? String
                OmiClient.instance.configPushNotification(
                    prefix = prefix ?: "Cuộc gọi tới từ: ",
                    declineTitle = declineTitle ?: "Từ chối",
                    acceptTitle = acceptTitle ?: "Chấp nhận",
                    acceptBackgroundColor = acceptBackgroundColor ?: "#FF3700B3",
                    declineBackgroundColor = declineBackgroundColor ?: "#FF000000",
                    incomingBackgroundColor = incomingBackgroundColor ?: "#FFFFFFFF",
                    incomingAcceptButtonImage = incomingAcceptButtonImage ?: "join_call",
                    incomingDeclineButtonImage = incomingDeclineButtonImage ?: "hangup",
                    backImage = backImage ?: "ic_back",
                    userImage = userImage ?: "calling_face",
                )
                result.success(true)
            }
            INIT_CALL_USER_PASSWORD -> {
                val userName = dataOmi["userName"] as? String
                val password = dataOmi["password"] as? String
                val realm = dataOmi["realm"] as? String
                val host = dataOmi["host"] as? String
                val isVideo = dataOmi["isVideo"] as? Boolean
                if (userName != null && password != null && realm != null && host != null) {
                    OmiClient.register(
                        userName,
                        password,
                        isVideo ?: true,
                        realm,
                        host,
                    )
                }
                requestPermission(isVideo ?: true)
                if (isVideo == true) {
                    setCamera()
                }
                result.success(true)
            }
            INIT_CALL_API_KEY -> {
                mainScope.launch {
                    var loginResult = false
                    val usrName = dataOmi["fullName"] as? String
                    val usrUuid = dataOmi["usrUuid"] as? String
                    val apiKey = dataOmi["apiKey"] as? String
                    val isVideo = dataOmi["isVideo"] as? Boolean
                    withContext(Dispatchers.Default) {
                       try {
                           if (usrName != null && usrUuid != null && apiKey != null) {
                               loginResult = OmiClient.registerWithApiKey(
                                   apiKey = apiKey,
                                   userName = usrName,
                                   uuid = usrUuid,
                                   isVideo ?: true,
                               )
                           }
                       } catch (_ : Throwable) {

                       }
                    }
                    requestPermission(isVideo ?: true)
                    if (isVideo == true) {
                        setCamera()
                    }
                    result.success(loginResult)
                }
            }
            UPDATE_TOKEN -> {
                mainScope.launch {
                    val deviceTokenAndroid = dataOmi["fcmToken"] as String
                    val deviceId = dataOmi["deviceId"] as String
                    val appId = dataOmi["appId"] as String
                    withContext(Dispatchers.Default) {
                       try {
                           OmiClient.instance.updatePushToken(
                               "",
                               deviceTokenAndroid,
                               deviceId,
                               appId,
                           )
                       } catch (_ : Throwable) {

                       }
                    }
                    result.success(true)
                }
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
                mainScope.launch {
                    var newStatus : Boolean? = null
                    withContext(Dispatchers.Default) {
                        try {
                            newStatus = OmiClient.instance.toggleMute()
                        } catch (_ : Throwable) {

                        }
                    }
                    result.success(newStatus)
                    channel.invokeMethod(MUTED, newStatus)
                }
            }
            TOGGLE_SPEAK -> {
                val newStatus = OmiClient.instance.toggleSpeaker()
                result.success(newStatus)
                channel.invokeMethod(SPEAKER, newStatus)
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
            JOIN_CALL -> {
                OmiClient.instance.pickUp()
            }
            SWITCH_CAMERA -> {
                OmiClient.instance.switchCamera()
                channel.invokeMethod(CAMERA_STATUS, true)
            }
            TOGGLE_VIDEO -> {
                OmiClient.instance.toggleCamera()
            }
            INPUTS -> {
                val inputs = OmiClient.instance.getAudioInputs()
                val allAudios = inputs.map {
                    mapOf(
                        "name" to it.first,
                        "id" to it.second,
                    )
                }.toTypedArray()
                result.success(allAudios)
            }
            OUTPUTS -> {
                val inputs = OmiClient.instance.getAudioOutputs()
                val allAudios = inputs.map {
                    mapOf(
                        "name" to it.first,
                        "id" to it.second,
                    )
                }.toTypedArray()
                result.success(allAudios)
            }
            SET_INPUT -> {

            }

            SET_OUTPUT -> {

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
//            OmiClient.instance.disconnect()
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

    private fun requestPermission(isVideo : Boolean) {
        var permissions = arrayOf(
            Manifest.permission.USE_SIP,
            Manifest.permission.CALL_PHONE,
            Manifest.permission.MODIFY_AUDIO_SETTINGS,
            Manifest.permission.RECORD_AUDIO,
        )
        if (isVideo) {
            permissions = permissions.plus(Manifest.permission.CAMERA)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions = permissions.plus(Manifest.permission.POST_NOTIFICATIONS)
        }
        requestPermissions(
            activity!!,
            permissions,
            0,
        )
    }

    private fun setCamera() {
        val cm =
            applicationContext!!.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        OmiClient.instance.setCameraManager(cm)
    }
}
