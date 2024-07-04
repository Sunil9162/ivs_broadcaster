package com.example.ivs_broadcaster;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.widget.LinearLayout;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import android.util.Log;
import io.flutter.plugin.common.MethodChannel;
import static io.flutter.plugin.common.MethodChannel.MethodCallHandler;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.platform.PlatformView;

import com.amazonaws.ivs.broadcast.BroadcastConfiguration;
import com.amazonaws.ivs.broadcast.BroadcastException;
import com.amazonaws.ivs.broadcast.BroadcastSession;
import com.amazonaws.ivs.broadcast.Device;
import com.amazonaws.ivs.broadcast.ImageDevice;
import com.amazonaws.ivs.broadcast.ImagePreviewView;
import com.amazonaws.ivs.broadcast.Presets;
import androidx.annotation.NonNull;

import java.util.Objects;

public class StreamView implements PlatformView, MethodCallHandler, EventChannel.StreamHandler {
    private final LinearLayout layout;
    private EventChannel.EventSink messenger;
    private BroadcastSession broadcastSession;
    private Device cameraDevice;
    private final Context context;

    private   Handler handler;

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
            case "startBroadcast":
                startBroadcast(
                        methodCall.argument("imgset"),
                        methodCall.argument("streamKey"),
                        Objects.requireNonNull(methodCall.argument("cameraType")));
                break;
            case "stopBroadcast":
                stopBroadcast();
                break;
            case "changeCamera":
                changeCamera(
                        methodCall.argument("cameraType"));
                break;
            case "toggleMute":
                 toggleMute();
                break;
            default:
                result.notImplemented();
        }
    }

    private void changeCamera(String type) {

    }

    private void toggleMute() {

    }

    private void startBroadcast(String url, String key, String cameraType) {
        broadcastSession = new BroadcastSession(
                context,
                broadcastListener,
                Presets.Configuration.STANDARD_LANDSCAPE,
                cameraType.equals("0") ? Presets.Devices.FRONT_CAMERA(context) : Presets.Devices.BACK_CAMERA(context));
        broadcastSession.start(url, key);

        broadcastSession.awaitDeviceChanges(() -> {
            for (Device device : broadcastSession.listAttachedDevices()) {
                // Find the camera we attached earlier
                if (device.getDescriptor().type == Device.Descriptor.DeviceType.CAMERA) {
                    cameraDevice = device;
                    View view = getView();
                    assert view != null;
                    ImagePreviewView preview = ((ImageDevice) device)
                            .getPreviewView(BroadcastConfiguration.AspectMode.FILL);
                    preview.setLayoutParams(new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT,
                            LinearLayout.LayoutParams.MATCH_PARENT));
                    layout.addView(preview);
                }
            }
        });
    }

    BroadcastSession.Listener broadcastListener = new BroadcastSession.Listener() {
        @Override
        public void onStateChanged(@NonNull BroadcastSession.State state) {
            sendEvent(state.name());
        }

        @Override
        public void onError(@NonNull BroadcastException exception) {
            Log.e("Player", "Exception: " + exception);
        }
    };

    private void stopBroadcast() {
        broadcastSession.stop();
        broadcastSession.release();
        // Remove the View from layout
        layout.removeAllViews();
    }

    @Override
    public void dispose() {
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        this.messenger = events;
    }

    // Send the event to Flutter on Main Thread
    private void sendEvent(String event) {
        if (messenger != null) {
            handler.post(() -> messenger.success(event));
        }
    }

    @Override
    public void onCancel(Object arguments) {
        this.messenger = null;
    }
}