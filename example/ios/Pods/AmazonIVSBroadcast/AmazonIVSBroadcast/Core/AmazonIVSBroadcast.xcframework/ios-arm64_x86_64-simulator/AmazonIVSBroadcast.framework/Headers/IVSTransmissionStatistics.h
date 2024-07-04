//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <AmazonIVSBroadcast/IVSBase.h>

NS_ASSUME_NONNULL_BEGIN

/// BroadcastQuality represents the quality of the stream based on the bitrate minimum and maximum provided
/// on session configuration. `nearMinimum` means the stream is near the lowest possible quality (the configured minimum bitrate),
/// or streaming is not possible at all.
/// `nearMaximum` means the bitrate is near the maximum allowed (the configured maximum bitrate).
///
/// If the video configuration looks like:
///     initial bitrate = 1000 kbps
///     minimum bitrate = 300 kbps
///     maximum bitrate = 5,000 kbps
/// It will be expected that a `nearMinimum` quality is provided to this callback initially, since the initial bitrate is much closer to the minimum
/// allowed bitrate than the maximum. If network conditions are good, the quality should improve over time towards `nearMaximum`.
typedef NS_CLOSED_ENUM(NSInteger, IVSTransmissionStatisticsBroadcastQuality) {
    /// The broadcast is near the maximum quality allowed.
    IVSTransmissionStatisticsBroadcastQualityNearMaximum,
    /// The broadcast is at a high quality relative to the provided bounds.
    IVSTransmissionStatisticsBroadcastQualityHigh,
    /// The broadcast is at a medium quality relative to the provided bounds.
    IVSTransmissionStatisticsBroadcastQualityMedium,
    /// The broadcast is at a low quality relative to the provided bounds.
    IVSTransmissionStatisticsBroadcastQualityLow,
    /// The broadcast is near the minumum quality allowed.
    IVSTransmissionStatisticsBroadcastQualityNearMinimum,
} NS_SWIFT_NAME(IVSTransmissionStatistics.BroadcastQuality);

/// NetworkHealth represents the current health of the network. `bad` means the network is struggling to keep up and the broadcast
/// may be experiencing latency spikes. The SDK may also reduce the quality of the broadcast on low values in order to keep it stable, depending
/// on the minimum allowed bitrate in the broadcast configuration. A value of `excellent` means the network is easily able to keep up with the current demand
/// and the SDK will be trying to increase the broadcast quality over time, depending on the maximum allowed bitrate.
/// Values like `medium` or `low` are not necessarily bad, it just means the network is being saturated, but it is still able to keep up. The broadcast is still likely stable.
typedef NS_CLOSED_ENUM(NSInteger, IVSTransmissionStatisticsNetworkHealth) {
    /// The network is easily able to keep up with the current broadcast.
    IVSTransmissionStatisticsNetworkHealthExcellent,
    /// The network keeping up with the broadcast well but the connection is not perfect.
    IVSTransmissionStatisticsNetworkHealthHigh,
    /// The network is experiencing some congestion but it can still keep up with the corrent quality.
    IVSTransmissionStatisticsNetworkHealthMedium,
    /// The network is struggling to keep up with the current video quality and may reduce quality.
    IVSTransmissionStatisticsNetworkHealthLow,
    /// The network can not keep up with the current video quality and will be reducing the quality if allowed.
    IVSTransmissionStatisticsNetworkHealthBad,
} NS_SWIFT_NAME(IVSTransmissionStatistics.NetworkHealth);

/// IVSTransmissionStatistics contains statistics on the broadcast's current measured bitrate, recommended bitrate by the SDK's adaptive bitrate algorithm,
/// average round trip time, broadcast quality (relative to configured minimum and maximum bitrates), and network health.
///
/// Expect this callback to be triggered on `IVSBroadcastSession.delegate` quite frequently (approximately twice per second) as the measured and recommended bitrates change.
/// Measured versus recommended bitrate behavior can vary significantly between platforms. The documentation on each metric provides instructions on how to interpret these values.
IVS_EXPORT
@interface IVSTransmissionStatistics : NSObject

IVS_INIT_UNAVAILABLE

/// The current measured average sending bitrate.
/// Note that the device's video encoder is often unable to match exactly the SDK's recommended bitrate. There can be some delay between
/// the SDK's recommended bitrate and the video encoder responding to the recommendation.
@property (nonatomic, readonly) double measuredBitrate;

/// The bitrate currently recommended by the SDK.
/// Depending on network conditions, the SDK may recommend a higher or lower bitrate to preserve the stability of the broadcast, within
/// the constraints of the minimum, maximum, and initial bitrates configured by the application in BroadcastConfiguration.
@property (nonatomic, readonly) double recommendedBitrate;

/// The current average round trip time for network packets (not image or audio samples).
@property (nonatomic, readonly) double rtt;

/// The current IVSBroadcastQuality.
@property (nonatomic, readonly) IVSTransmissionStatisticsBroadcastQuality broadcastQuality;

/// The current IVSNetworkHealth.
@property (nonatomic, readonly) IVSTransmissionStatisticsNetworkHealth networkHealth;

@end

NS_ASSUME_NONNULL_END
