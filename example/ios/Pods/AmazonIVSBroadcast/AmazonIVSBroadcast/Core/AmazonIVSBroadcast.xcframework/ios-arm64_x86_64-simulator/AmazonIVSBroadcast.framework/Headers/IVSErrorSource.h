//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <AmazonIVSBroadcast/IVSBase.h>

@protocol IVSErrorDelegate;

NS_ASSUME_NONNULL_BEGIN

/// An object capable of emitting errors.
IVS_EXPORT
@protocol IVSErrorSource <NSObject>

/// A delegate for client apps to listen for errors from the SDK.
@property (nonatomic, weak) id<IVSErrorDelegate> errorDelegate;

@end

/// Provide a delegate to receive errors emitted from `IVSErrorSource` objects. Updates may be run on arbitrary threads and not the main thread.
IVS_EXPORT
@protocol IVSErrorDelegate <NSObject>

/// Indicates that an `IVSErrorSource` object emitted an error.
///
/// @param source the error source that emitted the error
/// @param error the error emitted by the error source
- (void)source:(id<IVSErrorSource>)source didEmitError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
