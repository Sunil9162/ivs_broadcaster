//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <AmazonIVSBroadcast/IVSBase.h>
#import <AmazonIVSBroadcast/IVSBroadcastConfiguration.h>
#import <AmazonIVSBroadcast/IVSSession.h>

NS_ASSUME_NONNULL_BEGIN

@class IVSBroadcastConfiguration;
@class IVSVideoConfiguration;
@class IVSDeviceDescriptor;
@class IVSImagePreviewView;
@class IVSBroadcastSessionTest;
@class IVSBroadcastSessionTestResult;
@class IVSTransmissionStatistics;
@class UIView;
@protocol IVSBackgroundImageSource;
@protocol IVSBroadcastSessionDelegate;
@protocol MTLDevice;
@protocol MTLCommandQueue;

/// A callback to recieve `IVSBroadcastSessionTestResult`s asynchronously.
typedef void (^IVSSessionTestResultCallback)(IVSBroadcastSessionTestResult * _Nonnull);

/// A value representing the `IVSBroadcastSession`s current state.
typedef NS_CLOSED_ENUM(NSInteger, IVSBroadcastSessionState) {
    /// The session is invalid. This is the initial state after creating a session but before starting a stream.
    IVSBroadcastSessionStateInvalid,
    /// The session has disconnected. After stopping a stream the session should return to this state unless it has errored.
    IVSBroadcastSessionStateDisconnected,
    /// The session is connecting to the ingest server.
    IVSBroadcastSessionStateConnecting,
    /// The session has connected to the ingest server and is currently sending data.
    IVSBroadcastSessionStateConnected,
    /// The session has had an error. Use the `IVSBroadcastSessionDelegate` to catch errors thrown by the session.
    IVSBroadcastSessionStateError,
} NS_SWIFT_NAME(IVSBroadcastSession.State);

/// A value representing the `IVSBroadcastSession`s retry state.
typedef NS_CLOSED_ENUM(NSInteger, IVSBroadcastSessionRetryState) {
    /// The SDK is not currently attempting to reconnect a failed broadcast
    IVSBroadcastSessionRetryStateNotRetrying,
    /// The SDK is waiting to for the internet connection to be restored before starting to backoff timer to attempt a reconnect.
    IVSBroadcastSessionRetryStateWaitingForInternet,
    /// The SDK is waiting to for the backoff timer to trigger a reconnect attempt.
    IVSBroadcastSessionRetryStateWaitingForBackoffTimer,
    /// The SDK is actively trying to reconnect a failed broadcast.
    IVSBroadcastSessionRetryStateRetrying,
    /// The SDK successfully reconnected a failed broadcast.
    IVSBroadcastSessionRetryStateSuccess,
    /// The SDK was unable to reconnect a failed broadcast within the maximum amount of allowed retries.
    IVSBroadcastSessionRetryStateFailure,
} NS_SWIFT_NAME(IVSBroadcastSession.RetryState);

/// BroadcastSession is the primary interaction point with the IVS Broadcast SDK.
/// You must create a BroadcastSession in order to begin broadcasting.
///
/// @note If there as a live broadcast when this object deallocates, internally `stop` will be called during deallocation, and it will block
/// until the stream has been gracefully terminated or a timeout is reached. Because of that it is recommended that you always explicitly
/// stop a live broadcast before deallocating.
IVS_EXPORT
@interface IVSBroadcastSession : IVSSession

IVS_INIT_UNAVAILABLE

/// A protocol for client apps to listen to important updates from the Broadcast SDK.
@property (nonatomic, weak, nullable) id<IVSBroadcastSessionDelegate> delegate;

/// Create an IVSBroadcastSession object that can stream to an IVS endpoint via RTMP
/// @param config a Broadcast configuration, either one of the `IVSPresets` or a custom configuration.
/// @param descriptors an optional list of devices to instantiate immediately. To get a list of devices see `listAvailableDevices`.
/// @param delegate an `IVSBroadcastSessionDelegate` to receive callbacks from the broadcast session.
/// @param outError On input, a pointer to an error object. If an error occurs, the pointer is an NSError object that describes the error. If you don’t want error information, pass in nil.
- (nullable instancetype)initWithConfiguration:(IVSBroadcastConfiguration *)config
                                   descriptors:(nullable NSArray<IVSDeviceDescriptor *> *)descriptors
                                      delegate:(nullable id<IVSBroadcastSessionDelegate>)delegate
                                         error:(NSError *__autoreleasing *)outError;

