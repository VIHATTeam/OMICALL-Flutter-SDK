package com.example.calling

import androidx.core.app.ActivityCompat.requestPermissions
import android.app.Activity
import io.flutter.embedding.android.FlutterActivity
import vn.vihat.omicall.omicallsdk.OmicallsdkPlugin
import android.Manifest
import androidx.activity.result.contract.ActivityResultContracts
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import android.os.Bundle
import android.content.Intent
import android.util.Log

class MainActivity: FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            val callPermissions = arrayOf(
                Manifest.permission.RECORD_AUDIO,
            )
            if(!isGrantedPermission(Manifest.permission.RECORD_AUDIO)){
                requestPermissions(
                    this,
                    callPermissions,
                    0,
                )
            }
            OmicallsdkPlugin.onOmiIntent(this, intent)
        } catch (e: Throwable) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        OmicallsdkPlugin.onDestroy()
    }

    override fun onResume(){
        super.onResume()
        OmicallsdkPlugin.onResume(this);
    }

    fun isGrantedPermission(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        OmicallsdkPlugin.onRequestPermissionsResult(requestCode, permissions, grantResults, this)
    }

}
