//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import <AmazonIVSBroadcast/IVSDevice.h>
#import <AmazonIVSBroadcast/IVSBase.h>
#import <AmazonIVSBroadcast/IVSVideoCodec.h>

NS_ASSUME_NONNULL_BEGIN

/// Supported aspect modes.
typedef NS_ENUM(NSInteger, IVSAspectMode) {
    /// Will simply fill the bounding area with the image, disregarding the aspect ratio.
    IVSAspectModeNone = 0,
    /// Will fit the entire image within the bounding area while maintaining the correct aspect ratio. in practice this means that there will be letterboxing or pillarboxing.
    IVSAspectModeFit,
    /// Will fill the bounding area with the image while maintaining the aspect ratio. in practice this means that the image will likely be cropped.
    IVSAspectModeFill,
} NS_SWIFT_NAME(IVSBroadcastConfiguration.AspectMode);

/// Supported audio quality presets. These will increase the quality of the resulting audio at the expense of CPU time.
/// The impact on CPU is non-negligable, and can take up as much as 30% of the total CPU usage of the SDK.
/// The default value is Medium.
typedef NS_ENUM(NSInteger, IVSAudioQuality) {
    /// The minimum quality audio, but least taxing on the CPU
    IVSAudioQualityMinimum = 0,
    /// Low quality audio while still efficient for the CPU
    IVSAudioQualityLow,
    /// A middle ground between audio quality and CPU usage
    IVSAudioQualityMedium,
    /// Higher quality audio at the cost of more CPU usage
    IVSAudioQualityHigh,
    /// The maximum quality audio at the cost of significant CPU resources
    IVSAudioQualityMaximum,
} NS_SWIFT_NAME(IVSBroadcastConfiguration.AudioQuality);

/// A configuration object describing the desired format of the final output audio stream.
IVS_EXPORT
@interface IVSAudioConfiguration : NSObject

/// The audio bitrate for the output audio stream.
/// By default this is `96,000`.
@property (nonatomic, readonly) NSInteger bitrate;

/// Set the bitrate for the output audio stream. This must be greater than 64k and less than 160k.
/// If the provided bitrate falls outside this range, bitrate will not be set and the provided outError will be set.
/// @param bitrate The average bitrate for the final output audio stream.
/// @param outError On input, a pointer to an error object. If an error occurs, the pointer is an NSError object that describes the error. If you don’t want error information, pass in nil.
/// @return if the set operation is successful or not.
- (BOOL)setBitrate:(NSInteger)bitrate error:(NSError *__autoreleasing *)outError;

/// The number of channels for the output audio stream.
/// By default this is `2`.
@property (nonatomic, readonly) NSInteger channels;

/// Set the number of audio channels for the output stream.
/// Currently this must be 1 or 2, otherwise the provided outError will be set.
/// @param channels the number of channels for the audio output stream
/// @param outError On input, a pointer to an error object. If an error occurs, the pointer is an NSError object that describes the error. If you don’t want error information, pass in nil.
/// @return if the set operation is successful or not.
- (BOOL)setChannels:(NSInteger)channels error:(NSError *__autoreleasing *)outError;

/// The quality of the audio encoding
@property (nonatomic, readonly) IVSAudioQuality quality;

/// Sets the quality for the audio encoder. See `IVSAudioQuality` for more details.
- (void)setQuality:(IVSAudioQuality)quality;

@end

/// Profiles for the automatic video bitrate behavior.
typedef NS_ENUM(NSInteger, IVSAutomaticBitrateProfile) {
    /// This profile is conservative in how it ramps up the bitrate when the network health is good, but fast to drop the bitrate when network health is bad.
    /// This leads to slow recovery times after congestion, but the bitrate will be more stable.
    IVSAutomaticBitrateProfileConservative = 0,
    /// This profile is fast to ramp up the bitrate when the network health is good, and fast to drop the bitrate when network health is bad.
    /// This will lead to quicker recoveries towards the maximum bitrate after congestion, but could result in congestion being detected more
    /// frequently as a result of probing above the available bandwidth.
    IVSAutomaticBitrateProfileFastIncrease = 1,
} NS_SWIFT_NAME(IVSVideoConfiguration.AutomaticBitrateProfile);

/// A configuration object describing the desired format of the final output video stream
IVS_EXPORT
@interface IVSVideoConfiguration : NSObject

/// The video codec for the output video stream.
/// By default this is `H264`.
/// To get an `IVSVideoConfiguration` with a different codec, `IVSCodecDiscovery` must be used.
@property (nonatomic, readonly) IVSVideoCodec *codec;