/// Create a BroadcastSession object that can stream to an IVS endpoint via RTMP.
///
/// This initializer is specific to allowing a  `MTLDevice` and `MTLCommandQueue` to be provided.
/// These are expensive resources, and Apple recommends only allocating a single instance of each per application.
/// If your app is going to be using Metal outside of the broadcast SDK, you should provide your `MTLDevice`
/// and `MTLCommandQueue` here so they can be reused.
///
/// @param config a Broadcast configuration, either one of the `IVSPresets` or a custom configuration.
/// @param descriptors an optional list of devices to instantiate immediately. To get a list of devices see `listAvailableDevices`.
/// @param delegate an `IVSBroadcastSessionDelegate` to receive callbacks from the broadcast session.
/// @param metalDevice the `MTLDevice` for the broadcast SDK to use.
/// @param metalCommandQueue the `MTLCommandQueue` for the broadcast SDK to use.
/// @param outError On input, a pointer to an error object. If an error occurs, the pointer is an NSError object that describes the error. If you don’t want error information, pass in nil.
- (nullable instancetype)initWithConfiguration:(IVSBroadcastConfiguration *)config
                                   descriptors:(nullable NSArray<IVSDeviceDescriptor *> *)descriptors
                                      delegate:(nullable id<IVSBroadcastSessionDelegate>)delegate
                                   metalDevice:(nullable id<MTLDevice>)metalDevice
                             metalCommandQueue:(nullable id<MTLCommandQueue>)metalCommandQueue
                                         error:(NSError *__autoreleasing *)outError;

/// Start the configured broadcast session.
/// @param url the RTMPS endpoint provided by IVS.
/// @param streamKey the broadcaster's stream key that has been provided by IVS.
/// @param outError A reference to an NSError that would be set if an error occurs.
/// @return if the operation is successful. If it returns NO check `isReady`.
- (BOOL)startWithURL:(NSURL *)url streamKey:(NSString *)streamKey error:(NSError *__autoreleasing *)outError;

/// Stop the broadcast session, but do not deallocate resources. Stopping the stream happens asynchronously while the SDK attempts to gracefully end the
/// broadcast. Please obverse state changes in the `IVSBroadcastSessionDelegate` to know when you can start a new stream.
///
/// If this `IVSBroadcastSession` object deallocates during the `stop` operation, the deallocation will block until the stop completes successfully or
/// a timeout is reached. This is to ensure the live broadcast is properly shut down, preventing it from staying live longer than expected.
- (void)stop;

/// Runs a network test with a default duration of 8 seconds.
/// @see `-[IVSBroadcastSession recommendedVideoSettingsWithURL:streamKey:duration:results:]`
- (nullable IVSBroadcastSessionTest *)recommendedVideoSettingsWithURL:(NSURL *)url
                                                            streamKey:(NSString *)streamKey
                                                              results:(IVSSessionTestResultCallback)onNewResult;

/// This will perform a network test and provide recommendations for video configurations. It will not publish live video, it will only test the connection quality.
/// The callback will be called periodically and provide you with a status, progress, and continuously updated recommendations. The longer the test runs
/// the more refined the suggestions will be, however you can cancel the test at any time and make use of previous recommendations. But these recommendations
/// might not be as stable, or as high quality as a fully completed test.
///
/// @note This can not be called while an existing broadcast is in progress, and a new broadcast can not be started while a test is in progress.
///
/// @param url the RTMPS endpoint provided by IVS.
/// @param streamKey the broadcaster's stream key that has been provided by IVS.
/// @param duration How long to run the test for. It's recommended the test runs for at least 8 seconds, and the minimum is 3 seconds. The test can always be cancelled early.
/// @param onNewResult a block that will be called periodically providing you with an update on the test's progress and recommendations.
/// @return a handle to the network test, providing you a way to cancel it, or `nil` if there is an error starting the test.
- (nullable IVSBroadcastSessionTest *)recommendedVideoSettingsWithURL:(NSURL *)url
                                                            streamKey:(NSString *)streamKey
                                                             duration:(NSTimeInterval)duration
                                                              results:(IVSSessionTestResultCallback)onNewResult;

