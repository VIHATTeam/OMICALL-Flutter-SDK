package vn.vihat.omicall.omicallsdk

import android.Manifest
import android.content.Context
import android.content.Intent
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.net.ConnectivityManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
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
import vn.vihat.omicall.omicallsdk.videoCall.FLVideoTextureView
import vn.vihat.omicall.omisdk.pip.OmiPictureInPicture
import vn.vihat.omicall.omisdk.OmiAccountListener
import vn.vihat.omicall.omisdk.OmiClient
import vn.vihat.omicall.omisdk.OmiConsultState
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
    // Main.immediate: no extra frame when already on the main thread (all method calls are);
    // SupervisorJob: one failed action must not cancel the scope for every later action.
    private val mainScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val mainHandler = Handler(Looper.getMainLooper())
    private val gson = Gson()
    private var loadingResetJob: Job? = null
    private var isPipEnabled = false
    private var isRemoteVideoReadySent = false
    private val pipListener = OmiPictureInPicture.Listener { active ->
        runOnMain { channel.invokeMethod(PICTURE_IN_PICTURE_CHANGED, mapOf("isActive" to active)) }
    }
    private var isIncomming: Boolean = false
    private var callerNumberTemp: String = ""
    private var isAnserCall: Boolean = false
    private var isShouldCancelCall: Boolean = false
    private var isNeedLoading: Boolean = false

    override fun incomingReceived(callerId: Int?, phoneNumber: String?, isVideo: Boolean?) {
        isIncomming = true
        resetVideoState()
        callerNumberTemp = phoneNumber ?: ""
        runOnMain {
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
        applicationContext?.let {
            if (!AppUtils.isAppOnForeground(it)) return
            val activeCall = Utils.getActiveCall(it)
            if (activeCall != null) {
                activeCall.isShowed = true
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
        if (isVideo == true) {
            // Same moment as the Android-Client: attach both feeds as soon as the call connects
            FLVideoTextureView.attachAll()
            runOnMain { ensureVideoSpeaker() }
        }
        runOnMain {
            channel.invokeMethod(
                CALL_STATE_CHANGED, mapOf(
                    "callerNumber" to phoneNumber,
                    "status" to CallState.confirmed.value,
                    "isVideo" to isVideo,
                    "transactionId" to transactionId,
                    "incoming" to isIncomming
                )
            )
        }
        Log.d("omikit", "onCallEstablished: ")
    }

    override fun onCallEnd(callInfo: MutableMap<String, Any?>, statusCode: Int) {
        Log.d("SDK ====> CALL ACTION:::  ", "onCallEnd -> callInfo=$callInfo, statusCode=$statusCode")
        callInfo["status"] = CallState.disconnected.value
        callInfo["code_end_call"] = statusCode
        runOnMain {
            channel.invokeMethod(CALL_STATE_CHANGED, callInfo)
        }
        isIncomming = false
        isAnserCall = false
        resetVideoState()
    }

    override fun onConnecting() {
        runOnMain {
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
    }

    override fun onRinging(callerId: Int, transactionId: String?) {
        val callDirection = OmiClient.callDirection

        runOnMain {
            if (callDirection == "inbound") {
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
    }

    override fun onOutgoingStarted(callerId: Int, phoneNumber: String?, isVideo: Boolean?) {
        isIncomming = false
        resetVideoState()

        runOnMain {
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
    }

    override fun onRegisterCompleted(statusCode: Int) {
        // Your code to handle the registration completion
        Log.d("OMI Flutter", "OnRegisterCompleted")
    }

    override fun onDescriptionError() {
        Log.d("Kds", "IncomingCallActivity -> listener -> onDescriptionError!")
    }

    override fun networkHealth(stat: Map<String, *>, quality: Int) {
        val numLCN = stat["lcn"] as? Int
        numLCN?.let {
            isNeedLoading = it > 2
            if (isNeedLoading) {
                // Restart one timer instead of stacking a coroutine per quality report
                loadingResetJob?.cancel()
                loadingResetJob = mainScope.launch {
                    delay(15000)
                    isNeedLoading = false
                }
            }
        }
        runOnMain {
            channel.invokeMethod(CALL_QUALITY, mapOf(
                "quality" to quality,
                "stat" to stat,
                "isNeedLoading" to isNeedLoading
            ))
        }
    }

    override fun onAudioChanged(audioInfo: Map<String, Any>) {
        runOnMain {
            channel.invokeMethod(AUDIO_CHANGE, mapOf("data" to audioInfo))
        }
    }

    override fun onHold(isHold: Boolean) {
        runOnMain {
            channel.invokeMethod(HOLD, mapOf("isHold" to isHold))
        }
    }

    override fun onMuted(isMuted: Boolean) {
        runOnMain {
            channel.invokeMethod(MUTED, mapOf("isMuted" to isMuted))
        }
    }

    override fun onSwitchBoardAnswer(sip: String) {
        runOnMain {
            channel.invokeMethod(SWITCHBOARD_ANSWER, mapOf("sip" to sip))
        }
    }

    override fun onVideoSize(width: Int, height: Int) {
        FLVideoTextureView.updateRemoteSize(width, height)
        // First size of the call = remote video is decoding
        if (width > 0 && height > 0 && !isRemoteVideoReadySent) {
            isRemoteVideoReadySent = true
            runOnMain { channel.invokeMethod(REMOTE_VIDEO_READY, mapOf("width" to width, "height" to height)) }
        }
    }

    private fun resetVideoState() {
        isRemoteVideoReadySent = false
        FLVideoTextureView.resetRemoteSize()
    }

    /**
     * SDK workaround from the Android-Client: OmiClient.onCallStarted skips routing video calls to
     * the loudspeaker when a previous call ended abnormally. Idempotent when the SDK did route it.
     */
    private fun ensureVideoSpeaker() {
        val ctx = applicationContext ?: return
        try {
            val client = OmiClient.getInstance(ctx)
            if (!client.getSpeakerStatus()) {
                val am = ctx.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                val externalTypes = setOf(
                    AudioDeviceInfo.TYPE_WIRED_HEADSET,
                    AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
                    AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
                    AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
                )
                val hasExternal = am.getDevices(AudioManager.GET_DEVICES_OUTPUTS).any { it.type in externalTypes }
                if (!hasExternal) client.setAudio(2)
            }
            // Always sync the Flutter speaker button with the real route, like the client app
            channel.invokeMethod(SPEAKER, client.getSpeakerStatus())
        } catch (e: Exception) {
            Log.e("OMI Flutter", "ensureVideoSpeaker failed", e)
        }
    }

    override fun onConsultStateChanged(consultCallId: Int, state: OmiConsultState, statusCode: Int) {
        runOnMain {
            channel.invokeMethod(CONSULT_STATE_CHANGED, mapOf(
                "callId" to consultCallId,
                "state" to state.ordinal,
                "statusCode" to statusCode
            ))
        }
    }

    override fun onTransferStatus(callId: Int, statusCode: Int, isFinal: Boolean) {
        runOnMain {
            channel.invokeMethod(TRANSFER_STATUS, mapOf(
                "callId" to callId,
                "statusCode" to statusCode,
                "isFinal" to isFinal
            ))
        }
    }

    override fun onCallHoldChanged(callId: Int, isHold: Boolean) {
        runOnMain {
            channel.invokeMethod(CALL_HOLD_CHANGED, mapOf(
                "callId" to callId,
                "isHold" to isHold
            ))
        }
    }

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

            // SDK 2.5.17: getInstance now requires needRegister parameter
            // Set to false to prevent auto-registration (registration handled explicitly via initCall methods)
            OmiClient.getInstance(applicationContext!!, false)
            OmiClient.getInstance(applicationContext!!).addCallStateListener(this)
            OmiClient.getInstance(applicationContext!!).setDebug(false)
            OmiPictureInPicture.addListener(pipListener)
            // Late listener (screen opened after the first frame): refresh replays the event
            FLVideoTextureView.onRefreshed = {
                if (isRemoteVideoReadySent) runOnMain { channel.invokeMethod(REMOTE_VIDEO_READY, mapOf<String, Any>()) }
            }
            ProcessLifecycleOwner.get().lifecycle.addObserver(OmiClient.getInstance(applicationContext!!))
        } catch(e: Throwable) {
            e.printStackTrace()
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "action") {
            handleAction(call, result)
        } else {
            result.notImplemented()
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
            408 -> "NO_NETWORK"
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
                    val cm = applicationContext?.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
                    if (cm?.activeNetwork == null) {
                        result.success(gson.toJson(mapOf("status" to 600, "message" to "NETWORK_UNAVAILABLE")))
                        return@launch
                    }
                    val userName = dataOmi["userName"] as? String
                    val password = dataOmi["password"] as? String
                    val realm = dataOmi["realm"] as? String
                    // Optional: null/blank lets the SDK use its default SIP host
                    val host = (dataOmi["host"] as? String)?.takeIf { it.isNotBlank() }
                    val isVideo = dataOmi["isVideo"] as? Boolean
                    val firebaseToken = dataOmi["fcmToken"] as? String
                    val projectId = dataOmi["projectId"] as? String ?: ""
                    if (userName == null || password == null || realm == null || firebaseToken == null) {
                        result.success(gson.toJson(mapOf("status" to 400, "message" to "MISSING_PARAMS")))
                        return@launch
                    }
                    val registerResult = OmiClient.register(
                        userName, password, realm, isVideo ?: true, firebaseToken, host, projectId
                    )
                    requestPermission(isVideo ?: true)
                    val response = if (registerResult) {
                        mapOf("status" to 200, "message" to "INIT_SUCCESS")
                    } else {
                        mapOf("status" to 500, "message" to "INIT_FAILED")
                    }
                    result.success(gson.toJson(response))
                }
            }
            INIT_CALL_API_KEY -> {
                mainScope.launch {
                    val cm = applicationContext?.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
                    if (cm?.activeNetwork == null) {
                        result.success(gson.toJson(mapOf("status" to 600, "message" to "NETWORK_UNAVAILABLE")))
                        return@launch
                    }
                    val usrName = dataOmi["fullName"] as? String
                    val usrUuid = dataOmi["usrUuid"] as? String
                    val apiKey = dataOmi["apiKey"] as? String
                    val isVideo = dataOmi["isVideo"] as? Boolean
                    val phone = dataOmi["phone"] as? String
                    val firebaseToken = dataOmi["fcmToken"] as? String
                    val projectId = dataOmi["projectId"] as? String ?: ""
                    if (usrName == null || usrUuid == null || apiKey == null || phone == null || firebaseToken == null) {
                        result.success(gson.toJson(mapOf("status" to 400, "message" to "MISSING_PARAMS")))
                        return@launch
                    }
                    var loginResult = false
                    withContext(Dispatchers.Default) {
                        try {
                            loginResult = OmiClient.registerWithApiKey(
                                apiKey = apiKey,
                                userName = usrName,
                                uuid = usrUuid,
                                phone = phone,
                                isVideo ?: true,
                                firebaseToken,
                                projectId
                            )
                        } catch (_: Throwable) {}
                    }
                    val response = if (loginResult) {
                        mapOf("status" to 200, "message" to "INIT_SUCCESS")
                    } else {
                        mapOf("status" to 500, "message" to "INIT_FAILED")
                    }
                    result.success(gson.toJson(response))
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
                // Non-blocking SIP command (no thread hop needed); the new state arrives via onHold → HOLD
                try {
                    OmiClient.getInstance(applicationContext!!).toggleHold()
                    result.success(false)
                } catch (e: Exception) {
                    result.error("TOGGLE_HOLD_EXCEPTION", "Exception occurred: ${e.message}", e)
                }
            }
            TOGGLE_SPEAK -> {
                val newStatus = OmiClient.getInstance(applicationContext!!).toggleSpeaker()
                result.success(newStatus)
                channel.invokeMethod(SPEAKER, newStatus)
            }
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
                result.success(true)
            }
            TOGGLE_VIDEO -> {
                OmiClient.getInstance(applicationContext!!).toggleCamera()
                result.success(true)
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
                        val type = dataOmi["type"] as String
                        Log.d("dataOmi", "CHANGE_TRANSPORT $type")
                        if (type == "UDP") {
                            OmiClient.getInstance(applicationContext!!).updateSipTransport(OmiSipTransport.UDP)
                        } else {
                            OmiClient.getInstance(applicationContext!!).updateSipTransport(OmiSipTransport.TCP)
                        }
                    } catch (_: Throwable) {}
                    result.success(true)
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
            REJECT_CALL -> {
                val client = OmiClient.getInstance(applicationContext!!)
                if (isIncomming && !isAnserCall) {
                    client.declineWithCode(true) // 486 Busy Here
                } else {
                    client.hangUp()
                }
                result.success(true)
            }
            DROP_CALL -> {
                val client = OmiClient.getInstance(applicationContext!!)
                if (isIncomming && !isAnserCall) {
                    client.declineWithCode(false) // 603 Decline, stops ringing on all devices
                } else {
                    client.hangUp()
                }
                result.success(true)
            }
            START_CONSULT_CALL -> {
                val extension = dataOmi["extension"] as? String ?: ""
                OmiClient.getInstance(applicationContext!!).startConsultCall(
                    extension,
                    extraHeadersOf(dataOmi)
                ) { status ->
                    runOnMain { result.success(status.value) }
                }
            }
            COMPLETE_CONSULT_TRANSFER -> {
                result.success(
                    OmiClient.getInstance(applicationContext!!).completeConsultTransfer(extraHeadersOf(dataOmi))
                )
            }
            CANCEL_CONSULT -> {
                result.success(OmiClient.getInstance(applicationContext!!).cancelConsult())
            }
            IS_CONSULTING -> {
                result.success(OmiClient.getInstance(applicationContext!!).isConsulting())
            }
            IS_CONSULT_ORIGINAL_ENDED -> {
                result.success(OmiClient.getInstance(applicationContext!!).isConsultOriginalEnded())
            }
            SET_PICTURE_IN_PICTURE -> {
                // The SDK arms PiP only while a video call is up and disarms it at call end
                isPipEnabled = dataOmi["enabled"] as? Boolean ?: false
                activity?.let { OmiPictureInPicture.setEnabled(it, isPipEnabled) }
                result.success(applicationContext?.let { OmiPictureInPicture.isSupported(it) } ?: false)
            }
            // Device info — same sources and fallbacks as the React Native SDK
            GET_PROJECT_ID -> {
                val projectId = OmiClient.registrationInfo?.projectId
                    ?: try { com.google.firebase.FirebaseApp.getInstance().options.projectId } catch (_: Exception) { null }
                result.success(projectId)
            }
            GET_SIP_INFO -> {
                val client = OmiClient.getInstance(applicationContext!!)
                val user = client.getSipUser()
                val realm = client.getSipRealm()
                result.success(if (!user.isNullOrEmpty() && !realm.isNullOrEmpty()) "$user@$realm" else user)
            }
            GET_APP_ID -> {
                val ctx = applicationContext!!
                val appId = OmiClient.getInstance(ctx).getAppId().takeIf { it.isNotEmpty() }
                    ?: OmiClient.registrationInfo?.appId
                    ?: ctx.packageName
                result.success(appId)
            }
            GET_DEVICE_ID -> {
                val ctx = applicationContext!!
                val deviceId = OmiClient.getInstance(ctx).getDeviceId().takeIf { it.isNotEmpty() }
                    ?: OmiClient.registrationInfo?.deviceId
                    ?: try { Settings.Secure.getString(ctx.contentResolver, Settings.Secure.ANDROID_ID) } catch (_: Exception) { null }
                result.success(deviceId)
            }
            GET_FCM_TOKEN -> {
                val token = OmiClient.registrationInfo?.firebaseToken
                if (token != null) {
                    result.success(token)
                } else {
                    try {
                        com.google.firebase.messaging.FirebaseMessaging.getInstance().token
                            .addOnSuccessListener { result.success(it) }
                            .addOnFailureListener { result.success(null) }
                    } catch (_: Exception) {
                        result.success(null)
                    }
                }
            }
            GET_VOIP_TOKEN -> result.success(null) // iOS only
            GET_OMI_DEVICES -> {
                mainScope.launch {
                    val devices = withContext(Dispatchers.IO) {
                        try { OmiClient.getInstance(applicationContext!!).getOmiDevices() } catch (_: Throwable) { emptyList() }
                    }
                    result.success(devices.map {
                        mapOf(
                            "device_id" to it.deviceId,
                            "token" to it.token,
                            "device_type" to it.deviceType,
                            "voip_token" to it.voipToken,
                            "app_id" to it.appId,
                            "created_time" to it.createdTime,
                            "project_id" to it.projectId,
                            "sipNumber" to it.sipNumber
                        )
                    })
                }
            }
            IS_CURRENT_DEVICE_REGISTERED -> {
                mainScope.launch {
                    result.success(withContext(Dispatchers.IO) {
                        try { OmiClient.getInstance(applicationContext!!).isCurrentDeviceRegistered() } catch (_: Throwable) { false }
                    })
                }
            }
            NEEDS_RE_LOGIN -> {
                mainScope.launch {
                    result.success(withContext(Dispatchers.IO) {
                        try { OmiClient.getInstance(applicationContext!!).needsReLogin() } catch (_: Throwable) { false }
                    })
                }
            }
            GET_ACTIVE_CALLS -> {
                val calls = OmiClient.getInstance(applicationContext!!).getActiveCalls().map {
                    mapOf(
                        "callId" to it.callId,
                        "uuid" to it.uuid,
                        "number" to it.number,
                        "state" to it.state,
                        "isHold" to it.isHold,
                        "isConsult" to it.isConsult
                    )
                }
                result.success(calls)
            }
            // Actions without an Android implementation (iOS-only, or legacy): reply so the
            // Dart Future completes instead of hanging forever.
            else -> result.success(null)
        }
    }

    /** Run on the main thread; inline when already there to avoid a message-loop hop. */
    private fun runOnMain(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) block() else mainHandler.post(block)
    }

    /** Flutter sends `extraHeaders` as Map<String, Any?>; keep only string values. */
    private fun extraHeadersOf(dataOmi: Map<String, Any>): Map<String, String>? {
        val raw = dataOmi["extraHeaders"] as? Map<*, *> ?: return null
        return raw.entries
            .mapNotNull { (k, v) -> if (k is String && v is String) k to v else null }
            .toMap()
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        OmiClient.getInstance(applicationContext!!).removeCallStateListener(this)
        OmiPictureInPicture.removeListener(pipListener)
        FLVideoTextureView.onRefreshed = null
        mainScope.cancel()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d("SDK", "onAttachedToActivity!")
        binding.addOnNewIntentListener(this)
        activity = binding.activity as FlutterActivity
        // Recreated Activity: PiP must be re-armed on the new instance
        if (isPipEnabled) OmiPictureInPicture.setEnabled(binding.activity, true)
    }

    override fun onDetachedFromActivity() {
        Log.d("SDK", "onDetachedFromActivity!")
        activity?.let { if (isPipEnabled) OmiPictureInPicture.setEnabled(it, false) }
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.d("SDK", "onReattachedToActivityForConfigChanges!")
        binding.addOnNewIntentListener(this)
        activity = binding.activity as FlutterActivity
        if (isPipEnabled) OmiPictureInPicture.setEnabled(binding.activity, true)
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

        /** Forward from the host `Activity.onUserLeaveHint()` (PiP on Android 8-11). */
        fun onUserLeaveHint(activity: android.app.Activity) {
            OmiPictureInPicture.onUserLeaveHint(activity)
        }

        /** Forward from the host `Activity.onPictureInPictureModeChanged(isInPip, newConfig)`. */
        fun onPictureInPictureModeChanged(isInPip: Boolean) {
            OmiPictureInPicture.onPictureInPictureModeChanged(isInPip)
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

        // Android 13+ (API 33) - Required for notifications
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions = permissions.plus(Manifest.permission.POST_NOTIFICATIONS)
        }

        // Android 14+ (API 34) - Required for foreground service types (SDK 2.5.17)
        // CRITICAL: These permissions are required for incoming calls on Android 14+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            permissions = permissions.plus(Manifest.permission.FOREGROUND_SERVICE_MICROPHONE)
            permissions = permissions.plus(Manifest.permission.FOREGROUND_SERVICE_PHONE_CALL)
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
