//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <AmazonIVSPlayer/IVSBase.h>

NS_ASSUME_NONNULL_BEGIN

/// Represents a preloaded source fetched by the `-[IVSPlayer preload:completionHandler:]` method.
/// @see `-[IVSPlayer preload:completionHandler:]`
/// @see `-[IVSPlayer loadSource:]`
IVS_EXPORT
@interface IVSSource : NSObject

IVS_INIT_UNAVAILABLE

/// The path this Source was preloaded from.
@property (nonatomic, readonly) NSURL *path;

#pragma mark - Comparison and quality

/// Returns a boolean value that indicates whether a given Source is equal to another.
/// @param other Another Source instance
- (BOOL)isEqualToSource:(IVSSource *)other;

@end

NS_ASSUME_NONNULL_END
