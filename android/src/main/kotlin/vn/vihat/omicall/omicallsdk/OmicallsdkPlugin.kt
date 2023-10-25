package vn.vihat.omicall.omicallsdk

import android.Manifest
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat.requestPermissions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.*
import vn.vihat.omicall.omicallsdk.constants.*
import vn.vihat.omicall.omicallsdk.state.CallState
import vn.vihat.omicall.omicallsdk.video_call.FLLocalCameraFactory
import vn.vihat.omicall.omicallsdk.video_call.FLRemoteCameraFactory
import vn.vihat.omicall.omisdk.OmiAccountListener
import vn.vihat.omicall.omisdk.OmiClient
import vn.vihat.omicall.omisdk.OmiListener
import vn.vihat.omicall.omisdk.service.NotificationService
import vn.vihat.omicall.omisdk.utils.OmiSDKUtils
import vn.vihat.omicall.omisdk.utils.OmiStartCallStatus
import vn.vihat.omicall.omisdk.utils.SipServiceConstants
import vn.vihat.omicall.omisdk.utils.OmiSipTransport
import java.util.*
import com.google.gson.Gson

/** OmicallsdkPlugin */
class OmicallsdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.NewIntentListener, OmiListener {

    private lateinit var channel: MethodChannel
    private var activity: FlutterActivity? = null
    private var applicationContext: Context? = null
    private val mainScope = CoroutineScope(Dispatchers.Main)
    private var isIncomming: Boolean = false
    private var callerNumberTemp: String = ""
    private var isAnserCall: Boolean = false

    override fun incomingReceived(callerId: Int?, phoneNumber: String?, isVideo: Boolean?) {
        Log.d("SDK ====> CALL ACTION:::  ", "incomingReceived -> callerId=$callerId, phoneNumber=$phoneNumber")
        isIncomming = true;
        callerNumberTemp = phoneNumber ?: "";
        channel.invokeMethod(
            CALL_STATE_CHANGED, mapOf(
                "isVideo" to isVideo,
                "status" to CallState.incoming.value,
                "callerNumber" to phoneNumber,
                "_id" to "",
                "incoming" to isIncomming
            )
        )
    }

    override fun onCallEstablished(
        callerId: Int,
        phoneNumber: String?,
        isVideo: Boolean?,
        startTime: Long,
        transactionId: String?,
    ) {
        isAnserCall = true
        Log.d("SDK ====> CALL ACTION:::  ", "onCallEstablished -> callerId=$callerId, phoneNumber=$phoneNumber")
        channel.invokeMethod(
            CALL_STATE_CHANGED, mapOf(
                "callerNumber" to phoneNumber,
                "status" to CallState.confirmed.value,
                "isVideo" to isVideo,
                "transactionId" to transactionId,
                "incoming" to isIncomming
            )
        )
        Log.d("omikit", "onCallEstablished: ")
    }

    override fun onCallEnd(callInfo: MutableMap<String, Any?>, statusCode: Int) {
        Log.d("SDK ====> CALL ACTION:::  ", "onCallEnd -> callInfo=$callInfo, statusCode=$statusCode")
        callInfo["status"] = CallState.disconnected.value
        channel.invokeMethod(CALL_STATE_CHANGED, callInfo)
        isIncomming = false;
        isAnserCall  = false
    }

    override fun onConnecting() {
        Log.d("SDK ====> CALL ACTION:::  ", "onConnecting ->")
        channel.invokeMethod(
            CALL_STATE_CHANGED, mapOf(
                "status" to CallState.connecting.value,
                "isVideo" to NotificationService.isVideo,
                "callerNumber" to "",
                "incoming" to isIncomming,
                "_id" to ""
            )
        )
    }

