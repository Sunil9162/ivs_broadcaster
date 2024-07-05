//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <AmazonIVSBroadcast/IVSAudioDevice.h>
#import <AmazonIVSBroadcast/IVSDevice.h>
#import <AmazonIVSBroadcast/IVSBase.h>

NS_ASSUME_NONNULL_BEGIN

/// A description of the capabilities of an AV device that is usable by the Broadcast SDK.
IVS_EXPORT
@interface IVSDeviceDescriptor : NSObject

IVS_INIT_UNAVAILABLE

/// System deviceId. These may not be unique as the system may reuse device ids for different types.
@property (nonatomic, strong, readonly) NSString *deviceId;

/// Unique device locator. this will be unique but it may be generated internally and may not match system addresses.
@property (nonatomic, strong, readonly) NSString *urn;

/// A human-readable name.
@property (nonatomic, strong, readonly) NSString *friendlyName;

/// The device type or family.
@property (nonatomic, readonly) IVSDeviceType type;

/// The types of streams supported by the device. The `NSNumber` values will be `IVSDeviceStreamType`.
@property (nonatomic, strong, readonly) NSArray<NSNumber *> *streams;

/// The physical location of the device, if it can be determined.
@property (nonatomic, readonly) IVSDevicePosition position;

/// If the device contains an image stream, the size of the images to be produced.
@property (nonatomic, readonly) CGSize imageSize;

/// Camera rotation.
@property (nonatomic, readonly) float rotation;

/// Microphone sample rate.
///
/// @discussion
///
/// This will reflect the current sample rate provided by `AVAudioSession` at the time the device was queried.
/// It is not guaranteed that this number of be accurate, as it will not react to changes made to `AVAudioSession` after it was queried.
@property (nonatomic, readonly) NSInteger sampleRate;

/// Microphone channel count.
///
/// @note This will reflect the current channel count provided by `AVAudioSession` at the time the device was queried.
/// It is not guaranteed that this number of be accurate, as it will not react to changes made to `AVAudioSession` after it was queried.
@property (nonatomic, readonly) NSInteger channelCount;

/// If this device contains an audio stream, the audio format.
@property (nonatomic, readonly) IVSAudioFormat audioFormat;

/// Default device indicator.
///
/// @discussion
///
/// In the case of audio devices, this will be `YES` for the device that is the current audio input route at the time the audio devices were queried.
/// It is possible the default device will change if you have made changes to your application's `AVAudioSession` instance. See
/// `IVSBroadcastSession.applicationAudioSessionStrategy` for more information.
///
/// For cameras, it is possible that each position (front, back) will have a default camera, so your application should handle the scenario
/// where this is `YES` for multiple devices.
@property (nonatomic, readonly) BOOL isDefault;

@end

NS_ASSUME_NONNULL_END