/// The initial bitrate for the output video stream.
/// By default this is `2,100,000`.
@property (nonatomic, readonly) NSInteger initialBitrate;

/// Sets the initial bitrate for the output video stream. This value must be between 100k and 8,500k
/// If the provided bitrate falls outside this range, bitrate will not be set and the provided outError will be set.
/// @param initialBitrate the initial bitrate for the output video stream
/// @param outError On input, a pointer to an error object. If an error occurs, the pointer is an NSError object that describes the error. If you don’t want error information, pass in nil.
/// @return if the set operation is successful or not.
- (BOOL)setInitialBitrate:(NSInteger)initialBitrate error:(NSError *__autoreleasing *)outError;

/// The keyframe interval for the output video stream in seconds.
/// By default this is `2`.
@property (nonatomic, readonly) float keyframeInterval;

/// Sets the keyframe interval for the output video stream. This value must be between 1 and 5
/// /// If the provided keyframe interval falls outside this range, the keyframe interval will not be set and the provided outError will be set.
/// @param keyframeInterval the keyframe interval for the output video stream
/// @param outError On input, a pointer to an error object. If an error occurs, the pointer is an NSError object that describes the error. If you don’t want error information, pass in nil.
/// @return if the set operation is successful or not.
- (BOOL)setKeyframeInterval:(float)keyframeInterval error:(NSError *__autoreleasing *)outError;

/// The maximum bitrate for the output video stream.
/// By default this is `6,000,000`.
@property (nonatomic, readonly) NSInteger maxBitrate;

/// Sets the maximum bitrate for the output video stream. This value must be between 100k and 8,500k
/// If the provided bitrate falls outside this range, bitrate will not be set and the provided outError will be set.
/// @param maxBitrate the maximum bitrate for the output video stream
/// @param outError On input, a pointer to an error object. If an error occurs, the pointer is an NSError object that describes the error. If you don’t want error information, pass in nil.
/// @return if the set operation is successful or not.
- (BOOL)setMaxBitrate:(NSInteger)maxBitrate error:(NSError *__autoreleasing *)outError;

/// The minimum bitrate for the output video stream.
/// By default this is `300,000`.
@property (nonatomic, readonly) NSInteger minBitrate;

/// Sets the minimum bitrate for the output video stream. This value must be between 100k and 8,500k
/// If the provided bitrate falls outside this range, bitrate will not be set and the provided outError will be set.
/// @param minBitrate the minimum bitrate for the output video stream
/// @param outError On input, a pointer to an error object. If an error occurs, the pointer is an NSError object that describes the error. If you don’t want error information, pass in nil.
/// @return if the set operation is successful or not.
- (BOOL)setMinBitrate:(NSInteger)minBitrate error:(NSError *__autoreleasing *)outError;

/// The resolution of the output video stream.
/// By default this is `720x1280`.
@property (nonatomic, readonly) CGSize size;

/// Sets the resolution of the output video stream.
/// The width and height must both be between 160 and 1920, and the maximum total number of pixels
/// is 2,073,600. So the smallest size you can provide is 160x160, and the largest
/// is either 1080x1920 or 1920x1080. However something like 1920x1200 would not be
/// supported. 1280x180 however is supported.
/// If the provided resolution does not meet this criteria, the resolution will not be set and the provided outError will be set.
/// @param size The resolution of the output video stream
/// @param outError On input, a pointer to an error object. If an error occurs, the pointer is an NSError object that describes the error. If you don’t want error information, pass in nil.
/// @return if the set operation is successful or not.
- (BOOL)setSize:(CGSize)size error:(NSError *__autoreleasing *)outError;

/// The target framerate of the output video stream.
/// By default this is `30`.
@property (nonatomic, readonly) NSInteger targetFramerate;

/// Sets the target framerate of the output video stream. This must be between 10 and 60
/// If the provided framerate falls outside this range, the framerate will not be set and the provided outError will be set.
/// @param targetFramerate The target framerate for the output video stream
/// @param outError On input, a pointer to an error object. If an error occurs, the pointer is an NSError object that describes the error. If you don’t want error information, pass in nil.
/// @return if the set operation is successful or not.
- (BOOL)setTargetFramerate:(NSInteger)targetFramerate error:(NSError *__autoreleasing *)outError;

/// Setting this to `YES` will enable transparency between mixer slots at the cost of some memory usage.
///
/// For example, if you wanted to broadcast the rear facing camera taking up the entire view port, and then overlay the front facing camera
/// with 30% transparency so that you can still partially see the rear facing camera under the front facing camera, this property would need to be `YES`.
///
/// @note Enabling this option does increase the memory usage of the pipeline. If you are not going to use multiple mixer slots with blending, leave this as `NO`.
///
/// By default this is `NO`.
@property (nonatomic) BOOL enableTransparency;