/// Invoking this API changes the default behavior when your application goes into the background. By default any active broadcast will
/// stop, and all I/O devices will be shutdown until the app is foregrounded again. After calling this API and receiving an error free callback,
/// the broadcast will remain active in the background and will loop the video provided to the `IVSBackgroundImageSource` returned
/// by this API. The audio sources will stay live.
///
/// The total duration of the background video must be an internal of the keyframe interval provided to the `IVSVideoConfiguration.keyframeInterval`
/// If the `keyframeInterval` is 2 seconds, the `targetFramerate` is 30, and you provide 45 images, the last 15 images will be trimmed, or the last image
/// will be repeated 15 times based on the value of the `attemptTrim` param.
/// Because of this, the API will work best if the number of images provide is a multiple of (`keyframeInterval` * `targetFramerate`).
/// A single image can also be provided to this source before calling `finish`, and that image will be encoded to a full GOP for a static background.
///
/// @note This is an expensive API, it is recommended that you call this before going live to prevent dropping frames. Additionally, this API
/// must be called while the application is in the foreground.
///
/// @note In order to continue to operate in the background, you will need to enable the background audio entilement for your application.
///
/// @param onComplete A callback that is invoked when the setup for background image broadcasting is complete. Always invoked on the main queue.
/// @param attemptTrim if this is YES, this API will attempt to trim the submitted samples to create a perfect looping clip, which means
/// some samples might be dropped to correctly end on a keyframe. If this is NO, the last frame will be repeated until the GOP is closed.
/// If this is YES and there were not enough samples submitted to create a full GOP, the last frame will always be repeated and the trim will not occur.
- (nullable id<IVSBackgroundImageSource>)createAppBackgroundImageSourceWithAttemptTrim:(BOOL)attemptTrim
                                                                            OnComplete:(nullable void (^)(NSError * _Nullable))onComplete;

/// Removes the behavior change from calling `createAppBackgroundImageSourceOnComplete` and cleans up the artifacts
/// generated by that API. Which means if the app goes into the background, the stream will be stopped again.
/// This API must be called while the application is in the foreground, otherwise an error will be returned.
///
/// @note This does not need to be called to resume streaming in the foreground. Only call this API if you want to disable the ability to stream in the background.
///
/// @param outError On input, a pointer to an error object. If an error occurs, the pointer is an NSError object that describes the error. If you don’t want error information, pass in nil.
- (BOOL)removeImageSourceOnAppBackgroundedWithError:(NSError *__autoreleasing *)outError;

/// Send timed metadata that will be automatically synchronized with the ongoing stream.
/// @param contents text-based metadata that will be interpreted by your receiver.
/// @return YES if the operation is successful. If it returns NO then an error has occurred.
- (BOOL)sendTimedMetadata:(NSString*)contents error:(NSError *__autoreleasing *)outError;

@end

/// Provide a delegate to receive status updates and errors from the SDK. Updates may be run on arbitrary threads and not the main thread.
IVS_EXPORT
NS_SWIFT_NAME(IVSBroadcastSession.Delegate)
@protocol IVSBroadcastSessionDelegate <NSObject>

@required

/// Indicates that the broadcast state changed.
/// @param session The `IVSBroadcastSession` that just changed state
/// @param state current broadcast state
- (void)broadcastSession:(IVSBroadcastSession *)session
          didChangeState:(IVSBroadcastSessionState)state;

/// Indicates that an error occurred. Errors may or may not be fatal and will be marked as such
/// with the `IVSBroadcastErrorIsFatalKey` in the `userInfo` property of the error.
///
/// @note In the case of a fatal error the broadcast session moves into disconnected state.
///
/// @param session The `IVSBroadcastSession` that just emitted the error.
/// @param error error emitted by the SDK.
- (void)broadcastSession:(IVSBroadcastSession *)session
            didEmitError:(NSError *)error;

@optional

/// Indicates that a device has become available.
///
/// @note In the case of audio devices, it is possible the system has automatically rerouted audio to this device.
/// You can check `listAttachedDevices` to see if the attached audio devices have changed.
///
/// @param session The `IVSBroadcastSession` that added the device
/// @param descriptor the device's descriptor
- (void)broadcastSession:(IVSBroadcastSession *)session
            didAddDevice:(IVSDeviceDescriptor *)descriptor;

