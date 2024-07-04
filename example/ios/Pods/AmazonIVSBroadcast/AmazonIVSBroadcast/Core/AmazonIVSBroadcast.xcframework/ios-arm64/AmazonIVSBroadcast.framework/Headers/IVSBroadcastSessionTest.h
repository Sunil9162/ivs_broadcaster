//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <AmazonIVSBroadcast/IVSBase.h>

NS_ASSUME_NONNULL_BEGIN

@class IVSVideoConfiguration;

/// The state of a network quality test
typedef NS_ENUM(NSInteger, IVSBroadcastSessionTestStatus) {
    /// The test is connecting to the ingest server and will start soon.
    IVSBroadcastSessionTestStatusConnecting,
    /// The test is running.
    IVSBroadcastSessionTestStatusTesting,
    /// The test completed successfully.
    IVSBroadcastSessionTestStatusSuccess,
    /// The test failed due to an error.
    IVSBroadcastSessionTestStatusError,
} NS_SWIFT_NAME(IVSBroadcastSessionTest.Status);

/// Information about the state of a network quality test.
IVS_EXPORT
@interface IVSBroadcastSessionTestResult : NSObject

IVS_INIT_UNAVAILABLE

/// The progress of the network quality test from 0 to 1.
@property (nonatomic, readonly) float progress;
/// A list of suggestions to use for the video portion of your broadcast configuration. These are mutable and can be customized if needed.
@property (nonatomic, strong, readonly) NSArray<IVSVideoConfiguration *> *recommendations;
/// The status of the network quality test.
@property (nonatomic, readonly) IVSBroadcastSessionTestStatus status;
/// Any error associated with the network quality test.
@property (nonatomic, readonly, nullable) NSError *error;

@end

/// A handle on the network quality test. You can use this to cancel an ongoing test.
IVS_EXPORT
@interface IVSBroadcastSessionTest : NSObject

IVS_INIT_UNAVAILABLE

/// Cancels the associated network quality test.
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