/// Whether the output video stream uses B (Bidirectional predicted picture) frames.
///
/// By default this is `YES`.
@property (nonatomic) BOOL usesBFrames;

/// Whether the output video stream will automatically adjust the bitrate based on network conditions.
///
/// Use `minBitrate` and `maxBitrate` to specify the bounds when this is `YES`.
/// By default this is `YES`.
@property (nonatomic) BOOL useAutoBitrate;

/// The profile to use for the video's automatic bitrate algorithm. This has no effect if `useAutoBitrate` is `false`.
/// By default this is `.conservative`.
@property (nonatomic) IVSAutomaticBitrateProfile autoBitrateProfile;

@end

/// A configuration object describing additional network parameters
IVS_EXPORT
@interface IVSNetworkConfiguration : NSObject

/// Setting this to `YES` will enable IPv6 as an option that will be preferred if it is available to the user's device.
/// Broadcasters on IPv6-native networks may have better QoS with this option enabled.
/// By default this is `NO`.
@property (nonatomic) BOOL useIPv6;

@end

/// A configuration object describing a layer for composition on the final video output stream.
IVS_EXPORT
@interface IVSMixerSlotConfiguration : NSObject

/// The aspect ratio of the mixer slot
///
/// By default this is `IVSAspectMode.Fit`.
/// @note Setting this property always has the side-effect of setting `matchCanvasAspectMode` to `false`.
@property (nonatomic) IVSAspectMode aspect;

/// The fill color of the mixer slot
/// By default this is `UIColor.clear`.
@property (nonatomic, strong) UIColor *fillColor;

/// The gain of the mixer slot
/// By default this is `1`.
@property (nonatomic, readonly) float gain;

/// Sets the gain of the mixer slot. This must be between 0 and 2.
/// A gain of 1 means no change. A gain less than 1 will suppress, and greater than 1 will amplify.
/// If the provided gain falls outside this range, the gain will not be set and the provided outError will be set.
/// @param gain The gain of the mixer slot.
/// @param outError On input, a pointer to an error object. If an error occurs, the pointer is an NSError object that describes the error. If you don’t want error information, pass in nil.
/// @return if the set operation is successful or not.
- (BOOL)setGain:(float)gain error:(NSError *__autoreleasing *)outError;

/// Whether or not this mixer slot automatically matches the canvas aspect mode.
/// This defaults to `YES` but will be set to `NO` automatically if `aspect` is changed.
/// Setting this back to `YES` will once again match the canvas aspect mode, but will leave the `aspect`
/// property unchanged, i.e. it will still be the custom value you set it to.
@property (nonatomic) BOOL matchCanvasAspectMode;

/// Whether or not this mixer slot automatically matches the canvas size.
/// This defaults to `YES` but will be set to `NO` automatically if `size` is changed.
/// Setting this back to `YES` will once again match the canvas size, but will leave the `size`
/// property unchanged, i.e. it will still be the custom value you set it to.
@property (nonatomic) BOOL matchCanvasSize;

/// The name of this mixer slot.
/// By default this is `default`.
@property (nonatomic, strong, readonly) NSString *name;

/// Sets the name of this mixer slot. The length of the name must be between 1 and 50 characters in length
/// @param name The name of the mixer slot
/// @param outError On input, a pointer to an error object. If an error occurs, the pointer is an NSError object that describes the error. If you don’t want error information, pass in nil.
/// @return if the set operation is successful or not.
- (BOOL)setName:(NSString *)name error:(NSError *__autoreleasing *)outError;

/// The position of the mixer slot.
/// By default this is `0x0`
@property (nonatomic) CGPoint position;

/// The preferred video input device for the mixer slot.
/// By default this is `IVSDeviceType.Camera`.
@property (nonatomic) IVSDeviceType preferredVideoInput;

/// The preferred audio input device for the mixer slot.
/// By default this is `IVSDeviceType.Microphone`.
@property (nonatomic) IVSDeviceType preferredAudioInput;

/// The size for the mixer slot.
///
/// By default this is `720x1280`.
/// @note Setting this property always has the side-effect of setting `matchCanvasSize` to `false`.
@property (nonatomic) CGSize size;

/// The transparency for the mixer slot. 0 = fully opaque, 1 = fully transparent.
///
/// By default this is `0`.
@property (nonatomic, readonly) float transparency;

