package com.example.ivs_broadcaster;

import android.content.Context;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.widget.LinearLayout;

import androidx.annotation.NonNull;

import com.amazonaws.ivs.broadcast.AudioDevice;
import com.amazonaws.ivs.broadcast.BroadcastConfiguration;
import com.amazonaws.ivs.broadcast.BroadcastException;
import com.amazonaws.ivs.broadcast.BroadcastSession;
import com.amazonaws.ivs.broadcast.Device;
import com.amazonaws.ivs.broadcast.ImagePreviewView;
import com.amazonaws.ivs.broadcast.Presets;
import com.amazonaws.ivs.broadcast.TransmissionStats;
import com.google.gson.Gson;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.platform.PlatformView;

public class StreamView implements PlatformView, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private final LinearLayout layout;
    private EventChannel.EventSink eventSink;
    private BroadcastSession broadcastSession;
    private Device cameraDevice;
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
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "startPreview":
                startPreview(
                        call.argument("imgset"),
                        call.argument("streamKey"),
                        call.argument("quality")
                );
                result.success(true);
                break;
            case "startBroadcast":
                startBroadcast();
                result.success("Broadcasting Started");
                break;
            case "stopBroadcast":
                stopBroadcast();
                result.success("Broadcast Stopped");
                break;
            case "changeCamera":
                changeCamera(call.argument("type"));
                result.success("Camera Changed");
                break;
            case "mute":
                toggleMute();
                result.success(isMuted ? "Muted" : "Unmuted");
                break;
            case "isMuted":
                result.success(isMuted);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void startPreview(String url, String key, String quality) {
        streamUrl = url;
        streamKey = key;

        BroadcastConfiguration config = getConfig(quality);

        broadcastSession = new BroadcastSession(context, broadcastListener, config, Presets.Devices.BACK_CAMERA(context));

        ImagePreviewView preview = broadcastSession.getPreviewView();
        preview.setLayoutParams(new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.MATCH_PARENT
        ));
        layout.addView(preview);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            broadcastSession.listAttachedDevices().forEach(device -> {
                if (device.getDescriptor().type == Device.Descriptor.DeviceType.CAMERA) {
                    cameraDevice = device;
                } else if (device.getDescriptor().type == Device.Descriptor.DeviceType.MICROPHONE) {
                    audioDevice = (AudioDevice) device;
                }
            });
        }
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
        layout.removeAllViews();
    }

    private void toggleMute() {
        if (audioDevice != null) {
            audioDevice.setGain(isMuted ? 1.0F : 0.0F);
            isMuted = !isMuted;
        }
    }

    private void changeCamera(String type) {
        if (broadcastSession == null || cameraDevice == null) return;

        List<Device> devices = broadcastSession.listAttachedDevices();
        for (Device device : devices) {
            if (device.getDescriptor().type == Device.Descriptor.DeviceType.CAMERA &&
                    device.getDescriptor().friendlyName.toLowerCase().contains(Objects.equals(type, "0") ? "front" : "back")) {
                broadcastSession.exchangeDevices(cameraDevice, device.getDescriptor(), exchangedDevice -> cameraDevice = exchangedDevice);
                break;
            }
        }
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

    private final BroadcastSession.Listener broadcastListener = new BroadcastSession.Listener() {
        @Override
        public void onStateChanged(@NonNull BroadcastSession.State state) {
            Map<Object, Object> event = new HashMap<>();
            event.put("state", state.name());
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
}
