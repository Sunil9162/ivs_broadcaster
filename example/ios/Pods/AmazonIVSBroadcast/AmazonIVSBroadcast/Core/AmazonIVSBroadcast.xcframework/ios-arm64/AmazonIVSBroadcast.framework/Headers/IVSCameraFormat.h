#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AmazonIVSBroadcast/IVSBase.h>

NS_ASSUME_NONNULL_BEGIN

@class IVSCameraSource;
@class IVSFrameRateRange;

/// A class representing the current configuration for an `IVSCameraSource` object.
IVS_EXPORT
@interface IVSCameraFormat : NSObject

IVS_INIT_UNAVAILABLE

/// The minimum value which can be applied to the camera via the `-[IVSCameraSource setVideoZoomFactor:]` API.
@property (nonatomic, readonly) CGFloat minAvailableVideoZoomFactor;

/// The maximum value which can be applied to the camera via the `-[IVSCameraSource setVideoZoomFactor:]` API.
@property (nonatomic, readonly) CGFloat maxAvailableVideoZoomFactor;

/// The frame rate ranges this camera supports.
@property (nonatomic, readonly) NSArray<IVSFrameRateRange *> *frameRateRanges;

/// The video resolution this camera is configured to output.
@property (nonatomic, readonly) CGSize resolution;

@end

NS_ASSUME_NONNULL_END
