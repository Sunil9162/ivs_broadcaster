package com.example.ivs_broadcaster;

import android.content.Context;

import androidx.annotation.NonNull;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class StreamFactory extends PlatformViewFactory {
    private final BinaryMessenger messenger;

    public StreamFactory(BinaryMessenger messenger) {
        super(StandardMessageCodec.INSTANCE);
        this.messenger = messenger;
    }

    @NonNull
    @Override
    public PlatformView create(Context context, int id, Object o) {
        return (PlatformView) new StreamView(context, messenger);
    }
}