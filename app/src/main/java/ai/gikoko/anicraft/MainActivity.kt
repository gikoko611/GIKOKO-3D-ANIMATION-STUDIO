package ai.gikoko.anicraft

import android.app.Activity
import android.graphics.*
import android.os.Bundle
import android.provider.MediaStore
import android.content.ContentValues
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.widget.*
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

private data class Stroke(val points: MutableList<PointF>, val color: Int, val width: Float)

class MainActivity : Activity() {
    private val frames = mutableListOf(mutableListOf<Stroke>())
    private var frameIndex = 0
    private lateinit var canvasView: DrawingView
    private lateinit var status: TextView
    private var brushColor = Color.BLACK
    private val brushWidth = 6f

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = Color.rgb(16, 18, 25)
        window.navigationBarColor = Color.rgb(16, 18, 25)
        buildUi()
    }

    private fun buildUi() {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.rgb(20, 22, 29))
            setPadding(12, 10, 12, 10)
        }
        root.addView(TextView(this).apply {
            text = "ANICRAFT  •  2D ANIMATION STUDIO"
            setTextColor(Color.rgb(238, 194, 105))
            textSize = 16f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER_VERTICAL
            setPadding(6, 8, 6, 14)
        })
        val actions = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER }
        addButton(actions, "Undo") { undo() }
        addButton(actions, "Clear") { frames[frameIndex].clear(); canvasView.invalidate(); updateStatus("Frame cleared") }
        addButton(actions, "Save") { saveProject() }
        addButton(actions, "PNG") { exportPng() }
        root.addView(actions)

        canvasView = DrawingView()
        root.addView(FrameLayout(this).apply {
            setBackgroundColor(Color.WHITE)
            addView(canvasView, FrameLayout.LayoutParams(-1, -1))
        }, LinearLayout.LayoutParams(-1, 0, 1f).apply { topMargin = 12; bottomMargin = 12 })

        val tools = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER }
        addButton(tools, "Black") { brushColor = Color.BLACK; updateStatus("Black brush") }
        addButton(tools, "Red") { brushColor = Color.RED; updateStatus("Red brush") }
        addButton(tools, "Blue") { brushColor = Color.BLUE; updateStatus("Blue brush") }
        addButton(tools, "Eraser") { brushColor = Color.WHITE; updateStatus("Eraser") }
        root.addView(tools)

        val timeline = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER }
        addButton(timeline, "Prev") { selectFrame((frameIndex - 1).coerceAtLeast(0)) }
        addButton(timeline, "+ Frame") { frames.add(mutableListOf()); selectFrame(frames.lastIndex) }
        addButton(timeline, "Next") { selectFrame((frameIndex + 1).coerceAtMost(frames.lastIndex)) }
        root.addView(timeline)

        status = TextView(this).apply {
            text = "Frame 1 / 1  •  Offline"
            setTextColor(Color.LTGRAY)
            textSize = 12f
            gravity = Gravity.CENTER
            setPadding(4, 8, 4, 4)
        }
        root.addView(status)
        setContentView(root)
    }

    private fun addButton(parent: LinearLayout, label: String, action: () -> Unit) {
        val button = Button(this).apply {
            text = label
            textSize = 11f
            isAllCaps = false
            setTextColor(Color.WHITE)
            backgroundTintList = android.content.res.ColorStateList.valueOf(Color.rgb(67, 55, 39))
            setOnClickListener { action() }
        }
        parent.addView(button, LinearLayout.LayoutParams(0, 46, 1f).apply { setMargins(2, 2, 2, 2) })
    }

    private fun selectFrame(index: Int) {
        frameIndex = index.coerceIn(0, frames.lastIndex)
        canvasView.invalidate()
        updateStatus("Ready")
    }
    private fun undo() {
        if (frames[frameIndex].isNotEmpty()) {
            frames[frameIndex].removeAt(frames[frameIndex].lastIndex)
            canvasView.invalidate()
            updateStatus("Undo")
        }
    }
    private fun updateStatus(message: String) {
        status.text = "Frame ${frameIndex + 1} / ${frames.size}  •  $message  •  Offline"
    }

    private fun saveProject() {
        try {
            val project = JSONObject().put("format", "anicraft-android-draft").put("version", 1)
            val frameArray = JSONArray()
            frames.forEach { frame ->
                val strokeArray = JSONArray()
                frame.forEach { stroke ->
                    val points = JSONArray()
                    stroke.points.forEach { p -> points.put(JSONObject().put("x", p.x).put("y", p.y)) }
                    strokeArray.put(JSONObject().put("color", stroke.color).put("width", stroke.width).put("points", points))
                }
                frameArray.put(strokeArray)
            }
            project.put("frames", frameArray)
            val file = File(getExternalFilesDir(null), "AniCraft-project.json")
            file.writeText(project.toString())
            updateStatus("Saved locally")
            Toast.makeText(this, "Project saved in app storage", Toast.LENGTH_SHORT).show()
        } catch (e: Exception) { updateStatus("Save failed: ${e.message}") }
    }

    private fun exportPng() {
        try {
            val bitmap = Bitmap.createBitmap(1080, 1080, Bitmap.Config.ARGB_8888)
            val c = Canvas(bitmap)
            c.drawColor(Color.WHITE)
            c.save()
            c.scale(1080f / canvasView.width.coerceAtLeast(1), 1080f / canvasView.height.coerceAtLeast(1))
            drawStrokes(c, frames[frameIndex])
            c.restore()
            val stamp = SimpleDateFormat("yyyyMMdd-HHmmss", Locale.US).format(Date())
            val name = "AniCraft-frame-${frameIndex + 1}-$stamp.png"
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, name)
                put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/AniCraft")
            }
            val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values) ?: error("Image creation failed")
            contentResolver.openOutputStream(uri)?.use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) } ?: error("Image output failed")
            bitmap.recycle()
            updateStatus("PNG exported to Pictures/AniCraft")
        } catch (e: Exception) { updateStatus("Export failed: ${e.message}") }
    }

    private fun drawStrokes(canvas: Canvas, strokes: List<Stroke>) {
        strokes.forEach { stroke ->
            if (stroke.points.isEmpty()) return@forEach
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = stroke.color; style = Paint.Style.STROKE; strokeWidth = stroke.width
                strokeCap = Paint.Cap.ROUND; strokeJoin = Paint.Join.ROUND
            }
            val path = Path()
            path.moveTo(stroke.points[0].x, stroke.points[0].y)
            stroke.points.drop(1).forEach { path.lineTo(it.x, it.y) }
            canvas.drawPath(path, paint)
        }
    }

    private inner class DrawingView : View(this@MainActivity) {
        private val paper = Paint().apply { color = Color.WHITE }
        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paper)
            drawStrokes(canvas, frames[frameIndex])
        }
        override fun onTouchEvent(event: MotionEvent): Boolean {
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    frames[frameIndex].add(Stroke(mutableListOf(PointF(event.x, event.y)), brushColor, brushWidth))
                    parent?.requestDisallowInterceptTouchEvent(true)
                    invalidate()
                    return true
                }
                MotionEvent.ACTION_MOVE -> {
                    val stroke = frames[frameIndex].lastOrNull() ?: return true
                    for (i in 0 until event.historySize) stroke.points.add(PointF(event.getHistoricalX(i), event.getHistoricalY(i)))
                    stroke.points.add(PointF(event.x, event.y))
                    invalidate()
                    return true
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> { performClick(); return true }
            }
            return true
        }
        override fun performClick(): Boolean { super.performClick(); return true }
    }
}
