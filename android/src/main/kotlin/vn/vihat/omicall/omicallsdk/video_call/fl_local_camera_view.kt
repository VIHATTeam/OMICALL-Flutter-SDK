package vn.vihat.omicall.omicallsdk.video_call

import android.app.ActionBar.LayoutParams
import android.content.Context
import android.graphics.Color
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.view.marginLeft

import io.flutter.plugin.platform.PlatformView

internal class FLLocalCameraView(context: Context, id: Int, creationParams: Map<String?, Any?>?) :
    PlatformView {
    private val view: View

    override fun getView(): View {
        return view
    }

    override fun dispose() {}

    init {
        view = LinearLayout(context)
        view.orientation = LinearLayout.VERTICAL
        val view1 = LinearLayout(context)
        view1.orientation = LinearLayout.HORIZONTAL
        val view1Param = LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT,
            1.0f,
        )
        view1.setBackgroundColor(Color.rgb(255, 0, 0))
        val text1Param = LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT,LayoutParams.WRAP_CONTENT);
        text1Param.setMargins(10, 0,0,0)
        val tex1 = TextView(context)
        tex1.text = creationParams?.get("title") as? String
        view1.addView(tex1, text1Param)
        view.addView(view1, view1Param)
        val view2 = View(context)
        val view2Param = LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT,
            1.0f,
        )
        view2.setBackgroundColor(Color.rgb(255, 113, 0))
        view.addView(view2, view2Param)
    }
}