/// Indicates that a device has become unavailable.
///
/// @note In the case of audio devices, it is possible the system has automatically rerouted audio from this device
/// to another device. You can check `listAttachedDevices` to see if the attached audio devices have changed.
///
/// It is possible that this will not be called if a device that is not in use gets disconnected. For example, if you have
/// attached the built-in microphone to the broadcast session, but also have a bluetooth microphone paired with the device,
/// this may not be called if the bluetooth device disconnects. Anything impacting an attached device will result in this being called however.
///
/// @param session The `IVSBroadcastSession` that removed the device
/// @param descriptor the device's descriptor. This may not contain specific hardware information other than IDs.
- (void)broadcastSession:(IVSBroadcastSession *)session
         didRemoveDevice:(IVSDeviceDescriptor *)descriptor;

/// Periodically called with audio peak and rms in dBFS. Range is -100 (silent) to 0.
/// @param session The `IVSBroadcastSession` associated with the audio stats.
/// @param peak Audio Peak over the time period
/// @param rms Audio RMS over the time period
- (void)broadcastSession:(IVSBroadcastSession *)session
audioStatsUpdatedWithPeak:(double)peak
                     rms:(double)rms;

/// A number between 0 and 1 that represents the qualty of the stream based on bitrate minimum and maximum provided
/// on session configuration. 0 means the stream is at the lowest possible quality, or streaming is not possible at all.
/// 1 means the bitrate is near the maximum allowed.
///
/// If the video configuration looks like:
/// initial bitrate = 1000 kbps
/// minimum bitrate = 300 kbps
/// maximum bitrate = 5,000 kbps
///
/// It will be expected that a low quality is provided to this callback initially, since the initial bitrate is much closer to the minimum
/// allowed bitrate than the maximum. If network conditions are good the quality should improve over time towards the allowed maximum.
///
/// @param session The `IVSBroadcastSession` associated with the quality change.
/// @param quality The quality of the stream
- (void)broadcastSession:(IVSBroadcastSession *)session
 broadcastQualityChanged:(double)quality DEPRECATED_MSG_ATTRIBUTE("Use broadcastSession:transmissionStatisticsChanged: instead.");

/// A number between 0 and 1 that represents the current health of the network. 0 means the network is struggling to keep up and the broadcast
/// may be experiencing latency spikes. The SDK may also reduce the quality of the broadcast on low values in order to keep it stable, depending
/// on the minimum allowed bitrate in the broadcast configuration. A value of 1 means the network is easily able to keep up with the current demand
/// and the SDK will be trying to increase the broadcast quality over time, depending on the maximum allowed bitrate.
///
/// Lower values like 0.5 are not necessarily bad, it just means the network is being saturated, but it is still able to keep up.
///
/// @param session The `IVSBroadcastSession` that associated with the quality change.
/// @param health The instantaneous health of the network
- (void)broadcastSession:(IVSBroadcastSession *)session
    networkHealthChanged:(double)health DEPRECATED_MSG_ATTRIBUTE("Use broadcastSession:transmissionStatisticsChanged: instead.");

/// Periodically called with current statistics on the broadcast, such as the measured bitrate, recommended bitrate
/// by the SDK's adaptive bitrate algorithm, average round trip time, broadcast quality (relative to configured
/// minimum and maximum bitrates), and network health.
///
/// Expect this callback to be triggered on the delegate quite frequently (approximately twice per second)
/// as the measured and recommended bitrates change.
///
/// @see `IVSTransmissionStatistics` documentation for further information on how to interpret the metrics.
///
/// @param session The `IVSBroadcastSession` that associated with the transmission statistics.
/// @param statistics The current transmission stats
- (void)broadcastSession:(IVSBroadcastSession *)session
transmissionStatisticsChanged:(IVSTransmissionStatistics *)statistics;

/// Indicates that the SDK has updated it's retry state. Retry state communicates the SDK's intentions for automatically
/// reconnecting a failed broadcast.
///
/// @see `IVSBroadcastConfiguration.autoReconnectConfig` for more details.
///
/// @param session The `IVSBroadcastSession` that associated with the retry state change.
/// @param state The updated retry state.
- (void)broadcastSession:(IVSBroadcastSession *)session
     didChangeRetryState:(IVSBroadcastSessionRetryState)state;

@end

NS_ASSUME_NONNULL_END