    override fun onRinging(callerId: Int, transactionId: String?) {
        var callDirection  = OmiClient.callDirection
        Log.d("SDK ====> CALL ACTION:::  ", "onRinging -> callerId=$callerId, transactionId=$transactionId , callDirection=$callDirection")
        if(callDirection == "inbound") {
            channel.invokeMethod(
                CALL_STATE_CHANGED, mapOf(
                    "status" to CallState.incoming.value,
                    "isVideo" to NotificationService.isVideo,
                    "callerNumber" to OmiClient.prePhoneNumber,
                    "incoming" to true,
                    "_id" to ""
                )
            )
        } else {
            channel.invokeMethod(
                CALL_STATE_CHANGED, mapOf(
                    "status" to CallState.early.value,
                    "isVideo" to NotificationService.isVideo,
                    "callerNumber" to OmiClient.prePhoneNumber,
                    "incoming" to false,
                    "_id" to ""
                )
            )
        }
    }

    override fun onOutgoingStarted(callerId: Int, phoneNumber: String?, isVideo: Boolean?) {
        isIncomming = false;
        Log.d("SDK ====> CALL ACTION:::  ", "onOutgoingStarted -> callerId=$callerId, phoneNumber=$phoneNumber")
        channel.invokeMethod(
            CALL_STATE_CHANGED, mapOf(
                "status" to CallState.calling.value,
                "isVideo" to isVideo,
                "callerNumber" to "",
                "incoming" to isIncomming,
                "_id" to ""
            )
        )
    }

    override fun onSlowRegister(){
        Log.d("Kds", "MainActivity -> callListener -> onSlowRegister")
    }

    override fun networkHealth(stat: Map<String, *>, quality: Int) {
        channel.invokeMethod(CALL_QUALITY, mapOf(
            "quality" to quality,
            "stat" to stat,
        ))
    }

