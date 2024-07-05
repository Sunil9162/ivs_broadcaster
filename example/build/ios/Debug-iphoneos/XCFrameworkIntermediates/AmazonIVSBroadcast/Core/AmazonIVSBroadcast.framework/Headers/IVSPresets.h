//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <AmazonIVSBroadcast/IVSBase.h>

@class IVSBroadcastConfiguration;
@class IVSDeviceDescriptor;

NS_ASSUME_NONNULL_BEGIN

/// Standard configurations for `IVSBroadcastConfiguration` objects.
IVS_EXPORT
@interface IVSConfigurationPresets : NSObject

/// A preset appropriate for streaming basic content in Portrait.
- (IVSBroadcastConfiguration *)standardPortrait;
/// A preset appropriate for streaming basic content in Landscape.
- (IVSBroadcastConfiguration *)standardLandscape;
/// A preset that is usable with the Basic channel type.
- (IVSBroadcastConfiguration *)basicPortrait;
/// A preset that is usable with the Basic channel type.
- (IVSBroadcastConfiguration *)basicLandscape;

@end

/// Combinations for commonly accessed `IVSDeviceDescriptor` objects.
IVS_EXPORT
@interface IVSDevicePresets : NSObject

/// Picks the front camera and default system audio input.
- (NSArray<IVSDeviceDescriptor *> *)frontCamera;
/// Picks the back camera and default system audio input.
- (NSArray<IVSDeviceDescriptor *> *)backCamera;
/// Returns the default system audio input and no image inputs.
- (NSArray<IVSDeviceDescriptor *> *)microphone;

@end

/// A collection of predefined configurations and input device sets.
IVS_EXPORT
@interface IVSPresets : NSObject

IVS_INIT_UNAVAILABLE

/// Preset broadcast configurations.
+ (IVSConfigurationPresets *)configurations;
/// Preset device combinations.
+ (IVSDevicePresets *)devices;

@end

NS_ASSUME_NONNULL_END
