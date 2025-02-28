//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

#import <AmazonIVSPlayer/IVSBase.h>
#import <AmazonIVSPlayer/IVSImageFrameMessage.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Abstract base class for Supplemental Enhancement Information (SEI) messages.
/// @see `-[IVSPlayerDelegate player:didOutputSEIMessage:]`
IVS_EXPORT
@interface IVSSEIMessage : NSObject <IVSImageFrameMessage>

IVS_INIT_UNAVAILABLE

@end

NS_ASSUME_NONNULL_END
