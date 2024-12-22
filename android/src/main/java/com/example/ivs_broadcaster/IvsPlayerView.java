package com.example.ivs_broadcaster;

import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.plugin.platform.PlatformView;

public class IvsPlayerView implements PlatformView {
    @Nullable
    @Override
    public View getView() {
        return null;
    }

    @Override
    public void onFlutterViewAttached(@NonNull View flutterView) {
        PlatformView.super.onFlutterViewAttached(flutterView);
    }

    @Override
    public void onFlutterViewDetached() {
        PlatformView.super.onFlutterViewDetached();
    }

    @Override
    public void dispose() {

    }
}
