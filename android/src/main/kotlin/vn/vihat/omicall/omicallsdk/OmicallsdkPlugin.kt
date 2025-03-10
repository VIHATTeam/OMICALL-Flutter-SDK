package vn.vihat.omicall.omicallsdk

import android.Manifest
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import kotlinx.coroutines.*
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
import vn.vihat.omicall.omicallsdk.videoCall.FLLocalCameraFactory
import vn.vihat.omicall.omicallsdk.videoCall.FLRemoteCameraFactory
import vn.vihat.omicall.omisdk.OmiAccountListener
import vn.vihat.omicall.omisdk.OmiClient
import vn.vihat.omicall.omisdk.OmiListener
import vn.vihat.omicall.omisdk.service.NotificationService
import vn.vihat.omicall.omisdk.utils.OmiSDKUtils
import vn.vihat.omicall.omisdk.utils.OmiStartCallStatus
import vn.vihat.omicall.omisdk.utils.SipServiceConstants
import vn.vihat.omicall.omisdk.utils.OmiSipTransport
import vn.vihat.omicall.omisdk.utils.AppUtils
import vn.vihat.omicall.omisdk.utils.Utils
import java.util.*
import com.google.gson.Gson
import androidx.lifecycle.ProcessLifecycleOwner

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
    private var isShouldCancelCall: Boolean = false
    private var isNeedLoading: Boolean = false

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
        applicationContext?.let {
            if(!AppUtils.isAppOnForeground(it)) {
                return
            }
            val activeCall = Utils.getActiveCall(it)
            if(activeCall != null ) {
                activeCall?.isShowed = true
                Utils.saveActiveCall(it, activeCall)
            }
        }
    }

    override fun onFcmReceived(uuid: String, userName: String, avatar: String) {}


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
        callInfo["code_end_call"] = statusCode
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

    override fun onRegisterCompleted(statusCode: Int) {
        // Your code to handle the registration completion
        Log.d("OMI Flutter", "OnRegisterCompleted")
    }

    override fun onDescriptionError() {
        Log.d("Kds", "IncomingCallActivity -> listener -> onDescriptionError!")
    }

    override fun networkHealth(stat: Map<String, *>, quality: Int) {
        Log.d("Kds", "zzzzz -> numLCN -> $stat ")
        if(stat != null){
            val numLCN = stat["lcn"] as? Int
            Log.d("Kds", "networkHealth -> numLCN -> $numLCN ")
            numLCN?.let {
                isNeedLoading = it > 2
                if (isNeedLoading) {
                    mainScope.launch {
                        delay(15000)
                        isNeedLoading = false
                    }
                }
            }
        }

//        Log.d("Kds", "zzzzz -> numLCN -> $stat ")

        channel.invokeMethod(CALL_QUALITY, mapOf(
            "quality" to quality,
            "stat" to stat,
            "isNeedLoading" to isNeedLoading
        ))
    }

    override fun onAudioChanged(audioInfo: Map<String, Any>) {
        channel.invokeMethod(AUDIO_CHANGE, mapOf(
            "data" to audioInfo,
        ))
    }

    override fun onHold(isHold: Boolean) {
        channel.invokeMethod(
            HOLD, mapOf(
                "isHold" to isHold,
            )
        )
        Log.d("omikit", "onHold: $isHold")
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
            OmiClient.getInstance(applicationContext!!).addCallStateListener(this)
            OmiClient.getInstance(applicationContext!!).setDebug(false)
            ProcessLifecycleOwner.get().lifecycle.addObserver(OmiClient.getInstance(applicationContext!!))
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
            200 -> "START_CALL_SUCCESS"
            400 -> "HAVE_ANOTHER_CALL"
            401 -> "INVALID_UUID"
            402 -> "INVALID_PHONE_NUMBER"
            403 -> "CAN_NOT_CALL_YOURSELF"
            404 -> "SWITCHBOARD_NOT_CONNECTED"
            405 -> "PERMISSION_DENIED"
            406 -> "PERMISSION_DENIED"
            407 -> "SWITCHBOARD_REGISTERING"
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
                val appRepresentName = dataOmi["representName"] as? String
                val displayNameType = dataOmi["displayNameType"] as? String
                val isUseIntentFilter = dataOmi["isUseIntentFilter"] as? Boolean

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
                    notificationMissedCallPrefix = prefixMissedCallMessage ?: "Cuộc gọi nhỡ từ",
                    representName= appRepresentName ?: "",
                    useIntentFilter= isUseIntentFilter ?: true
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
                    val firebaseToken = dataOmi["fcmToken"] as? String
                    val projectId = dataOmi["projectId"] as? String ?: ""
                    if (userName != null && password != null && realm != null && host != null && firebaseToken != null ) {
                            OmiClient.register(
                                userName,
                                password,
                                realm,
                                isVideo ?: true,
                                firebaseToken,
                                host,
                                projectId
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
                    val firebaseToken = dataOmi["fcmToken"] as? String
                    val projectId = dataOmi["projectId"] as? String ?: ""

                    withContext(Dispatchers.Default) {
                        try {
                            if (usrName != null && usrUuid != null && apiKey != null && phone != null && firebaseToken != null) {
                                loginResult = OmiClient.registerWithApiKey(
                                    apiKey = apiKey,
                                    userName = usrName,
                                    uuid = usrUuid,
                                    phone = phone,
                                    isVideo ?: true,
                                    firebaseToken,
                                    projectId
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
            START_CALL -> {
                val phoneNumber = dataOmi["phoneNumber"] as String
                val isVideo = dataOmi["isVideo"] as Boolean
                val startCallResult = OmiClient.getInstance(applicationContext!!).startCall(phoneNumber, isVideo)
                var statusCalltemp =  startCallResult.value as Int;

                if(startCallResult.value == 200 || startCallResult.value == 407 ){
                    statusCalltemp = 8
                }

                val dataSend = mapOf(
                    "status" to statusCalltemp ,
                    "_id" to "",
                    "message" to messageCall(startCallResult.value),
                )

                val gson = Gson()

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
            TOGGLE_HOLD -> {
                mainScope.launch {
                    try {
                        val rawResult = withContext(Dispatchers.IO) {
                            OmiClient.getInstance(applicationContext!!).toggleHold()
                        }
                        println("Raw result from toggleHold(): $rawResult")
                        // Nếu rawResult là Unit, gán false; nếu không, ép sang Boolean (nếu có thể).
                        val newStatus = if (rawResult == Unit) false else rawResult as? Boolean ?: false
                        println("New status after evaluation: $newStatus")
                        result.success(newStatus)
//                        channel.invokeMethod(HOLD, newStatus)
                    } catch (e: Exception) {
                        result.error("TOGGLE_HOLD_EXCEPTION", "Exception occurred: ${e.message}", e)
                    }
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
                    OmiClient.getInstance(applicationContext!!).sendDtmf(characterCode.toString())
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
            TRANSFER_CALL -> {
                mainScope.launch {
                    val transferResult = withContext(Dispatchers.Default) {
                        try {
                            val phone = dataOmi["phoneNumber"] as String
                            OmiClient.getInstance(applicationContext!!).forwardCallTo(phone)
                            true
                        } catch (_: Throwable) {
                            false
                        }
                    }
                    result.success(transferResult)
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
        
        // Current not use it 
        fun onResume(applicationContext: Context ) {
             applicationContext?.let { context ->
                OmiClient.isAppReady = true
             }
        }

        fun onOmiIntent(applicationContext: Context , intent: Intent)  {
            applicationContext?.let { context ->
                val isIncomingCall = intent.getBooleanExtra(SipServiceConstants.ACTION_IS_INCOMING_CALL, false)
                val isReopenCall = intent.getBooleanExtra(SipServiceConstants.ACTION_REOPEN_CALL, false)
                val isAcceptedCall = intent.getBooleanExtra(SipServiceConstants.ACTION_ACCEPT_INCOMING_CALL, false)
                val isMissedCall = intent.getBooleanExtra(SipServiceConstants.PARAM_IS_MISSED_CALL, false)

                if (isIncomingCall) {
                    //case gọi đến
                    if (isAcceptedCall) {
                        //case bấm nút pickup trên thông báo cuộc gọi đến
                        // cần gọi pickup
                        OmiClient.getInstance(context).pickUp()
                        return
                    }

                    if (isReopenCall) {
                        //case bấm vào thông báo calling khi cuộc gọi đã được accept
                        // xử lý giao diện của cuộc gọi đang diễn ra
                        return
                    }
                    //Khi không thoả 2 điều kiện trên thì là cuộc gọi đến chưa được accept, bao gồm:
                    //case bấm vào body thông báo cuộc gọi đến
                    //case bấm vào thông báo calling khi cuộc gọi đang ở trạng thái early
                    //cần show nút nghe máy và nút từ chối
                    return
                } else {
                    //case gọi đi
                    //trường hợp này chỉ xảy ra khi bấm vào thông báo calling khi gọi đi
                    if(isReopenCall) {
                        // case cuộc gọi đã được accept
                        // xử lý giao diện của cuộc gọi đang diễn ra
                    } else {
                        // case cuộc gọi chưa được accept
                        // cần xử lý ui bình thường như cuộc gọi đi khi đang early
                    }
                }
            }
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
        val isIncomingCall = intent.getBooleanExtra(SipServiceConstants.ACTION_IS_INCOMING_CALL, false)
        val isReopenCall = intent.getBooleanExtra(SipServiceConstants.ACTION_REOPEN_CALL, false)
        val isAcceptedCall = intent.getBooleanExtra(SipServiceConstants.ACTION_ACCEPT_INCOMING_CALL, false)
        val isMissedCall = intent.getBooleanExtra(SipServiceConstants.PARAM_IS_MISSED_CALL, false)

        if (isMissedCall && !isIncomingCall ){
            channel.invokeMethod(CLICK_MISSED_CALL,
                mapOf(
                    "callerNumber" to intent.getStringExtra(SipServiceConstants.PARAM_NUMBER),
                    "isVideo" to intent.getBooleanExtra(SipServiceConstants.PARAM_IS_VIDEO, false)),
                )
                return true
        }
        return false
    }


}
