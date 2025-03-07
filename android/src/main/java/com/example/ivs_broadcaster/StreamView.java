package com.example.ivs_broadcaster;


import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.Matrix;
import android.graphics.SurfaceTexture;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.params.StreamConfigurationMap;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.util.Size;
import android.view.Surface;
import android.view.TextureView;
import android.view.View;
import android.widget.LinearLayout;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;

import com.amazonaws.ivs.broadcast.AudioDevice;
import com.amazonaws.ivs.broadcast.BroadcastConfiguration;
import com.amazonaws.ivs.broadcast.BroadcastException;
import com.amazonaws.ivs.broadcast.BroadcastSession;
import com.amazonaws.ivs.broadcast.Device;
import com.amazonaws.ivs.broadcast.ImagePreviewView;
import com.amazonaws.ivs.broadcast.Presets;
import com.amazonaws.ivs.broadcast.SurfaceSource;
import com.amazonaws.ivs.broadcast.TransmissionStats;
import com.google.gson.Gson;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.platform.PlatformView;

public class StreamView implements PlatformView, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private final LinearLayout layout;
    private EventChannel.EventSink eventSink;
    private BroadcastSession broadcastSession;
    private AudioDevice audioDevice;
    private final Context context;
    private final Handler mainHandler;

    private String streamUrl;
    private String streamKey;
    private boolean isMuted = false;

    StreamView(Context context, BinaryMessenger messenger) {
        this.context = context;
        layout = new LinearLayout(context);
        mainHandler = new Handler(Looper.getMainLooper());

        MethodChannel methodChannel = new MethodChannel(messenger, "ivs_broadcaster");
        EventChannel eventChannel = new EventChannel(messenger, "ivs_broadcaster_event");

        methodChannel.setMethodCallHandler(this);
        eventChannel.setStreamHandler(this);
    }

    @Override
    public View getView() {
        return layout;
    }

    @Override
    public void dispose() {
        stopBroadcast();
        releaseCamera();
    }

    // Define constants for method names
    private static final String METHOD_START_PREVIEW = "startPreview";
    private static final String METHOD_START_BROADCAST = "startBroadcast";
    private static final String METHOD_GET_CAMERA_ZOOM_FACTOR = "getCameraZoomFactor";
    private static final String METHOD_ZOOM_CAMERA = "zoomCamera";
    private static final String METHOD_UPDATE_CAMERA_LENS = "updateCameraLens";
    private static final String METHOD_MUTE = "mute";
    private static final String METHOD_IS_MUTED = "isMuted";
    private static final String METHOD_CHANGE_CAMERA = "changeCamera";
    private static final String METHOD_GET_AVAILABLE_CAMERA_LENS = "getAvailableCameraLens";
    private static final String METHOD_STOP_BROADCAST = "stopBroadcast";
    private static final String METHOD_SET_FOCUS_MODE = "setFocusMode";
    private static final String METHOD_CAPTURE_VIDEO = "captureVideo";
    private static final String METHOD_STOP_VIDEO_CAPTURE = "stopVideoCapture";
    private static final String METHOD_SEND_TIME_METADATA = "sendTimeMetaData";

    // Define constants for argument keys
    private static final String ARG_IMGSET = "imgset";
    private static final String ARG_STREAM_KEY = "streamKey";
    private static final String ARG_QUALITY = "quality";
    private static final String ARG_AUTO_RECONNECT = "autoReconnect";
    private static final String ARG_ZOOM = "zoom";
    private static final String ARG_LENS = "lens";
    private static final String ARG_TYPE = "type";
    private static final String ARG_SECONDS = "seconds";


    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case METHOD_START_PREVIEW:
                startPreview(call.argument(ARG_IMGSET), call.argument(ARG_STREAM_KEY), call.argument(ARG_QUALITY), call.argument(ARG_AUTO_RECONNECT));
                result.success(true);
                break;
            case METHOD_START_BROADCAST:
                startBroadcast();
                result.success("Broadcasting Started");
                break;
            case METHOD_STOP_BROADCAST:
                stopBroadcast();
                result.success("Broadcast Stopped");
                break;
            case METHOD_CHANGE_CAMERA:
                changeCamera(call.argument("type"));
                result.success("Camera Changed");
                break;
            case METHOD_MUTE:
                toggleMute();
                result.success(isMuted ? "Muted" : "Unmuted");
                break;
            case METHOD_IS_MUTED:
                result.success(isMuted);
                break;
            case METHOD_SEND_TIME_METADATA:
                sendMetaData(call.argument("metadata"));
                result.success(true);
                break;
            case METHOD_GET_CAMERA_ZOOM_FACTOR:
                result.success(getCameraZoomFactor());
                break;
            case METHOD_ZOOM_CAMERA:
                result.success(true);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private Map<String, Object> getCameraZoomFactor() {
        int max = 0;
        int min = 0;
        return Map.of();
    }

    private void sendMetaData(String metadata) {
        if (broadcastSession != null) {
            broadcastSession.sendTimedMetadata(metadata);
        }
    }

    private TextureView cameraPreview;

    private void startPreview(String url, String key, String quality, Boolean autoReconnect) {
        streamUrl = url;
        streamKey = key;

        BroadcastConfiguration config = getConfig(quality);
        config.autoReconnect.setEnabled(autoReconnect);
        config.mixer.slots = new BroadcastConfiguration.Mixer.Slot[]{
                BroadcastConfiguration.Mixer.Slot.with(slot -> {
                    slot.setPreferredAudioInput(Device.Descriptor.DeviceType.UNKNOWN);
                    slot.setPreferredVideoInput(Device.Descriptor.DeviceType.USER_IMAGE);
                    slot.setName("custom");
                    return slot;
                }),
                BroadcastConfiguration.Mixer.Slot.with(slot -> {
                    slot.setzIndex(1);
                    slot.setAspect(BroadcastConfiguration.AspectMode.FILL);
                    slot.setSize(1920, 1080);
                    slot.setPosition(new BroadcastConfiguration.Vec2(config.video.getSize().x - 350, config.video.getSize().y - 350));
                    slot.setName("camera");
                    return slot;
                })
        };
        broadcastSession = new BroadcastSession(context, broadcastListener, config, null);
        SurfaceSource source = broadcastSession.createImageInputSource();
        Surface ivsSurface = source.getInputSurface();
        cameraPreview = new TextureView(context);
        cameraPreview.setLayoutParams(new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.MATCH_PARENT));
        layout.addView(cameraPreview);

        cameraPreview.setSurfaceTextureListener(new TextureView.SurfaceTextureListener() {
            @Override
            public void onSurfaceTextureAvailable(SurfaceTexture surface, int width, int height) {
                startCamera2(new Surface(surface), ivsSurface);
                configureTransform(width, height);
            }

            @Override
            public void onSurfaceTextureSizeChanged(SurfaceTexture surface, int width, int height) {
                configureTransform(width, height);
            }

            @Override
            public boolean onSurfaceTextureDestroyed(SurfaceTexture surface) {
                return false;
            }

            @Override
            public void onSurfaceTextureUpdated(SurfaceTexture surface) {
            }
        });
    }

    private CameraDevice cameraDevice;
    private CameraCaptureSession captureSession;

    private void startCamera2(Surface previewSurface, Surface ivsSurface) {
        CameraManager manager = (CameraManager) context.getSystemService(Context.CAMERA_SERVICE);
        try {
            String cameraId = manager.getCameraIdList()[0];
            CameraCharacteristics characteristics = manager.getCameraCharacteristics(cameraId);
            StreamConfigurationMap map = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP);
            Size[] sizes = map.getOutputSizes(SurfaceTexture.class);
            Size previewSize = sizes[0];

            if (ActivityCompat.checkSelfPermission(context, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
                // Request camera permissions if not granted
                ActivityCompat.requestPermissions((Activity) context, new String[]{Manifest.permission.CAMERA}, 100);
                return;
            }

            manager.openCamera(cameraId, new CameraDevice.StateCallback() {
                @Override
                public void onOpened(@NonNull CameraDevice camera) {
                    cameraDevice = camera;
                    createCaptureSession(previewSurface, ivsSurface);
                }

                @Override
                public void onDisconnected(@NonNull CameraDevice camera) {
                    camera.close();
                    cameraDevice = null;
                }

                @Override
                public void onError(@NonNull CameraDevice camera, int error) {
                    camera.close();
                    cameraDevice = null;
                    Log.e("Camera2", "Camera error: " + error);
                }
            }, mainHandler);
        } catch (CameraAccessException e) {
            Log.e("Camera2", "Camera access exception: " + e.getMessage());
        }
    }

    private void createCaptureSession(Surface previewSurface, Surface ivsSurface) {
        try {
            CaptureRequest.Builder captureRequestBuilder = cameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW);
            captureRequestBuilder.addTarget(previewSurface);
            captureRequestBuilder.addTarget(ivsSurface);

            cameraDevice.createCaptureSession(Arrays.asList(previewSurface, ivsSurface), new CameraCaptureSession.StateCallback() {
                @Override
                public void onConfigured(@NonNull CameraCaptureSession session) {
                    captureSession = session;
                    try {
                        captureSession.setRepeatingRequest(captureRequestBuilder.build(), null, mainHandler);
                    } catch (CameraAccessException e) {
                        e.printStackTrace();
                    }
                }

                @Override
                public void onConfigureFailed(@NonNull CameraCaptureSession session) {
                    Log.e("Camera2", "CaptureSession Configuration Failed");
                }
            }, mainHandler);
        } catch (CameraAccessException e) {
            e.printStackTrace();
        }
    }

    private void configureTransform(int viewWidth, int viewHeight) {
        if (cameraPreview == null) {
            return;
        }
        Matrix matrix = new Matrix();
        int rotation = context.getResources().getConfiguration().orientation;
        int centerX = viewWidth / 2;
        int centerY = viewHeight / 2;

        if (rotation == android.content.res.Configuration.ORIENTATION_LANDSCAPE) {
            matrix.postRotate(0, centerX, centerY);
        } else if (rotation == android.content.res.Configuration.ORIENTATION_PORTRAIT) {
            matrix.postRotate(90, centerX, centerY);
        }
        cameraPreview.setTransform(matrix);
    }

    private void startBroadcast() {
        if (broadcastSession != null) {
            broadcastSession.start(streamUrl, streamKey);
        }
    }

    private void stopBroadcast() {
        if (broadcastSession != null) {
            broadcastSession.stop();
            broadcastSession.release();
            broadcastSession = null;

            Map<Object, Object> event = new HashMap<>();
            event.put("state", "DISCONNECTED");
            sendEvent(event);
        }
        releaseCamera();
    }

    private void toggleMute() {
        if (audioDevice != null) {
            audioDevice.setGain(isMuted ? 1.0F : 0.0F);
            isMuted = !isMuted;
        }
    }

    private void changeCamera(String type) {
        if (broadcastSession == null || cameraDevice == null) return;
    }

    private BroadcastConfiguration getConfig(String quality) {
        BroadcastConfiguration config = new BroadcastConfiguration();
        switch (quality) {
            case "360":
                config.video.setSize(640, 360);
                config.video.setMaxBitrate(1000000);
                config.video.setMinBitrate(500000);
                config.video.setInitialBitrate(800000);
                config.video.setTargetFramerate(30);
                config.video.setKeyframeInterval(2);
                break;
            case "720":
                config.video.setSize(1280, 720);
                config.video.setMaxBitrate(3500000);
                config.video.setMinBitrate(1500000);
                config.video.setInitialBitrate(2500000);
                config.video.setTargetFramerate(30);
                config.video.setKeyframeInterval(2);
                break;
            case "1080":
                config.video.setSize(1920, 1080);
                config.video.setMaxBitrate(6000000);
                config.video.setMinBitrate(4000000);
                config.video.setInitialBitrate(5000000);
                config.video.setTargetFramerate(30);
                config.video.setKeyframeInterval(2);
                break;
            default:
                config.video.setSize(1920, 1080);
                config.video.setMaxBitrate(8500000);
                config.video.setMinBitrate(1500000);
                config.video.setInitialBitrate(2500000);
                config.video.setTargetFramerate(30);
                config.video.setKeyframeInterval(2);
                break;
        }
        config.audio.setBitrate(128000);
        return config;
    }

    private final BroadcastSession.Listener broadcastListener = new BroadcastSession.Listener() {
        @Override
        public void onStateChanged(@NonNull BroadcastSession.State state) {
            Map<Object, Object> event = new HashMap<>();
            event.put("state", state.name());
            sendEvent(event);
        }

        @Override
        public void onRetryStateChanged(@NonNull BroadcastSession.RetryState state) {
            Map<Object, Object> event = new HashMap<>();
            event.put("retrystate", state.name());
            sendEvent(event);
        }

        @Override
        public void onError(@NonNull BroadcastException exception) {
            Map<Object, Object> event = new HashMap<>();
            event.put("error", exception.getError().name());
            sendEvent(event);
        }

        @Override
        public void onTransmissionStatsChanged(@NonNull TransmissionStats stats) {
            Map<Object, Object> event = new HashMap<>();
            event.put("quality", stats.broadcastQuality.name());
            event.put("network", stats.networkHealth.name());
            sendEvent(event);
        }
    };

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        this.eventSink = events;
    }

    @Override
    public void onCancel(Object arguments) {
        this.eventSink = null;
    }

    private void sendEvent(Map<Object, Object> event) {
        if (eventSink != null) {
            mainHandler.post(() -> eventSink.success(new Gson().toJson(event)));
        }
    }

    private void releaseCamera() {
        if (captureSession != null) {
            captureSession.close();
            captureSession = null;
        }
        if (cameraDevice != null) {
            cameraDevice.close();
            cameraDevice = null;
        }
    }
}