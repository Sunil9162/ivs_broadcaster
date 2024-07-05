//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@class IVSImagePreviewView;

/// Extends `AVPictureInPictureController` with `IVSImagePreviewView` support.
API_AVAILABLE(ios(15))
@interface AVPictureInPictureController (IVSImagePreviewView)

/// Create an instance of `AVPictureInPictureController` with an `IVSImagePreviewView` instance.
/// @param previewView The `IVSImagePreviewView` instance used for playback.
/// @note this is designed for remote Stage participants. Using this on the local camera's preview will not work once
/// in the background. Special camera permissions and a different PiP controller are required for that.
- (nullable instancetype)initWithIVSImagePreviewView:(IVSImagePreviewView *)previewView;

@end

NS_ASSUME_NONNULL_END
