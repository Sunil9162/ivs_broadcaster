# ivs_broadcaster

A new Flutter project for broadcasting live video using AWS IVS.

## Getting Started  

To use this package you need to have an AWS account and an IVS channel.


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
child:  ivsBroadcaster?.previewWidget,
....

//This will give you a preview of the camera
```

## METHODS

```dart
//Starts the broadcast
ivsBroadcaster?.startBroadcast(imgset, streamKy,CameraType.BACK);

//Stops the broadcast
ivsBroadcaster?.stopBroadcast();

//Listen to the broadcast state
ivsBroadcaster!.broadcastStateController.stream.listen((event) {
    log(event.name.toString());
});
```



 

 


