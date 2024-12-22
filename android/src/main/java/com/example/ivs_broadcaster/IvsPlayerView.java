package com.example.ivs_broadcaster;


import android.content.Context;
import android.net.Uri;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.amazonaws.ivs.player.Cue;
import com.amazonaws.ivs.player.Player;
import com.amazonaws.ivs.player.PlayerException;
import com.amazonaws.ivs.player.PlayerView;
import com.amazonaws.ivs.player.Quality;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class IvsPlayerView extends Player.Listener implements PlatformView, SurfaceHolder.Callback, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private final Player player;
    private final SurfaceView surfaceView;
    private Surface surface;
    private EventChannel.EventSink eventSink;

    public IvsPlayerView(Context context, BinaryMessenger messenger, int viewId, Object args) {
        this.player = new PlayerView(context).getPlayer();
        this.player.addListener(this);
        this.surfaceView = new SurfaceView(context);
        MethodChannel methodChannel = new MethodChannel(messenger, "ivs_player");
        methodChannel.setMethodCallHandler(this);
        this.surfaceView.getHolder().addCallback(this);
        EventChannel eventChannel = new EventChannel(messenger, "ivs_player_event");
        eventChannel.setStreamHandler(this);
    }

    @Nullable
    @Override
    public View getView() {
        return surfaceView;
    }

    private void sendEvent(Object data) {
        if (eventSink != null) {
            eventSink.success(data);
        }
    }

    @Override
    public void onFlutterViewAttached(@NonNull View flutterView) {
        PlatformView.super.onFlutterViewAttached(flutterView);
        surfaceView.getHolder().addCallback(this);
    }

    @Override
    public void onFlutterViewDetached() {
        PlatformView.super.onFlutterViewDetached();
    }

    @Override
    public void dispose() {
        player.removeListener(this);
        player.release();
    }

    @Override
    public void surfaceCreated(@NonNull SurfaceHolder holder) {
        this.surface = holder.getSurface();
        if (player != null) {
            player.setSurface(this.surface);
        }
    }

    @Override
    public void surfaceChanged(@NonNull SurfaceHolder holder, int format, int width, int height) {

    }

    @Override
    public void surfaceDestroyed(@NonNull SurfaceHolder holder) {
        this.surface = null;
        if (player != null) {
            player.setSurface(null);
        }
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        this.eventSink = events;

    }

    @Override
    public void onCancel(Object arguments) {
        this.eventSink = null;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {

        Map<String, Object> args = call.arguments();
        switch (call.method) {
            case "startPlayer":
                assert args != null;
                String url = (String) args.get("url");
                Boolean autoPlay = (Boolean) args.get("autoPlay");
                startPlayer(url, autoPlay);
                result.success(true);
                break;
            case "stopPlayer":
                stopPlayer();
                result.success(true);
                break;
            case "mute":
                mutePlayer();
                result.success(true);
                break;
            case "pause":
                pausePlayer();
                result.success(true);
                break;
            case "resume":
                resumePlayer();
                result.success(true);
                break;
            case "seek":
                args = call.arguments();
                String time = (String) args.get("time");
                seekPlayer(time);
                result.success(true);
                break;
            case "position":
                result.success(player.getPosition());
                break;
            case "qualities":
                List<String> qualities = getQualities();
                result.success(qualities);
                break;
            case "setQuality":
                args = call.arguments();
                String quality = (String) args.get("quality");
                setQuality(quality);
                result.success(true);
                break;
            case "autoQuality":
                toggleAutoQuality();
                result.success(true);
                break;
            case "isAuto":
                result.success(isAuto());
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void seekPlayer(String time) {
        if (player != null) {
            player.seekTo(Long.parseLong(time));
        }
    }

    private void resumePlayer() {
        if (player != null) {
            player.play();
        }
    }

    private void pausePlayer() {
        if (player != null) {
            player.pause();
        }
    }

    private void mutePlayer() {
        if (player != null) {
            player.setMuted(!player.isMuted());
        }
    }

    private void stopPlayer() {
        this.dispose();
    }

    private void startPlayer(String url, Boolean autoPlay) {
        if (player != null) {
            player.load(Uri.parse(url));
            if (autoPlay) {
                player.play();
            }
        }
    }

    private void toggleAutoQuality() {
        final boolean auto = isAuto();
        player.setAutoQualityMode(!auto);
    }

    private boolean isAuto() {
        return player.isAutoQualityMode();
    }

    private void setQuality(String quality) {
        if (player != null) {
            for (Quality q : player.getQualities()) {
                if (q.getName().equals(quality)) {
                    player.setQuality(q);
                    break;
                }
            }
        }
    }

    private ArrayList<String> getQualities() {
        ArrayList<String> qualities = new ArrayList<>();
        if (player != null) {
            for (Quality quality : player.getQualities()) {
                qualities.add(quality.getName());
            }
        }
        return qualities;
    }

    @Override
    public void onCue(@NonNull Cue cue) {

    }

    @Override
    public void onDurationChanged(long l) {
        HashMap<String, Object> data = new HashMap<>();
        data.put("duration", l);
        sendEvent(data);
    }

    @Override
    public void onStateChanged(@NonNull Player.State state) {

        HashMap<String, Object> data = new HashMap<>();
        data.put("state", state.ordinal());
        sendEvent(data);
    }

    @Override
    public void onError(@NonNull PlayerException e) {
        HashMap<String, Object> data = new HashMap<>();
        data.put("error", e.getMessage());
        sendEvent(data);
    }

    @Override
    public void onRebuffering() {

    }

    @Override
    public void onSeekCompleted(long l) {
        HashMap<String, Object> data = new HashMap<>();
        data.put("seekedtotime", l);
        sendEvent(data);
    }

    @Override
    public void onVideoSizeChanged(int i, int i1) {

    }

    @Override
    public void onQualityChanged(@NonNull Quality quality) {
        HashMap<String, Object> data = new HashMap<>();
        data.put("quality", quality.getName());
        sendEvent(data);
    }
}