/// Sets the transparency for this mixer slot. 0 = fully opaque, 1 = fully transparent
/// The value must be btewen 0 and 1 and `IVSVideoConfiguration.enableTransparency` must be `YES`,
/// otherwise transparency will not be set and the provided outError will be set.
///
/// @note For transparency to work, `IVSVideoConfiguration.enableTransparency` must be set to `YES`.
///
/// @param transparency The transparency of the mixer slot.
/// @param outError On input, a pointer to an error object. If an error occurs, the pointer is an NSError object that describes the error. If you don’t want error information, pass in nil.
/// @return if the set operation is successful or not.
- (BOOL)setTransparency:(float)transparency error:(NSError *__autoreleasing *)outError;

/// The z-index of the mixer slot. Higher values are rendered in front of lower values.
/// By default this is `0`.
@property (nonatomic) int zIndex;

@end

/// A collection of `IVSMixerSlotConfiguration` objects.
IVS_EXPORT
@interface IVSMixerConfiguration : NSObject

/// The mixer slot configurations to be parent with the broadcast session that owns this mixer config.
/// By default this is an empty array.
@property (nonatomic, strong) NSArray<IVSMixerSlotConfiguration *> *slots;

/// The aspect mode for the output video stream.
/// Be aware that the slot, the device screen containing the preview, and the camera feeding the slot have aspect ratios, as well.
/// Different aspect ratios in each of those layers may lead to unexpected results.
/// By default this is `IVSAspectMode.Fit`.
@property (nonatomic) IVSAspectMode canvasAspectMode;

@end

/// Possible log levels for `IVSBroadcastSession.logLevel`
typedef NS_ENUM(NSInteger, IVSBroadcastLogLevel) {
    /// Debugging messages, potentially quite verbose.
    IVSBroadcastLogLevelDebug,
    /// Informational messages.
    IVSBroadcastLogLevelInfo,
    /// Warning messages.
    IVSBroadcastLogLevelWarn,
    /// Error conditions and faults.
    IVSBroadcastLogLevelError,
} NS_SWIFT_NAME(IVSBroadcastSession.LogLevel);

/// An object that can configure SDK auto-reconnect functionality.
IVS_EXPORT
@interface IVSBroadcastAutoReconnectConfiguration : NSObject

/// Enables auto-reconnect. This defaults to `false`.
/// When this is `true`, the retry logic will be active after a call to `start`
/// and before a call to `stop`. Calling `stop` will automatically cancel
/// any pending retries, regardless of the retry state. To receive updates about the
/// retry state, observe `IVSBroadcastSessionDelegate:broadcastSession:didChangeRetryState`
@property (nonatomic) BOOL enabled;

@end

/// An object to broadcast, transform, and distribute audio video content.
/// Changing any properties on this object after providing it to `IVSBroadcastSession` will not have any effect.
/// A copy of the configuration is made and kept internally.
/// To make changes to the session live, use the `IVSBroadcastSession.mixer` APIs, or `IVSBroadcastSession.setLogLevel`.
IVS_EXPORT
@interface IVSBroadcastConfiguration : NSObject

/// This describes the audio configuration for the broadcast esssion.
@property (nonatomic, strong) IVSAudioConfiguration *audio;
/// This describes the video configuration for the broadcast esssion.
@property (nonatomic, strong) IVSVideoConfiguration *video;
/// This describes additional network configuration for the broadcast session.
@property (nonatomic, strong) IVSNetworkConfiguration *network;
/// This describes the mixer configuration for the broadcast esssion.
@property (nonatomic, strong) IVSMixerConfiguration *mixer;
/// This describes the auto-reconnect configuration for the broadcast session.
@property (nonatomic, strong) IVSBroadcastAutoReconnectConfiguration *autoReconnect;
/// Logging level for the broadcast session. Default is `IVSBroadcastLogLevelError`.
/// In order to catch logs at a more granular level than `Error` during the initialization process,
/// you will need to use this property instead of the `IVSBroadcastSession.logLevel` property.
@property (nonatomic) IVSBroadcastLogLevel logLevel;

/// Creates a `IVSBroadcastConfiguration` with pre-defined audio, video, and mixer
/// configurations
/// @param audio the audio configuration.
/// @param video the video configuration.
/// @param mixer the mixer configuration.
- (instancetype)initWithAudio:(IVSAudioConfiguration *)audio
                        video:(IVSVideoConfiguration *)video
                        mixer:(IVSMixerConfiguration *)mixer;

@end

NS_ASSUME_NONNULL_END
