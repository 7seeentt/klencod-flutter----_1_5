// android/app/src/main/kotlin/com/example/echo_fx/MainActivity.kt
package com.example.echo_fx

import android.Manifest
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val CHANNEL = "echo_fx/audio"
    private var isRecording = false
    private var audioRecord: AudioRecord? = null
    private var audioThread: Thread? = null
    private var echoMix = 0.55f
    private var delayMs = 280

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "start" -> {
                            if (!hasMicPermission()) {
                                requestMicPermission()
                                result.error("PERMISSION", "تم طلب صلاحية المايك، اضغط تشغيل مرة أخرى", null)
                                return@setMethodCallHandler
                            }
                            echoMix = (call.argument<Double>("mix") ?: 0.55).toFloat()
                            delayMs = call.argument<Int>("delayMs") ?: 280
                            startEcho()
                            result.success(true)
                        }
                        "stop" -> {
                            stopEcho()
                            result.success(true)
                        }
                        "setEcho" -> {
                            echoMix = (call.argument<Double>("mix") ?: 0.55).toFloat()
                            delayMs = call.argument<Int>("delayMs") ?: 280
                            result.success(true)
                        }
                        "openDeveloper" -> result.success(true)
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
    }

    private fun hasMicPermission(): Boolean {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) ==
                PackageManager.PERMISSION_GRANTED
    }

    private fun requestMicPermission() {
        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), 101)
    }

    private fun startEcho() {
        if (isRecording) return
        try {
            isRecording = true
            val sampleRate = 44100
            val bufferSize = AudioRecord.getMinBufferSize(
                sampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT
            )

            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                sampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                bufferSize
            )

            val track = AudioTrack(
                AudioManager.STREAM_MUSIC,
                sampleRate,
                AudioFormat.CHANNEL_OUT_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                bufferSize,
                AudioTrack.MODE_STREAM
            )

            audioRecord?.startRecording()
            track.play()

            audioThread = thread {
                val buffer = ShortArray(bufferSize)
                var currentDelayBuf = ShortArray((sampleRate * delayMs) / 1000)
                var delayIndex = 0

                while (isRecording) {
                    val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                    if (read > 0) {
                        val targetSize = (sampleRate * delayMs) / 1000
                        if (currentDelayBuf.size != targetSize) {
                            currentDelayBuf = ShortArray(targetSize)
                            delayIndex = 0
                        }
                        for (i in 0 until read) {
                            val dry = buffer[i].toFloat()
                            val delayed = currentDelayBuf[delayIndex].toFloat()
                            val mixed = dry + (delayed * echoMix)
                            buffer[i] = mixed.coerceIn(-32768f, 32767f).toInt().toShort()
                            currentDelayBuf[delayIndex] = dry.toInt().toShort()
                            delayIndex = (delayIndex + 1) % currentDelayBuf.size
                        }
                        track.write(buffer, 0, read)
                    }
                }
                try {
                    track.stop()
                    track.release()
                } catch (_: Exception) {}
            }
        } catch (e: Exception) {
            isRecording = false
        }
    }

    private fun stopEcho() {
        isRecording = false
        try {
            audioThread?.join(1000)
        } catch (_: Exception) {}
        audioThread = null
        try {
            audioRecord?.stop()
            audioRecord?.release()
        } catch (_: Exception) {}
        audioRecord = null
    }
}