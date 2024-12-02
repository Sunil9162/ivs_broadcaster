//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <AmazonIVSBroadcast/IVSBase.h>

/// This will be the `domain` on the `NSError` objects that the Broadcast SDK emits.
IVS_EXPORT NSErrorDomain const IVSBroadcastErrorDomain;

/// For errors emitted by the SDK, they will all have a key of `IVSBroadcastErrorIsFatalKey` in their
/// `userInfo` property. The value will be an BOOL wrapped in an `NSNumber` describing whether the
/// emitted error is fatal or not (fatal means recovery is impsosible).
IVS_EXPORT NSErrorUserInfoKey const IVSBroadcastErrorIsFatalKey;

/// `NSString`, short text describing the source of where the error originated from.
IVS_EXPORT NSErrorUserInfoKey const IVSBroadcastSourceDescriptionErrorKey;

/// `NSString`, short text describing the category of error.
IVS_EXPORT NSErrorUserInfoKey const IVSBroadcastResultDescriptionErrorKey;

/// `NSString`, short text describing the error UID.
IVS_EXPORT NSErrorUserInfoKey const IVSBroadcastUidDescriptionErrorKey;

/// Known errors that can be returned by various APIs in the Broadcast SDK
typedef NS_ENUM(NSInteger, IVSBroadcastError) {

    // MARK: - Device Add/Remove Errors

    /// This happens when you use the exchange devices API but the devices are of a different type, for example
    /// a microphone and a camera. Both devices must be of the same type.
    IVSBroadcastErrorDeviceExchangeIncompatibleTypes = 10100,

    /// This happens when trying to attach a device but the device is not found. This could happen if you
    /// query all the devices and store them in an array, a device goes offline or is unplugged, and then you attempt
    /// to connect to that device.
    IVSBroadcastErrorDeviceNotFound = 10101,

    /// This happens when a device you are trying to add could not be added to as an input source.
    IVSBroadcastErrorDeviceAttachDeviceCouldNotAddAsInput = 10102,

    /// This happens when a new output stream for the attaching device could not be added to the AVCaptureSession.
    IVSBroadcastErrorDeviceAttachDeviceCouldNotAddOutputStream = 10103,

    /// At the moment, only a single input source of each type is allowed. In the future multiple cameras may be allowed,
    /// but a single microphone will likely be a requirement for the foreseeable future.
    IVSBroadcastErrorDeviceTypeAlreadyAttached = 10104,

    /// The device being attached was unable to pair to a `IVSMixerSlotConfiguration`. Make sure your `IVSBroadcastConfiguration`
    /// has a slot with a matching preferred input device type.
    IVSBroadcastErrorDeviceFoundNoMatchingSlot = 10105,

    /// The device that was submitted to attach to the `IVSBroadcastSession` is not supported.
    IVSBroadcastErrorUnsupportedDeviceType = 10106,

    /// When multiple external audio inputs are plugged in, only the most recently connected device can be attached to the broadcast
    /// session. The built-in microphone can always be attached.
    IVSBroadcastErrorTooManyExternalAudioInputs = 10107,

    /// The attaching camera does not support any of the pixel formats that the broadcast SDK supports.
    IVSBroadcastErrorNoSupportedPixelFormats = 10108,

    /// Thrown when the exchange device API is called and the device being swapped out is not currently attached.
    IVSBroadcastErrorExchangeDeviceOldDeviceNotAttached = 10109,

    /// Thrown when there is an attempt to attach a device that is already attached, either through attachDevice or exchangeDevice.
    IVSBroadcastErrorDeviceAlreadyAttached = 10110,

    /// RTC stats are unavailable for this stream because the stream is not currently publishing.
    IVSBroadcastErrorDeviceNotPublishing = 10111,
    
    /// The zoom factor set on an `IVSCamera` must be between `IVSCamera.maxAvailableVideoZoomFactor` and `IVSCamera.maxAvailableVideoZoomFactor` This error is thrown
    /// when the camera's zoom factor is set to a value outside this range.
    IVSBroadcastErrorDeviceInvalidCameraZoomFactor = 10112,
    
    /// This error is thrown when the `-[IVSCamera setVideoZoomFactor:]` API is called
    /// when the `AVCaptureDevice`'s configuration lock could not be taken, or when the underlying
    /// `AVCaptureDevice` is nil, because it could not be constructed.
    IVSBroadcastErrorDeviceCouldNotSetCameraZoomFactor = 10113,

    // MARK: - Configuration Errors

    /// The audio bitrate set on the IVSBroadcastConfiguration must be between 64k and 160k. This error is thrown
    /// when the audio bitrate is set to a value outside this range.
    IVSBroadcastErrorConfigurationInvalidAudioBitrate = 10200,

    /// The audio channels set on the IVSBroadcastConfiguration must be equal to 1 or 2.
    IVSBroadcastErrorConfigurationInvalidAudioChannels = 10201,

    /// The video initial bitrate set on the IVSBroadcastConfiguration must be between 100k and 8,500k. This error is thrown
    /// when the video initial bitrate is set to a value outside this range.
    IVSBroadcastErrorConfigurationInvalidVideoInitialBitrate = 10202,

    /// The video maximum bitrate set on the IVSBroadcastConfiguration must be between 100k and 8,500k. This error is thrown
    /// when the video maximum bitrate is set to a value outside this range.
    IVSBroadcastErrorConfigurationInvalidVideoMaxBitrate = 10203,

    /// The video minimum bitrate set on the IVSBroadcastConfiguration must be between 100k and 8,500k. This error is thrown
    /// when the video minimum bitrate is set to a value outside this range.
    IVSBroadcastErrorConfigurationInvalidVideoMinBitrate = 10204,

    /// The video target framerate set on the IVSBroadcastConfiguration must be between 10 and 60. This error is thrown
    /// when the video target framerate is set to a value outside this range.
    IVSBroadcastErrorConfigurationInvalidVideoTargetFramerate = 10205,

    /// The video keyframe interval set on the IVSBroadcastConfiguration must be between 1 and 10. This error is thrown
    /// when the video keyframe interval is set to a value outside this range.
    IVSBroadcastErrorConfigurationInvalidVideoKeyframeInterval = 10206,

    /// The video size set on the IVSBroadcastConfiguration must have a width and height of greater than 160, less than 1080, and
    /// the total number of pixels must be less than 2,073,600.
    /// For example, the smallest possible size is 160x160, and the biggest possible size is either 1080x1920 or 1920x1080..
    /// This error is thrown when the video size does not meet the specified criteria.
    IVSBroadcastErrorConfigurationInvalidVideoSize = 10207,

    /// The mixer slot name set on the IVSBroadcastConfiguration must be between 1 and 50 characetrs in length.
    /// This error is thrown when the name is shorter or longer than the requirements.
    IVSBroadcastErrorConfigurationInvalidMixerSlotName = 10208,

    /// The mixer slot gain set on the IVSBroadcastConfiguration must be between 0 and 2.
    /// This error is thrown when the gain is set to a value outside this range.
    IVSBroadcastErrorConfigurationInvalidMixerSlotGain = 10209,

    /// The mixer slot transparency set on the IVSBroadcastConfiguration must be between 0 and 1.
    /// This error is thrown when the transparency is set to a value outside this range.
    IVSBroadcastErrorConfigurationInvalidMixerSlotTransparency = 10210,

    /// There are multiple `IVSMixerSlotConfiguration` objects with the same `name`. All names must be unique.
    IVSBroadcastErrorConfigurationDuplicateMixerNames = 10211,

    /// The stage video maximum bitrate set on the `IVSLocalStageStreamVideoConfiguration` must be between 100k and 2,500k. This error is thrown
    /// when the stage video maximum bitrate is set to a value outside this range.
    IVSBroadcastErrorConfigurationInvalidStageVideoMaxBitrate = 10220,

    /// The stage video minimum bitrate set on the `IVSLocalStageStreamVideoConfiguration` must be between 100k and 2,500k. This error is thrown
    /// when the stage video minimum bitrate is set to a value outside this range.
    IVSBroadcastErrorConfigurationInvalidStageVideoMinBitrate = 10221,

    /// The stage video target framerate set on the `IVSLocalStageStreamVideoConfiguration` must be between 10 and 30. This error is thrown
    /// when the stage video target framerate is set to a value outside this range.
    IVSBroadcastErrorConfigurationInvalidStageVideoTargetFramerate = 10222,

    /// The stage video size set on the `IVSLocalStageStreamVideoConfiguration` must have a width and height of greater than 160, less than 720, and
    /// the total number of pixels must be less than 921,600.
    /// For example, the smallest possible size is 160x160, and the biggest possible size is either 720x1280 or 1280x720..
    /// This error is thrown when the video size does not meet the specified criteria.
    IVSBroadcastErrorConfigurationInvalidStageVideoSize = 10223,

    /// The stage audio bitrate set on the `IVSLocalStageStreamAudioConfiguration` must be between 12k and 128k. This error is thrown
    /// when the stage audio bitrate is set to a value outside this range.
    IVSBroadcastErrorConfigurationInvalidStageAudioBitrate = 10224,
    
    /// The stage jitter buffer min delay set on the `IVSJitterBufferConfiguration` must be between 0 and 10k. This error is thrown
    /// when the stage jitter buffer min delay is set to a value outside this range.
    IVSBroadcastErrorConfigurationInvalidStageJitterBufferMinDelay = 10225,

    /// An encoder that matches the associated codec and video configuration could not be found.
    IVSBroadcastErrorEncoderNotFound = 10226,

    /// The configuration has been locked by the SDK to guarantee compatibility with this device and the
    /// upstream IVS channel.
    IVSBroadcastErrorConfigurationLocked = 10227,

    // MARK: - Setup Errors

    /// When creating the preview view for a surface, there was an error obtaining the metal default library.
    /// The property "sourceError" will include the originating error.
    IVSBroadcastErrorPreviewMetalLibraryInvalid = 10300,

    /// When creating the preview view for a surface, there was an error generating the metal render pipeline state
    /// The property "sourceError" will include the originating error.
    IVSBroadcastErrorPreviewMetalStateDescriptorInvalid = 10301,

    /// The device you're using this on does not support Metal. Metal is a requirement for using the IVS Broadcast SDK.
    IVSBroadcastErrorMetalNotSupported = 10302,

    // MARK: - Session Errors

    /// This is thrown when the `IVSBroadcastSession`'s `isReady` property is set to `NO` and a method is called on the
    /// session anyway.
    IVSBroadcastErrorSessionIsNotReady = 10400,

    /// This is thrown when an `IVSCustomImageSource` is used and an unsupported pixel format is provided.
    /// The currently supported pixel formats are:
    /// `kCVPixelFormatType_32BGRA`
    /// `kCVPixelFormatType_420YpCbCr8BiPlanarFullRange`
    /// `kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange`
    /// On devices that support it, the `Lossless` and `Lossy` equivalents of these formats are also supported.
    IVSBroadcastErrorInvalidVideoFormat = 10401,

    /// This is thrown when an image submitted via `onSampleBuffer` exceeds 32400 KB (32 bpp at 3840×2160).
    /// If you have images in resolutions greater than 4k, please convert them to format such as `kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange`
    /// to reduce the total size of the image below the threshold.
    IVSBroadcastErrorImageTooLarge = 10402,

    /// This is thrown when PCM data is submitted via `onPCMBuffer` or `onSampleBuffer` and the total size of the data is greater than 5.5 MB.
    /// If you run into this while submitting valid data, break up your sample into multiple smaller samples.
    /// This error will only be emitted once per audio source.
    IVSBroadcastErrorPCMDataTooLong = 10403,

    /// This is thrown when `IVSBroadcastSession.applicationAudioSessionStrategy` is set to `noAction` and an attempt to attach a microphone
    /// to the SDK is attempted. Microphones can still be used with the noAction strategy, but they must be managed by the host application and
    /// have their samples provided via an `IVSCustomAudioSource`.
    IVSBroadcastErrorInvalidAudioSessionStrategy = 10404,

    /// This is thrown when the broadcast session is stopped due to a loss in network connectivity. You can monitor your device's connection
    /// and start the stream again when connectivity is restored.
    IVSBroadcastErrorNetworkConnectivityLost = 10405,

    /// This API must only be called while the application is in the foreground.
    IVSBroadcastErrorForegroundOnly = 10406,

    /// An app background video source already exists. You must call `removeImageSourceOnAppBackgrounded` before using
    /// this API again.
    IVSBroadcastErrorBackgroundVideoSourceAlreadyExists = 10407,

    /// The background video source is currently live. If your app responds to `UIApplicationWillEnterForegroundNotification`, it is possible your app will receive that notification
    /// before the broadcast SDK does. Dispatching a block to the main queue will allow the SDK to receive that notification, then the `removeImageSourceOnAppBackgrounded`
    /// will be safe to call.
    IVSBroadcastErrorBackgroundVideoSourceIsLive = 10408,

    /// The background video source is currently live because the attached camera is waiting to receive the `AVCaptureSessionInterruptionEndedNotification` notification to be fired.
    /// This is fired some time after the app returns to the foreground. Waiting for that notification and dispatching a block to the main queue that calls this API again will resolve
    /// this error if the source of the error is the attached camera.
    /// An alternative workaround would be to detach and reattach the camera.
    IVSBroadcastErrorBackgroundVideoSourceIsWaitingForCamera = 10409,

    /// This is thrown when the SDK's internal state is invalid.
    IVSBroadcastErrorInvalidState = 10410,

    /// This is thrown when PCM data is submitted via `onPCMBuffer` with multiple AudioBuffer structs attached and one of the following is false
    /// All AudioBuffers have the same data length.
    /// The channels are non-interleaved (planar).
    /// The number of channels reported by the format is the same as the number of AudioBuffer structs.
    /// All of the AudioBuffers are  single channel (together they can create multiple channels, but each individually must be single channel).
    /// There are only 2 AudioBuffer structs (if there are more than 2, all channels after 2 will be droppped).
    /// When this error is emitted, only a single audio channel will be processed, unless the error is too many channels, at which point 2 channels will be processed.
    /// This error will only be emitted once per audio source.
    IVSBroadcastErrorPCMUnsupportedSample = 10411,

    /// This is thrown when the host application is in the background with an active `AVAudioSession`, but the `AVAudioSession` was just interrupted.
    /// At that point the application is likely to be suspended, and any in progress sessions will be ended.
    IVSBroadcastErrorAppSuspension = 10412,

    /// The background video source was removed before finishing.
    IVSBroadcastErrorBackgroundVideoSourceWasRemoved = 10413,

    /// This is thrown when the host application is in a phone call and the SDK attempts to activate the `AVAudioSession`. This can be safely ignored by host applications,
    /// but can be useful to track to inform end users that the SDK might not be working at the moment.
    IVSBroadcastErrorInPhoneCall = 10414,

    /// This is thrown when iOS notifies the SDK that the `AVAudioSession` is interrupted, and then the SDK attempts to activate the session before the interruption is ended.
    IVSBroadcastErrorSessionInterrupted = 10415,
};
