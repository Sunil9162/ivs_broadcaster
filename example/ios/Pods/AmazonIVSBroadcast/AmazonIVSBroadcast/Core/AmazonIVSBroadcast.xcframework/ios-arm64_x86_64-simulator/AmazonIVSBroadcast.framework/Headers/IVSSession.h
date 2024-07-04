//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <AmazonIVSBroadcast/IVSBase.h>
#import <AmazonIVSBroadcast/IVSBroadcastConfiguration.h>

NS_ASSUME_NONNULL_BEGIN

@class IVSDeviceDescriptor;
@class IVSImagePreviewView;
@class IVSMixer;
@class UIView;
@protocol IVSDevice;
@protocol IVSCustomImageSource;
@protocol IVSCustomAudioSource;
@protocol IVSBackgroundImageSource;
@protocol MTLDevice;
@protocol MTLCommandQueue;

/// A value representing how the `IVSBroadcastSession` will interact with `AVAudioSession`.
/// If you are using the Stages SDK, please in `IVSStageAudioManager` instead.
typedef NS_ENUM(NSInteger, IVSSessionAudioSessionStrategy) {
    /// The SDK controls `AVAudioSession` completely and will set the category to `playAndRecord`.
    IVSSessionAudioSessionStrategyPlayAndRecord,
    /// The SDK controls the `AVAudioSession` completely and will set the category to `playAndRecord`.
    /// On devices with both handset and speaker, the speaker will be preferred.
    IVSSessionAudioSessionStrategyPlayAndRecordDefaultToSpeaker,
    /// The SDK controls `AVAudioSession` completely and will set the category to `record`.
    /// There is a known issue with the `recordOnly` category and AirPods. Please use `playAndRecord` if you wish to use AirPods.
    IVSSessionAudioSessionStrategyRecordOnly,
    /// The SDK does not control `AVAudioSession` at all. If this strategy is selected only custom audio sources will be allowed.
    /// Microphone based sources will not be returned or added by any APIs.
    IVSSessionAudioSessionStrategyNoAction,
    /// The SDK controls `AVAudioSession` completely and will set the category to `playAndRecord`.
    /// Options include `AVAudioSessionCategoryOptionMixWithOthers` and mode is set to `AVAudioSessionModeVideoChat`.
    /// This option is used automatically when using the opt-in Stages functionality. When in a Stage call, do not change the audio session strategy manually.
    IVSSessionAudioSessionStrategyStages __attribute__((deprecated("This strategy should not be used. Use IVSStageAudioManager instead."))),
} NS_SWIFT_NAME(IVSBroadcastSession.AudioSessionStrategy);

/// The base of both Broadcast and Stage Sessions, providing common APIs for working with devices
/// and getting a preview for the composited session.
IVS_EXPORT
@interface IVSSession : NSObject

/// A value that indicates whether the broadcast session automatically changes settings in the app’s shared audio session.
///
/// @note Changing this property can impact the devices return by `listAvailableDevices`.
///
/// The value of this property defaults to `playAndRecord`, causing the broadcast session to automatically configure the app’s
/// shared `AVAudioSession` instance . You can also set it to `.recordOnly` to still let the SDK manage
/// the settings, but use the `record` `AVAudioSession` category instead of `playAndRecord`. Note there is an issue with recording
/// audio with AirPods using `recordOnly`, so `playAndRecord` is recommended.
/// If you set this property’s value to `noAction`, your app is responsible for selecting appropriate audio session settings.
/// Recording may fail if the audio session’s settings are incompatible with the the desired inputs.
/// Letting the broadcast SDK manage the audio session is especially useful when dealing with audio input devices other than
/// the built in microphone, as it will allow the SDK to manage all of the routing for you.
/// If this value is anything except `noAction`, it is expected that your app will not interact with `AVAudioSession` while an `IVSBroadcastSession` is allocated.
/// If you switch this to `noAction` after, setting up the `IVSBroadcastSession`, the broadcast SDK will immediately stop interacting with AVAudioSession.
/// It will not reset any values to their original state, so if your app needs control, be prepared to set all relevant properties since the broadcast SDK may have
/// changed many things.
@property (nonatomic, class) IVSSessionAudioSessionStrategy applicationAudioSessionStrategy;

/// The broadcast SDK version.
@property (nonatomic, class, readonly) NSString *sdkVersion;

/// The unique ID of this broadcast session. This will be updated every time the stream is stopped.
@property (nonatomic, strong, readonly) NSString *sessionId;

/// Whether or not the session is ready for use.
///
/// This state is constant once the session has been initialized with the exception of when your app
/// is backgrounded. When backgrounded, isReady will become NO regardless of its previous state when the SDK tears
/// down some resources. When coming back to the foreground isReady will receive a new `isReady` value. Outside
/// of backgrounding and foregrounding the value of `isReady` will never change. If this method returns NO, be sure to assign
/// the `delegate` property in the `IVSBroadcastSession` initializer so that you receive the relevant error.
@property (nonatomic, readonly) BOOL isReady;

