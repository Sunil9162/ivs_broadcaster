//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AmazonIVSBroadcast/IVSBase.h>
#import <AmazonIVSBroadcast/IVSErrorSource.h>

@class IVSDeviceDescriptor;

NS_ASSUME_NONNULL_BEGIN

/// Types of input devices.
typedef NS_ENUM(NSInteger, IVSDeviceType) {
    /// The device type is unknown.
    IVSDeviceTypeUnknown = 0,
    /// The device is a video camera.
    IVSDeviceTypeCamera = 1,
    /// The device is a audio microphone.
    IVSDeviceTypeMicrophone = 2,
    /// The device is a user provided image stream.
    IVSDeviceTypeUserImage = 5,
    /// The device is user provided audio.
    IVSDeviceTypeUserAudio = 6,
};

/// Media types present in a stream.
typedef NS_ENUM(NSInteger, IVSDeviceStreamType) {
    /// The device stream will contain audio PCM encoded samples.
    IVSDeviceStreamTypePCM,
    /// The device stream will contain image samples.
    IVSDeviceStreamTypeImage,
};

/// The position of the input device relative to the host device.
typedef NS_ENUM(NSInteger, IVSDevicePosition) {
    /// The device's position is unknown.
    IVSDevicePositionUnknown,
    /// The input device is located on the front of the host device.
    IVSDevicePositionFront,
    /// The input device is located on the back of the host device.
    IVSDevicePositionBack,
    /// The input device is connected to the host device via USB.
    IVSDevicePositionUSB,
    /// The input device is connected to the host device via bluetooth.
    IVSDevicePositionBluetooth,
    /// The input device is connected via an auxiliary cable.
    IVSDevicePositionAUX,
};

/// Represents an input device such as a camera or microphone.
IVS_EXPORT
@protocol IVSDevice <IVSErrorSource>

/// A descriptor of the device and its capabilities.
- (IVSDeviceDescriptor *)descriptor;
/// A unique tag for this device.
- (NSString *)tag;

@end

/// Represents an input device such as a camera or microphone with multiple underlying input sources.
IVS_EXPORT
@protocol IVSMultiSourceDevice <IVSDevice>

/// List available underlying input sources for the device.
///
/// @discussion
///
/// The return order of these input sources is predictable. They are sorted by, in priority order:
/// 
/// * `position` (based on `rawValue` of the `IVSDevicePosition` enum in ascending order)
/// * `isDefault` (`YES` will appear before `NO`)
/// * `friendlyName` (sorted alphabetically in ascending order)
- (NSArray<IVSDeviceDescriptor *> *)listAvailableInputSources;

/// Sets the preferred input source.
///
/// The preferred input source of a camera device will always take effect if no error occurs. The preferred input source of a microphone device _may_ take effect if the system allows it and no error occurs.
///
/// @param inputSource The preferred input source.
/// @param onComplete A callback that that contains any error that occurred while updating the preferred input source. Invoked when the operation has completed. Always invoked on the main queue.
- (void)setPreferredInputSource:(IVSDeviceDescriptor *)inputSource onComplete:(nullable void (^)(NSError * _Nullable error))onComplete;

@end

NS_ASSUME_NONNULL_END
