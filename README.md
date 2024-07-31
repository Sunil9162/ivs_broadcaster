# ivs_broadcaster

A new Flutter project for broadcasting live video using AWS IVS and Play the stream.

## Getting Started  

To use this package you need to have an AWS account and an IVS channel.

| Service                        | Android | iOS |
| ------------------------------ | :-----: | :-: |
| BroadCaster                    | ✅      | ✅  |
| Player                         |         | ✅  |


## Android Setup

```dart
String imgset = 'rtmp://<your channel url>';
String streamKy =  '<your stream key>';

//Add the following permissions to your AndroidManifest.xml file
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```


## IOS Setup

Add these two keys to your info.plist file

```plist
  <key>NSCameraUsageDescription</key>
	<string>To stream video</string>
	<key>NSMicrophoneUsageDescription</key>
	<string>To stream the audio</string>
```

## Usage

```dart
import 'package:ivs_broadcaster/ivs_broadcaster.dart';

IvsBroadcaster? ivsBroadcaster;

@override
void initState() {
  super.initState();
  ivsBroadcaster = IvsBroadcaster.instance;
}

//In your widget tree   
....
child:  BroadcaterPreview(),
....

//This will give you a preview of the camera
```

## METHODS FOR BROADCASTING

```dart
  Future<bool> requestPermissions();

  Future<void> startPreview({
    required String imgset,
    required String streamKey,
    CameraType cameraType = CameraType.BACK,
    void Function(dynamic)? onData,
    void Function(dynamic)? onError,
  });

  Future<void> startBroadcast();
  Future<void> stopBroadcast();
  Future<void> changeCamera(CameraType cameraType);

//Listen to the broadcast state
ivsBroadcaster!.broadcastState.stream.listen((event) {
    log(event.name.toString());
});

//Listen to the broadcast Quality
ivsBroadcaster!.broadcastQuality.stream.listen((event) {
    log(event.name.toString());
});

//Listen to the broadcast network health
ivsBroadcaster!.broadcastHealth.stream.listen((event) {
    log(event.name.toString());
});
```
## METHODS FOR PLAYER

```dart
 void startPlayer(
    String url, {
    required bool autoPlay,
    void Function(dynamic)? onData,
    void Function(dynamic)? onError,
  });
  void resume();
  void pause();
  void muteUnmute();
  void stopPlayer();

  Future<List<String>> getQualities();

  Future<void> setQuality(String value);

  Future<void> toggleAutoQuality();

  Future<bool> isAutoQuality();

  Future<void> seekTo(Duration duration);

  Future<Duration> getPosition();

```

## LISTNERS OF PLAYER

```dart
  StreamController<Duration> positionStream = StreamController.broadcast();
  StreamController<Duration> syncTimeStream = StreamController.broadcast();
  StreamController<Duration> durationStream = StreamController.broadcast();
  StreamController<String> qualityStream = StreamController.broadcast();
  StreamController<PlayerState> playeStateStream = StreamController.broadcast();
  StreamController<String> errorStream = StreamController.broadcast();
  StreamController<bool> isAutoQualityStream = StreamController.broadcast();
```


 

 


