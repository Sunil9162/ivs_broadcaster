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
/// An `IVSSource` object is returned immediately, and is initially in an "in-flight" state as the content is being "pre-loaded".
/// The invocation of the `completionHandler` signals that the returned `IVSSource` has completed preloading,
/// or, in the error case, that the path provided could not be preloaded. The immediately-returned `IVSSource` and the
/// `completionHandler` returned `IVSSource` will compare equal via `-[IVSSource isEqualToSource:]`.
/// In-flight `IVSSource`s can still be passed to `loadSource:`, and will still save time over a `load:` invoked at the same time.
///
/// Multiple streams can be preloaded at once with a single `IVSPlayer` object`.
///
/// Recommended usage of this API falls into one of three camps:
///     1) Fast. Use an nil `completionHandler`, and pass the immediately-returned `IVSSource` object back to `loadSource:`
///     within a timely manner. Any errors will be discovered upon `loadSource:` with the provided source, but not before.
///
///     2) Safe. Ignore the immediately-returned `IVSSource` object, and only use `IVSSource`s provided in the `completionHandler`.
///     This approach provides you error handling as soon as possible, and ensures you only hold valid `IVSSource`s, but also forces you to
///     wait for the preload to complete before `loadSource:` can be called.
///
///     3) Hybrid. Store the immediately-returned `IVSSource`, and provide a `completionHandler` with success and error handling logic.
///     If a load is requested quickly, pass the returned `IVSSource` back to `loadSource:` without waiting for the `completionHandler`.
///     If a load is not requested quickly, ensure the `IVSSource` you're holding is valid by waiting for the `completionHandler`, and dealing
///     with any errors that arise.
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

