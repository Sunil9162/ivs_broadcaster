//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <AmazonIVSBroadcast/IVSBase.h>

NS_ASSUME_NONNULL_BEGIN

/// Information about the stats of a audio device.
IVS_EXPORT
@interface IVSAudioDeviceStats : NSObject

/// Audio Peak over the time period from 100 (silent) to 0.
@property (nonatomic, readonly) float peak;
/// Audio RMS over the time period from 100 (silent) to 0.
@property (nonatomic, readonly) float rms;

@end

NS_ASSUME_NONNULL_END
