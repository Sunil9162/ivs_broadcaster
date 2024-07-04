//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <AmazonIVSBroadcast/IVSBase.h>

NS_ASSUME_NONNULL_BEGIN

IVS_EXPORT

/// A data class providing metadata about the frames going through an `IVSImageDevice`.
@interface IVSImageDeviceFrame : NSObject

/// The size of the current frame.
@property (nonatomic, readonly) CGSize size;

@end

NS_ASSUME_NONNULL_END
