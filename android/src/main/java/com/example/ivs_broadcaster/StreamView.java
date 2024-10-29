package com.example.ivs_broadcaster;

import android.content.Context;
import android.hardware.camera2.CameraManager;
import android.os.Handler;
import android.os.Looper;
import android.view.Surface;
import android.view.View;
import android.widget.LinearLayout;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import static io.flutter.plugin.common.MethodChannel.MethodCallHandler;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.platform.PlatformView;

import com.amazonaws.ivs.broadcast.AudioDevice;
import com.amazonaws.ivs.broadcast.AudioSource;
import com.amazonaws.ivs.broadcast.BroadcastConfiguration;
import com.amazonaws.ivs.broadcast.BroadcastException;
import com.amazonaws.ivs.broadcast.BroadcastSession;
import com.amazonaws.ivs.broadcast.CustomAudioSource;
import com.amazonaws.ivs.broadcast.CustomImageSource;
import com.amazonaws.ivs.broadcast.Device;
import com.amazonaws.ivs.broadcast.SurfaceSource;
import com.amazonaws.ivs.broadcast.TransmissionStats;
import com.google.gson.Gson;

import androidx.annotation.NonNull;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

public class StreamView implements PlatformView, MethodCallHandler, EventChannel.StreamHandler {
    private final LinearLayout layout;
    private EventChannel.EventSink messenger;
    private BroadcastSession broadcastSession;
    private Device cameraDevice;
    private AudioDevice audioDevice;
    private final Context context;
    private final Handler handler;
    private CustomImageSource imageSource;
    private Surface surface;
    private CustomAudioSource customAudioSource;

    private String imgset;
    private String streamKey;
    private Boolean isMuted = false;

    StreamView(Context context, BinaryMessenger messenger) {
        this.context = context;
        layout = new LinearLayout(context);
        MethodChannel methodChannel = new MethodChannel(messenger, "ivs_broadcaster");
        EventChannel eventChannel = new EventChannel(messenger, "ivs_broadcaster_event");
        methodChannel.setMethodCallHandler(this);
        eventChannel.setStreamHandler(this);
        handler = new Handler(Looper.getMainLooper());
    }

    @Override
    public View getView() {
        return layout;
    }

    @Override
    public void onMethodCall(MethodCall methodCall, @NonNull MethodChannel.Result result) {
        switch (methodCall.method) {
            case "startPreview":
                startPreview(methodCall.argument("imgset"), methodCall.argument("streamKey"), methodCall.argument("quality"));
                result.success(true);
            case "startBroadcast":
                startBroadcast();
                result.success("Broadcasting Started");
            case "stopBroadcast":
                stopBroadcast();
                result.success("Broadcaster Stopped");
            case "changeCamera":
                changeCamera(methodCall.argument("type"));
                result.success("Camera Changed");
            case "mute":
                toggleMute();
                result.success("Muted toggled");
            case "isMuted":
                result.success(isMuted);
            case "zoomCamera":
                Object zoomFactor = methodCall.argument("zoomFactor");
                try {
                    zoomCamera((Integer) zoomFactor);
                } catch (Exception e) {
                    throw new RuntimeException(e);
                }
                result.success("Zoom not supported in Android");
            default:
                result.notImplemented();
        }
    }

    private void zoomCamera(Integer zoomFactor) throws Exception {
        assert broadcastSession.isReady();
        assert zoomFactor != null;
        throw new Exception("Zoom not supported in Android");
    }

    private void changeCamera(String type) {
        assert broadcastSession.isReady();
        List<Device> devices = broadcastSession.listAttachedDevices();
        Device newDevice = null;
        for (Device device : devices) {
            if (device.getDescriptor().type == Device.Descriptor.DeviceType.CAMERA && device.getDescriptor().friendlyName.toLowerCase().contains(Objects.equals(type, "0") ? "front" : "back")) {
                newDevice = device;
                break;
            }
        }
        assert Objects.requireNonNull(newDevice).isValid();
        broadcastSession.exchangeDevices(cameraDevice, newDevice.getDescriptor(), device -> {
            cameraDevice = device;
        });
    }

