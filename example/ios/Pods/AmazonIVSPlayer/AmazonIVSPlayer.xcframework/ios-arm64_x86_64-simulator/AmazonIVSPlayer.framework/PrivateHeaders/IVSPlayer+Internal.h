//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

#import <AmazonIVSPlayer/IVSPlayer.h>

NS_ASSUME_NONNULL_BEGIN

@class IVSSource;

/// "Beta" APIs which are subject to breaking change / removal in upcoming IVSPlayer releases.
/// Use at your own risk.
@interface IVSPlayer (IVSInternal)

/// Pre-loads a stream at the specified URL for more rapid playback commencement.
///
/// An `IVSSource` object is returned immediately, and is initially in an "in-flight" state as the content is being pre-loaded.
/// The invocation of the `completionHandler` signals that the returned `IVSSource` has completed preloading (meaning it is no
/// longer in-flight), or, in the error case, that the path provided could not be preloaded. The immediately-returned `IVSSource`
/// and the `completionHandler` returned `IVSSource` will compare equal via `-[IVSSource isEqualToSource:]`.
/// In-flight `IVSSource`s can still be passed to `loadSource:`, and will still save time over a `load:` invoked at the same time
/// (as the in-flight request will be used instead of shooting off a new request to accommodate the load).
///
/// Multiple streams can be preloaded at once with a single `IVSPlayer` object`.
///
/// @param path Location of the streaming manifest. Does not work with clips or files, unlike the load method.
/// @see `IVSSource`
- (IVSSource *)preload:(NSURL *)path completionHandler:(void (^ _Nullable)(IVSSource * _Nullable source, NSError * _Nullable error))completionHandler;

/// Loads the stream which has been preloaded into the specified `IVSSource` object.
/// `loadSource` with a valid `IVSSource` object is at least one network round-trip
/// faster than `load`, so use the `preload` ==> `loadSource` flow when the next
/// source for playback is known ahead of time.
/// @param source The pre-loaded source object returned by a previous preload call.
/// @see `IVSSource`
- (void)loadSource:(IVSSource *)source NS_SWIFT_NAME(load(_:));

@end

NS_ASSUME_NONNULL_END

