package com.example.ivs_broadcaster;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import org.junit.Test;

/**
 * This demonstrates a simple unit test of the Java portion of this plugin's implementation.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew testDebugUnitTest` in the `example/android/` directory, or
 * you can run them directly from IDEs that support JUnit such as Android Studio.
 */

public class IvsBroadcasterPluginTest {
  @Test
  public void onMethodCall_getPlatformVersion_returnsExpectedValue() {
    IvsBroadcasterPlugin plugin = new IvsBroadcasterPlugin();

    final MethodCall call = new MethodCall("getPlatformVersion", null);
    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);


    verify(mockResult).success("Android " + android.os.Build.VERSION.RELEASE);
  }
}