    private void toggleMute() {
        assert broadcastSession.isReady();
        if (isMuted) {
            audioDevice.setGain(1.0F);
            isMuted = false;
        } else {
            audioDevice.setGain(0.0F);
            isMuted = true;
        }
    }

    private void startPreview(String url, String key, String quality) {
        imgset = url;
        streamKey = key;
        BroadcastConfiguration config =  getConfig(quality);
        broadcastSession
            = new BroadcastSession(context,  broadcastListener,config,null);
        SurfaceSource surfaceSource = broadcastSession.createImageInputSource();
        AudioDevice audioSource = broadcastSession.createAudioInputSource(1, BroadcastConfiguration.AudioSampleRate.RATE_48000, AudioDevice.Format.INT16);
        Surface surface = surfaceSource.getInputSurface();
        broadcastSession.getMixer().bind(surfaceSource, "customSlot");
        broadcastSession.getMixer().bind(audioSource, "customSlot");
        createSession();
    }

    private void createSession(){
        Object manager = context.getSystemService(Context.CAMERA_SERVICE);
        CameraManager cameraManager = null;
        cameraManager = (CameraManager) manager;
        List<String> cameraList;
        try {
            assert cameraManager != null;
            cameraList = Arrays.asList(cameraManager.getCameraIdList());
            String cameraId = cameraList.get(0);
//            cameraDevice = broadcastSession.attachCamera(cameraId);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }


    private void startBroadcast() {
        broadcastSession.start(imgset, streamKey);
    }

    BroadcastSession.Listener broadcastListener = new BroadcastSession.Listener() {
        @Override
        public void onStateChanged(@NonNull BroadcastSession.State state) {
            Map<Object, Object> map = new HashMap<>();
            map.put("state", state.name());
            sendMapData(map);
        }

        @Override
        public void onError(@NonNull BroadcastException exception) {
            Map<Object, Object> map = new HashMap<>();
            map.put("error", exception.getError().name());
            sendMapData(map);
        }

        @Override
        public void onTransmissionStatsChanged(TransmissionStats statistics) {
            Map<Object, Object> map = new HashMap<>();
            map.put("quality", statistics.broadcastQuality.name());
            map.put("network", statistics.networkHealth.name());
            sendMapData(map);
        }
    };

    private void stopBroadcast() {
        broadcastSession.stop();
        broadcastSession.release();
        Map<Object, Object> map = new HashMap<>();
        map.put("state", "DISCONNECTED");
        sendMapData(map);
        layout.removeAllViews();
    }

    @Override
    public void dispose() {
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        this.messenger = events;
    }

    private void sendMapData(Map<Object, Object> map) {
        Gson json = new Gson();
        sendEvent(json.toJson(map));
    }

    // Send the event to Flutter on Main Thread
    private void sendEvent(Object event) {
        if (messenger != null) {
            handler.post(() -> messenger.success(event));
        }
    }

    @Override
    public void onCancel(Object arguments) {
        this.messenger = null;
    }


    private BroadcastConfiguration getConfig(String quality) {
        BroadcastConfiguration config = new BroadcastConfiguration();
        switch (quality) {
            case "360":
                config.video.setSize(640, 360);
                config.video.setMaxBitrate(1000000);// 1 Mbps
                config.video.setMinBitrate(500000); // 500 kbps
                config.video.setInitialBitrate(800000); // 800 kbps
                config.video.setTargetFramerate(30);
                config.video.setKeyframeInterval(2);
                break;
            case "1080":
                config.video.setSize(1920, 1080);
                config.video.setMaxBitrate(6000000); // 6 Mbps
                config.video.setMinBitrate(4000000); // 4 Mbps
                config.video.setInitialBitrate(5000000); // 5 Mbps
                config.video.setTargetFramerate(30);
                config.video.setKeyframeInterval(2);
                break;
            default:
                config.video.setSize(1280, 720);
                config.video.setMaxBitrate(3500000); // 3.5 Mbps
                config.video.setMinBitrate(1500000); // 1.5 Mbps
                config.video.setInitialBitrate(2500000); // 2.5 Mbps
                config.video.setTargetFramerate(30);
                config.video.setKeyframeInterval(2);
                break;
        }
        config.audio.setBitrate(128000); // 128 kbps
        return config;
    }
}
