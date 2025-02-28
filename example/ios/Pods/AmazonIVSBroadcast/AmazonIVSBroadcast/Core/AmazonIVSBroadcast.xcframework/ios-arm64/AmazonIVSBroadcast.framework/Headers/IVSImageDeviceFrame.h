//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <AmazonIVSBroadcast/IVSBase.h>
#import <AmazonIVSBroadcast/IVSImageFrameMessage.h>

NS_ASSUME_NONNULL_BEGIN

IVS_EXPORT

/// A data class providing metadata about the frames going through an `IVSImageDevice`.
@interface IVSImageDeviceFrame : NSObject

/// The size of the current frame.
@property (nonatomic, readonly) CGSize size;

/// The messages embedded in the current frame.
/// For h264 frames, these are SEI messages (See `IVSBroadcastSEIMessage`).
/// Only populated by the subscribe-side `IVSImageDevice` implementations in 
/// the Real-Time Stages SDK (not by the Broadcast SDK alone).
@property (nonatomic, strong, readonly) NSArray<id<IVSBroadcastImageFrameMessage>> *embeddedMessages;

@end

NS_ASSUME_NONNULL_END
