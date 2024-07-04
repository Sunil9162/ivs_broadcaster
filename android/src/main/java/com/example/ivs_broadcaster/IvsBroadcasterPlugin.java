package com.example.ivs_broadcaster;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.PluginRegistry;

public class IvsBroadcasterPlugin  implements FlutterPlugin {


  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    binding
        .getPlatformViewRegistry()
        .registerViewFactory(
            "ivs_broadcaster", new StreamFactory(binding.getBinaryMessenger()));
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {

  }
}
