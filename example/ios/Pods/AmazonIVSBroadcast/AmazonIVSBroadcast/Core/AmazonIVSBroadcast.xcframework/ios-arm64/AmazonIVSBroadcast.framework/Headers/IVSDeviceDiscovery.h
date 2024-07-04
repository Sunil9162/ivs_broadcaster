//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <AmazonIVSBroadcast/IVSBase.h>

#import "IVSDeviceDescriptor.h"

@protocol IVSDevice;
@protocol IVSCustomImageSource;
@protocol IVSCustomAudioSource;

NS_ASSUME_NONNULL_BEGIN

IVS_EXPORT
/// Use this delegate to be notified about added / removed devices
@protocol IVSDeviceDiscoveryDelegate <NSObject>

@optional

/// Devices have been added (connected)
/// @param The array of added devices
- (void)devicesAdded:(NSArray<IVSDeviceDescriptor *> *)added;

/// Devices have been removed (disconnected)
/// @param The array of removed devices
- (void)devicesRemoved:(NSArray<IVSDeviceDescriptor *> *)removed;

@end

IVS_EXPORT
/// The interaction point for discovering and creating devices for use with the Broadcast and Stage SDKs.
@interface IVSDeviceDiscovery : NSObject

/// Add delegate
- (void)addDelegate:(id<IVSDeviceDiscoveryDelegate>)delegate NS_SWIFT_NAME(addDelegate(_:));

/// Remove delegate
- (void)removeDelegate:(id<IVSDeviceDiscoveryDelegate>)delegate NS_SWIFT_NAME(removeDelegate(_:));

/// List available devices for use with the Stage and Broadcast SDKs.
/// These devices will conform to `IVSCamera` and `IVSMicrophone` and are available for immediate use.
- (NSArray<id<IVSDevice>> *)listLocalDevices;

/// Create an image input for a custom source. This should only be used if you intend to generate and feed image data to the SDK manually.
/// @param The custom image soruce name.
- (id<IVSCustomImageSource>)createImageSourceWithName:(NSString *)name;

/// Create an audio input for a custom source. This should only be used if you intend to generate and feed PCM audio data to the SDK manually.
/// @param The custom audio soruce name.
- (id<IVSCustomAudioSource>)createAudioSourceWithName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
