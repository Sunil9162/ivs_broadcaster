//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AmazonIVSBroadcast/IVSBroadcastConfiguration.h>
#import <AmazonIVSBroadcast/IVSDevice.h>
#import <AmazonIVSBroadcast/IVSImageDeviceFrame.h>

NS_ASSUME_NONNULL_BEGIN

@class AVSampleBufferDisplayLayer;
@class IVSImagePreviewView;
@class IVSCameraFormat;
@protocol IVSCameraDelegate;

/// This represents an IVSDevice that provides video samples.
IVS_EXPORT
@protocol IVSImageDevice <IVSDevice>

/// Sets the current rotation of the video device. This will be used to transform the output stream
///
/// This is handled automatically when attaching a camera via an `IVSDeviceDescriptor`.
///
/// @param rotation The rotation in radians
- (void)setHandsetRotation:(float)rotation;

/// Gets a view that will render a preview image of this device.
/// @param outError On input, a pointer to an error object. If an error occurs, the pointer is an NSError object that describes the error. If you don’t want error information, pass in nil.
///
/// @note this must be called on the main thread
- (nullable IVSImagePreviewView *)previewViewWithError:(NSError *__autoreleasing *)outError;

/// Gets a view that will render a preview image of this device with the provided aspect ratio.
/// @param aspectMode the aspect mode to apply to the image stream rendering on the view.
/// @param outError On input, a pointer to an error object. If an error occurs, the pointer is an NSError object that describes the error. If you don’t want error information, pass in nil.
///
/// @note this must be called on the main thread
- (nullable IVSImagePreviewView *)previewViewWithAspectMode:(IVSAspectMode)aspectMode error:(NSError *__autoreleasing *)outError;

/// Set a callback to receive information about image frames as they move through this device. This will always be invoked on the main queue.
/// @param callback that takes a `IVSImageDeviceFrame`
- (void)setOnFrameCallback:(nullable void (^)(IVSImageDeviceFrame *))callback;

/// Create an `AVSampleBufferDisplayLayer` that will have sample buffers rendered to. The SDK handles all rendering and flushing and the host application
/// should avoid calling anything that directly deals with rendering media samples.
/// @note this does not respect the `setHandsetRotation` API. Any rotation will need to be applied manually to the layer, including the automatic front facing camera mirroring.
- (AVSampleBufferDisplayLayer *)createSampleBufferDisplayLayer;

@end

/// An extention of `IVSImageDevice` that allows for submitting `CMSampleBuffer`s manually.
/// The currently supported pixel formats are:
/// `kCVPixelFormatType_32BGRA`
/// `kCVPixelFormatType_420YpCbCr8BiPlanarFullRange`
/// `kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange`
/// On devices that support it, the `Lossless` and `Lossy` equivalents of these formats are also supported.
///
/// @note Make sure you have an `IVSMixerSlotConfiguration` that requests the `preferredVideoInput` value of `IVSDeviceTypeUserVideo`.
IVS_EXPORT
@protocol IVSCustomImageSource <IVSImageDevice>

/// Submit a frame to the broadcaster for processing.
/// @param sampleBuffer a sample buffer with a `CVPixelBuffer` with a supported pixel format.
- (void)onSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

/// An extention of `IVSCustomImageSource` that is used to pre-encode an image or video to be rendered when the application
/// goes into the background.
///
/// The timing information on the samples provided via `onSampleBuffer` is ignored on this image source, every image submitted will
/// be encoded as the next frame based on the `targetFramerate` on the provided `IVSVideoConfiguration`.
///
/// @note samples submitted will be processed on the invoking thread. For large amounts samples, submit them on a background queue.
///
/// Generating large numbers of samples from MP4 files is fairly straight forward using AVFoundation. There are multiple ways to do it in fact
/// You can use `AVAssetImageGenerator` and `generateCGImagesAsynchronously` to generate an image at every 1 / FPS increment.
/// Be certain to set `requestedTimeToleranceAfter` and `requestedTimeToleranceBefore` to `.zero`, otherwise it will batch the same frame multiple times.
///
/// You can also use an `AVPlayer` instance with `AVPlayerItemVideoOutput` and a `DisplayLink`, using the `copyPixelBuffer` API from the video output.
///
/// Both can provide a series of CVPixelBuffers to submit to this API in order to broadcast a looping clip while in the background.
///
IVS_EXPORT
@protocol IVSBackgroundImageSource <IVSCustomImageSource>

/// Signals that no more images will be submitted for encoding and final processing should begin.
/// Any errors that happen during this process will be emitted through the callback provided to `createAppBackgroundImageSource`.
- (void)finish;

/// A convenience API that doesn't require creating a `CMSampleBufferRef` to provide to the `IVSCustomImageSource` API, since timing data is ignored for the background source.
/// @param pixelBuffer The PixelBuffer to be encoded.
- (void)addPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

/// An extension of `IVSImageDevice` that represents a physical camera accessible by the host device.
IVS_EXPORT
@protocol IVSCamera <IVSImageDevice, IVSMultiSourceDevice>

/// Assign a delegate to receive updates about the attached camera.
@property (nonatomic, weak) id<IVSCameraDelegate> delegate;

/// The minimum value which can be provided to the `setVideoZoomFactor` API.
@property (readonly) CGFloat minAvailableVideoZoomFactor;

/// The maximum value which can be provided to the `setVideoZoomFactor` API.
@property (readonly) CGFloat maxAvailableVideoZoomFactor;

/// Applies a centered crop for the camera's image output.
/// A `zoomFactor` of 2.0 means the resulting camera frames will be zoomed in twice as much as their normal size.
/// Analogous to setting the `AVCaptureDevice` property of the same name.
/// Can be called rapidly, for example, via a slider or pinch-to-zoom.
/// @param zoomFactor The zoom factor to apply to this camera object.
- (void)setVideoZoomFactor:(CGFloat)zoomFactor;

@end

/// A delegate that provides updates about the attached camera on the main queue.
IVS_EXPORT
@protocol IVSCameraDelegate <NSObject>

@optional

/// Invoked when the underlying input source providing video samples to the camera changes, for example, when the video
/// source is changed from the front-facing camera to the back-facing camera or when the camera is attached to an IVSBroadcastSession
/// or IVSStage that is configured for a certain FPS and resolution, causing the camera to reconfigure its input source to be more performant.
/// @param camera The camera that had it's underlying input source changed.
/// @param inputSource The new input source. If this is `nil` it means there is no available input source to record from.
/// The camera's video zoom factor will reset to 1.0 when the input source for the camera changes.
- (void)underlyingInputSourceChangedFor:(id<IVSCamera>)camera
                                     to:(IVSDeviceDescriptor *)inputSource
                                  with:(IVSCameraFormat *)format;

/// Invoked after the `-[IVSCamera setVideoZoomFactor:]` API successfully changes the AVCaptureDevice's zoom factor.
/// @param camera The camera that had it's zoom factor changed.
/// @param zoomFactor The new zoom factor on the IVSCamera object.
/// This method will not be called when the input source for the camera changes -- as mentioned above, the zoom factor will be reset
/// to 1.0 in that case.
- (void)videoZoomFactorChangedFor:(id<IVSCamera>)camera
                                     to:(CGFloat)videoZoomFactor;


@end

NS_ASSUME_NONNULL_END