    override fun onAudioChanged(audioInfo: Map<String, Any>) {
        channel.invokeMethod(AUDIO_CHANGE, mapOf(
            "data" to audioInfo,
        ))
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

    override fun onSwitchBoardAnswer(sip: String) {
        channel.invokeMethod(
            SWITCHBOARD_ANSWER, mapOf(
                "sip" to sip,
            )
        )
    }

    override fun onVideoSize(width: Int, height: Int) {  }

    private val accountListener = object : OmiAccountListener {
        override fun onAccountStatus(online: Boolean) {
            Log.d("aaa", "Account status $online")
        }
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        try {
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

            Log.d("SDK", "onAttachedToEngine! ---- $applicationContext")

            OmiClient.getInstance(applicationContext!!)
            OmiClient.isAppReady = true;
            OmiClient.getInstance(applicationContext!!).addCallStateListener(this)
            OmiClient.getInstance(applicationContext!!).setDebug(false)
        } catch(e: Throwable) {
            e.printStackTrace()
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "action") {
            handleAction(call, result)
        }
    }

    private fun messageCall(type: Int): String {
        return when (type) {
//            0 -> "INVALID_UUID"
//            1 -> "INVALID_PHONE_NUMBER"
//            2 -> "SAME_PHONE_NUMBER_WITH_PHONE_REGISTER"
//            3 -> "MAX_RETRY"
//            4 -> "PERMISSION_DENIED"
//            5 -> "COULD_NOT_FIND_END_POINT"
//            6 -> "REGISTER_ACCOUNT_FAIL"
//            7 -> "START_CALL_FAIL"
//            8 -> "START_CALL_SUCCESS"
//            9 -> "HAVE_ANOTHER_CALL"
//            else -> "START_CALL_SUCCESS"
            200 -> "START_CALL_SUCCESS"
            400 -> "HAVE_ANOTHER_CALL"
            401 -> "INVALID_UUID"
            402 -> "INVALID_PHONE_NUMBER"
            403 -> "CAN_NOT_CALL_YOURSELF"
            404 -> "SWITCHBOARD_NOT_CONNECTED"
            405 -> "PERMISSION_DENIED"
            406 -> "PERMISSION_DENIED"
            407 -> "COULD_NOT_REGISTER_ACCOUNT"
            else -> "HAVE_ANOTHER_CALL"
        }
    }


    @Suppress("UNCHECKED_CAST")
    private fun handleAction(call: MethodCall, result: Result) {
        val data = call.arguments as HashMap<String, Any>
        val dataOmi = data["data"] as HashMap<String, Any>
        when (data["actionName"]) {
            START_SERVICES -> {
                OmiClient.getInstance(applicationContext!!).addAccountListener(accountListener)
                result.success(true)
            }
            GET_INITIAL_CALL -> {
                val callInfo = OmiClient.getInstance(applicationContext!!).getCurrentCallInfo()
                result.success(callInfo)
            }
            CONFIG_NOTIFICATION -> {
                val notificationIcon = dataOmi["notificationIcon"] as? String
                Log.d("dataOmi", "notificationIcon $dataOmi")
                val prefix = dataOmi["prefix"] as? String
                val incomingBackgroundColor = dataOmi["incomingBackgroundColor"] as? String
                val incomingAcceptButtonImage = dataOmi["incomingAcceptButtonImage"] as? String
                val incomingDeclineButtonImage = dataOmi["incomingDeclineButtonImage"] as? String
                val prefixMissedCallMessage = dataOmi["prefixMissedCallMessage"] as? String
                val backImage = dataOmi["backImage"] as? String
                val userImage = dataOmi["userImage"] as? String
                val userNameKey = dataOmi["userNameKey"] as? String
                val channelId = dataOmi["channelId"] as? String
                val missedCallTitle = dataOmi["missedCallTitle"] as? String
                val audioNotificationDescription = dataOmi["audioNotificationDescription"] as? String
                val videoNotificationDescription = dataOmi["videoNotificationDescription"] as? String
                val displayNameType = dataOmi["displayNameType"] as? String

                OmiClient.getInstance(applicationContext!!).configPushNotification(
                    showMissedCall = true,
                    notificationIcon = notificationIcon ?: "ic_notification",
                    notificationAvatar = userImage ?: "ic_inbound_avatar_notification",
                    fullScreenAvatar = userImage ?: "ic_inbound_avatar_fullscreen",
                    internalCallText = "Gọi nội bộ",
                    videoCallText = "Gọi Video",
                    inboundCallText = prefix,
                    unknownContactText = "Cuộc gọi không xác định",
                    showUUID = false,
                    inboundChannelId =  "${channelId}-inbound",
                    inboundChannelName = "Cuộc gọi đến",
                    missedChannelId =  "${channelId}-missed",
                    missedChannelName = "Cuộc gọi nhỡ",
                    displayNameType = userNameKey ?: "full_name",
                    notificationMissedCallPrefix = prefixMissedCallMessage ?: "Cuộc gọi nhỡ từ"
                )
                result.success(true)
            }
            INIT_CALL_USER_PASSWORD -> {
                mainScope.launch {
                    val userName = dataOmi["userName"] as? String
                    val password = dataOmi["password"] as? String
                    val realm = dataOmi["realm"] as? String
                    val host = dataOmi["host"] as? String
                    val isVideo = dataOmi["isVideo"] as? Boolean
                    val firebaseToken = dataOmi["fcmToken"] as String
                    if (userName != null && password != null && realm != null && host != null) {
//                        Log.d(
//                            "dataOmi",
//                            "INIT_CALL_API_KEY $firebaseToken "
//                        )
                        OmiClient.register(
                            userName,
                            password,
                            realm,
                            isVideo ?: true,
                            firebaseToken,
                            host
                        )

                    }
                    requestPermission(isVideo ?: true)
                    result.success(true)
                }
            }
            INIT_CALL_API_KEY -> {
                mainScope.launch {
                    var loginResult = false
                    val usrName = dataOmi["fullName"] as? String
                    val usrUuid = dataOmi["usrUuid"] as? String
                    val apiKey = dataOmi["apiKey"] as? String
                    val isVideo = dataOmi["isVideo"] as? Boolean
                    val phone = dataOmi["phone"] as? String
                    val firebaseToken = dataOmi["fcmToken"] as String
                    Log.d(
                        "dataOmi",
                        "INIT_CALL_API_KEY $firebaseToken "
                    )
                    withContext(Dispatchers.Default) {
                        try {
                            if (usrName != null && usrUuid != null && apiKey != null && phone != null) {
                                loginResult = OmiClient.registerWithApiKey(
                                    apiKey = apiKey,
                                    userName = usrName,
                                    uuid = usrUuid,
                                    phone = phone,
                                    isVideo ?: true,
                                    firebaseToken
                                )
                            }
                        } catch (_: Throwable) {

                        }
                    }
//                    requestPermission(isVideo ?: true)
                    result.success(loginResult)
                }
            }
            GET_INITIAL_CALL -> {
                result.success(false)
            }
            UPDATE_TOKEN -> {
                mainScope.launch {
                    val deviceTokenAndroid = dataOmi["fcmToken"] as String
                    withContext(Dispatchers.Default) {
                        try {
                            OmiClient.getInstance(applicationContext!!).updatePushToken(deviceTokenAndroid)
                        } catch (_: Throwable) {

                        }
                    }
                    result.success(true)
                }
            }
            START_CALL -> {
                val phoneNumber = dataOmi["phoneNumber"] as String
                val isVideo = dataOmi["isVideo"] as Boolean
                val startCallResult = OmiClient.getInstance(applicationContext!!).startCall(phoneNumber, isVideo)
                var statusCalltemp =  startCallResult.value as Int;
                if(startCallResult.value == 200 ){
                    statusCalltemp = 8
                }
                val dataSend = mapOf(
                    "status" to statusCalltemp ,
                    "_id" to "",
                    "message" to messageCall(startCallResult.value),
                )
                // Log.d(
                //     "dataOmi",
                //     "START_CALL $dataSend "
                // )
                val gson = Gson()
//                val dataSendResult = dataSend.entries.joinToString(", ") { (key, value) ->
//                    "$key: ${value ?: "null"}"
//                }

                val jsonData = gson.toJson(dataSend)
                result.success(jsonData)
            }
            JOIN_CALL -> {
                if(applicationContext != null) {
                    OmiClient.getInstance(applicationContext!!).pickUp()
                    result.success(true)
                }
            }
            END_CALL -> {
                var callResult: Any? = null
                if(isIncomming && !isAnserCall){
                    callResult =  OmiClient.getInstance(applicationContext!!).decline()
                } else {
                    callResult = OmiClient.getInstance(applicationContext!!).hangUp()
                }
                result.success(callResult)
            }
            TOGGLE_MUTE -> {
                mainScope.launch {
                    var newStatus: Boolean? = null
                    withContext(Dispatchers.Default) {
                        try {
                            newStatus = OmiClient.getInstance(applicationContext!!).toggleMute()
                        } catch (_: Throwable) {

                        }
                    }
                    result.success(newStatus)
                    channel.invokeMethod(MUTED, newStatus)
                }
            }
            TOGGLE_SPEAK -> {
                val newStatus = OmiClient.getInstance(applicationContext!!).toggleSpeaker()
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
                    OmiClient.getInstance(applicationContext!!).sendDtmf(characterCode)
                }
                result.success(true)
            }
            SWITCH_CAMERA -> {
                OmiClient.getInstance(applicationContext!!).switchCamera()
                channel.invokeMethod(CAMERA_STATUS, true)
            }
            TOGGLE_VIDEO -> {
                OmiClient.getInstance(applicationContext!!).toggleCamera()
            }
            GET_AUDIO -> {
                val inputs = OmiClient.getInstance(applicationContext!!).getAudioOutputs()
                result.success(inputs)
            }
            SET_AUDIO -> {
                val portType = dataOmi["portType"] as Int
                OmiClient.getInstance(applicationContext!!).setAudio(portType)
                result.success(true)
            }

            GET_CURRENT_AUDIO -> {
                val audio = OmiClient.getInstance(applicationContext!!).getCurrentAudio()
                result.success(listOf(audio))
            }
            START_CALL_WITH_UUID -> {
                mainScope.launch {
                    var callResult: OmiStartCallStatus? = null
                    withContext(Dispatchers.Default) {
                        try {
                            val uuid = dataOmi["usrUuid"] as String
                            val isVideo = dataOmi["isVideo"] as Boolean
                            callResult =
                                OmiClient.getInstance(applicationContext!!).startCallWithUuid(
                                    uuid = uuid,
                                    isVideo = isVideo
                                )
                        } catch (_: Throwable) {

                        }
                    }
                    result.success(callResult?.value ?: 0)
                }
            }
            LOG_OUT -> {
                ///implement later
                mainScope.launch {
                    withContext(Dispatchers.Default) {
                        try {
                            OmiClient.getInstance(applicationContext!!).logout()
                        } catch (_: Throwable) {

                        }
                    }
                    result.success(true)
                }
            }
            GET_CURRENT_USER -> {
                mainScope.launch {
                    var callResult: Any? = null
                    withContext(Dispatchers.Default) {
                        try {
                            callResult = OmiClient.getInstance(applicationContext!!).getCurrentUser()
                        } catch (_: Throwable) {

                        }
                    }
                    result.success(callResult)
                }
            }
            GET_GUEST_USER -> {
                mainScope.launch {
                    var callResult: Any? = null
                    withContext(Dispatchers.Default) {
                        try {
                            callResult = OmiClient.getInstance(applicationContext!!).getIncomingCallUser()
                        } catch (_: Throwable) {

                        }
                    }
                    result.success(callResult)
                }
            }
            GET_USER_INFO -> {
                mainScope.launch {
                    var callResult: Any? = null
                    withContext(Dispatchers.Default) {
                        try {
                            val phone = dataOmi["phone"] as String
                            callResult = OmiClient.getInstance(applicationContext!!).getUserInfo(phone)
                        } catch (_: Throwable) {

                        }
                    }
                    result.success(callResult)
                }
            }
            CHANGE_TRANSPORT -> {
                mainScope.launch {
                    try {
                        val type = dataOmi["type"] as String;
                         Log.d(
                             "dataOmi",
                             "CHANGE_TRANSPORT $type "
                         )
                        if(type == "UDP"){
                            OmiClient.getInstance(applicationContext!!).updateSipTransport(OmiSipTransport.UDP)
                        } else {
                            OmiClient.getInstance(applicationContext!!).updateSipTransport(OmiSipTransport.TCP)
                        }
                    } catch (_: Throwable) {

                    }
                }
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d("SDK", "onDetachedFromEngine!")
        channel.setMethodCallHandler(null)
        OmiClient.getInstance(applicationContext!!).removeCallStateListener(this)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d("SDK", "onAttachedToActivity!")
        binding.addOnNewIntentListener(this)
        activity = binding.activity as FlutterActivity
    }

    override fun onDetachedFromActivity() {
        Log.d("SDK", "onDetachedFromActivity!")
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.d("SDK", "onReattachedToActivityForConfigChanges!")
        binding.addOnNewIntentListener(this)
        activity = binding.activity as FlutterActivity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.d("SDK", "onDetachedFromActivityForConfigChanges!")
        activity = null
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

    private fun requestPermission(isVideo: Boolean) {
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
        if(activity!=null){
            requestPermissions(
                activity!!,
                permissions,
                0,
            )
        } else {
            Log.d("OMISDK", "requestPermission -> activity empty!")
        }
    }

    override fun onNewIntent(intent: Intent): Boolean {
        if (intent.hasExtra(SipServiceConstants.PARAM_NUMBER)) {
            //do your Stuff
            channel.invokeMethod(
                CLICK_MISSED_CALL,
                mapOf(
                    "callerNumber" to intent.getStringExtra(SipServiceConstants.PARAM_NUMBER),
                    "isVideo" to intent.getBooleanExtra(SipServiceConstants.PARAM_IS_VIDEO, false),
                ),
            )
        }
        return false
    }

}