/// Logging level for the broadcast session. Default is `IVSBroadcastLogLevelError`.
@property (nonatomic) IVSBroadcastLogLevel logLevel;

/// The session mixer instance. This allows you to control on-screen elements.
@property (nonatomic, nonnull, readonly) IVSMixer *mixer;

/// List available devices for use with a broadcast session.
/// The value of `applicationAudioSessionStrategy` will impact the devices returned by this API.
///
/// @discussion
/// 
/// The return order of these devices is predictable:
///
/// * All cameras will be returned before any microphones.
///
/// Devices of the same type with be sorted by, in priority order:
/// 
/// * `position` (based on `rawValue` of the `IVSDevicePosition` enum in ascending order)
/// * `isDefault` (`YES` will appear before `NO`)
/// * `friendlyName` (sorted alphabetically in ascending order)
+ (NSArray<IVSDeviceDescriptor *> *)listAvailableDevices;

/// List attached, active devices being used with this broadcast session.
///
/// @note since devices are attached and detached asynchronously, this might not include the most recent changes. Use
/// `awaitDeviceChanges` to wait for all changes to complete before calling this to guarantee up to date results.
- (NSArray<id<IVSDevice>> *)listAttachedDevices;

/// Create and attach a device based on a descriptor for use with the broadcast session.
/// @param descriptor The device descriptor for the device to be attached
/// @param slotName The name of a slot to bind to when attaching. If `nil` is provided it will attach to the first compatible slot.
/// @param onComplete A callback that contains the new device or any error that occured while attaching. Invoked when the operation has completed. Always invoked on the main queue.
- (void)attachDeviceDescriptor:(IVSDeviceDescriptor *)descriptor
                toSlotWithName:(nullable NSString *)slotName
                    onComplete:(nullable void (^)(id<IVSDevice> _Nullable, NSError * _Nullable))onComplete;

/// Attach a device for use with the broadcast session.
/// @param device The device to be attached
/// @param slotName The name of a slot to bind to when attaching. If `nil` is provided it will attach to the first compatible slot.
/// @param onComplete A callback that contains any error that occured while attaching. Invoked when the operation has completed. Always invoked on the main queue.
- (void)attachDevice:(id<IVSDevice>)device
      toSlotWithName:(nullable NSString *)slotName
          onComplete:(nullable void (^)(NSError * _Nullable))onComplete;

/// Close and detach a device based on its descriptor.
/// @param descriptor The descriptor for the device to close.
/// @param onComplete Invoked when the operation has completed. Always invoked on the main queue.
- (void)detachDeviceDescriptor:(IVSDeviceDescriptor *)descriptor
                    onComplete:(nullable void (^)(void))onComplete;

/// Close and detach a device.
/// @param device The device to close.
/// @param onComplete Invoked when the operation has completed. Always invoked on the main queue.
- (void)detachDevice:(id<IVSDevice>)device
          onComplete:(nullable void (^)(void))onComplete;

/// Exchange a device with another device of the same type. For hardware backed devices, this API might make
/// performance optimizations around locking compared to detaching and attaching the devices separately.
/// This method should not be used for custom audio and image sources.
/// @param oldDevice The device to replace
/// @param newDevice The descriptor of the new device to attach
/// @param onComplete A callback that contains the new device or any error that occured while attaching. Invoked when the operation has completed. Always invoked on the main queue.
- (void)exchangeOldDevice:(id<IVSDevice>)oldDevice
            withNewDevice:(IVSDeviceDescriptor *)newDevice
               onComplete:(nullable void (^)(id<IVSDevice> _Nullable, NSError * _Nullable))onComplete;

/// Waits for all pending device operations to complete, then invokes onComplete.
/// @param onComplete Always invoked on the main queue.
- (void)awaitDeviceChanges:(void (^)(void))onComplete;

/// Create an image input for a custom source. This should only be used if you intend to generate and feed image data to the SDK manually.
- (id<IVSCustomImageSource>)createImageSourceWithName:(NSString *)name;

/// Create an audio input for a custom source. This should only be used if you intend to generate and feed pcm audio data to the SDK manually.
- (id<IVSCustomAudioSource>)createAudioSourceWithName:(NSString *)name;

/// Gets a view that will render a preview image of the composited video stream. This will match what consumers see when watching the broadcast.
/// @param aspectMode the aspect mode to apply to the image stream rendering on the view.
/// @param outError On input, a pointer to an error object. If an error occurs, the pointer is an NSError object that describes the error. If you don’t want error information, pass in nil.
///
/// @note this must be called on the main thread
- (nullable IVSImagePreviewView *)previewViewWithAspectMode:(IVSAspectMode)aspectMode error:(NSError *__autoreleasing *)outError;

@end

NS_ASSUME_NONNULL_END
