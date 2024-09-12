package com.example.ivs_broadcaster;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.widget.LinearLayout;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import static io.flutter.plugin.common.MethodChannel.MethodCallHandler;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.platform.PlatformView;

import com.amazonaws.ivs.broadcast.AudioDevice;
import com.amazonaws.ivs.broadcast.BroadcastConfiguration;
import com.amazonaws.ivs.broadcast.BroadcastException;
import com.amazonaws.ivs.broadcast.BroadcastSession;
import com.amazonaws.ivs.broadcast.Device;
import com.amazonaws.ivs.broadcast.ImageDevice;
import com.amazonaws.ivs.broadcast.ImagePreviewView;
import com.amazonaws.ivs.broadcast.Presets;
import com.amazonaws.ivs.broadcast.TransmissionStats;
import com.google.gson.Gson;
import androidx.annotation.NonNull;

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
                startPreview(
                    methodCall.argument("imgset"),
                    methodCall.argument("streamKey"),
                    methodCall.argument("quality")
                );
                result.success(true);
            case "startBroadcast":
                startBroadcast();
                result.success("Broadcasting Started");
            case "stopBroadcast":
                stopBroadcast();
                result.success("Broadcaster Stopped");
            case "changeCamera":
                changeCamera(
                    methodCall.argument("type")
                );
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
        List<Device> devices =
          broadcastSession.listAttachedDevices();
        Device newDevice = null;
        for (Device device : devices) {
            if (device.getDescriptor().type == Device.Descriptor.DeviceType.CAMERA &&
                    device.getDescriptor().friendlyName.toLowerCase().contains(Objects.equals(type, "0") ?"front":"back")) {
                newDevice = device;
                break;
            }
        }
        assert Objects.requireNonNull(newDevice).isValid();
        broadcastSession.exchangeDevices(cameraDevice,newDevice.getDescriptor(),device -> {
            cameraDevice = device;
        });
    }

    private void toggleMute() {
        assert broadcastSession.isReady();
        if (isMuted){
            audioDevice.setGain(1.0F);
            isMuted = false;
        } else {
            audioDevice.setGain(0.0F);
            isMuted = true;
        }
    }

    private void startPreview(String url, String key, String quality){
        imgset = url;
        streamKey = key;
        broadcastSession = new BroadcastSession(
            context,
            broadcastListener,
            Presets.Configuration.STANDARD_LANDSCAPE,
            Presets.Devices.BACK_CAMERA(context)
        );
//        broadcastSession.awaitDeviceChanges(() -> {
//            for (Device device : broadcastSession.listAttachedDevices()) {
//                if (device.getDescriptor().type == Device.Descriptor.DeviceType.CAMERA) {
//                    cameraDevice = device;
//                    View view = getView();
//                    assert view != null;
//                    ImagePreviewView preview = ((ImageDevice) device)
//                            .getPreviewView(BroadcastConfiguration.AspectMode.FILL);
//                    preview.setLayoutParams(
//                            new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT,
//                            LinearLayout.LayoutParams.MATCH_PARENT)
//                    );
//                    layout.addView(preview);
//                }
//                if (device.getDescriptor().type == Device.Descriptor.DeviceType.MICROPHONE){
//                    assert device instanceof AudioDevice;
//                    audioDevice = (AudioDevice) device;
//                }
//            }
//        });
    }

    public  vo

    private void startBroadcast() {
        broadcastSession.start(imgset, streamKey);
    }

    BroadcastSession.Listener broadcastListener = new BroadcastSession.Listener() {
        @Override
        public void onStateChanged(@NonNull BroadcastSession.State state) {
            Map<Object, Object> map = new HashMap<>();
            map.put("state",state.name());
            sendMapData(map);
        }

        @Override
        public void onError(@NonNull BroadcastException exception) {
            Map<Object, Object> map = new HashMap<>();
            map.put("error",exception.getError().name());
            sendMapData(map);
        }

        @Override
        public void onTransmissionStatsChanged(TransmissionStats statistics){
            Map<Object, Object> map = new HashMap<>();
            map.put("quality",statistics.broadcastQuality.name());
            map.put("network",statistics.networkHealth.name());
            sendMapData(map);
        }
    };

    private void stopBroadcast() {
        broadcastSession.stop();
        broadcastSession.release();
        Map<Object, Object> map = new HashMap<>();
        map.put("state","DISCONNECTED");
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

    private void sendMapData(Map<Object, Object> map){
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
}
