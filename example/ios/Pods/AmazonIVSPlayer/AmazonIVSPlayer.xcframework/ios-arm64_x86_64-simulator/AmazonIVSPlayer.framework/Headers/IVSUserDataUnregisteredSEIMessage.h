//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

#import <AmazonIVSPlayer/IVSSEIMessage.h>
#import <CoreMedia/CMTime.h>

NS_ASSUME_NONNULL_BEGIN

/// User Data Unregistered Supplemental Enhancement Information (SEI) message.
/// @see `-[IVSPlayerDelegate player:didOutputSEIMessage:]`
IVS_EXPORT
@interface IVSUserDataUnregisteredSEIMessage : IVSSEIMessage

IVS_INIT_UNAVAILABLE

/// The UUID of the message.
@property (nonatomic, strong, readonly) NSUUID *UUID;

/// The presentation timestamp (PTS) of the message.
@property (nonatomic, readonly) CMTime timestamp;

/// The data payload of the message.
@property (nonatomic, strong, readonly) NSData *data;

@end

NS_ASSUME_NONNULL_END
