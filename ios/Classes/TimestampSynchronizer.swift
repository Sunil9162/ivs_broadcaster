//
//  TimestampSynchronizer.swift
//  Pods
//
//  Created by Gitesh Dang iOS on 04/10/24.
//


import AVFoundation
import CoreMedia

class TimestampSynchronizer {
    // Define tolerance for synchronization (in seconds)
    let synchronizationTolerance: Double = 0.01
    
    // Store the last timestamp for video and audio
    var lastVideoTimestamp: CMTime = .zero
    var lastAudioTimestamp: CMTime = .zero
    
    // Flag to indicate if synchronization has been established
    var isSynchronized: Bool = false
    
    func synchronize(videoBuffer: CMSampleBuffer, audioBuffer: CMSampleBuffer) -> (video: CMSampleBuffer?, audio: CMSampleBuffer?) {
        // Get timestamps for video and audio buffers
        let videoTimestamp = CMSampleBufferGetPresentationTimeStamp(videoBuffer)
        let audioTimestamp = CMSampleBufferGetPresentationTimeStamp(audioBuffer)
        
        // Calculate timestamp differences
        let videoDiff = videoTimestamp - lastVideoTimestamp
        let audioDiff = audioTimestamp - lastAudioTimestamp
        
        // Check if synchronization has been established
        if !isSynchronized {
            // If not, set the initial timestamps and return nil
            lastVideoTimestamp = videoTimestamp
            lastAudioTimestamp = audioTimestamp
            isSynchronized = true
            return (nil, nil)
        }
        
        // Check if buffers are within tolerance
        if abs(videoDiff.seconds - audioDiff.seconds) < synchronizationTolerance {
            // If within tolerance, return buffers
            lastVideoTimestamp = videoTimestamp
            lastAudioTimestamp = audioTimestamp
            return (videoBuffer, audioBuffer)
        } else {
            // If not within tolerance, return nil for the lagging buffer
            if videoDiff.seconds > audioDiff.seconds {
                // Video is lagging, return nil for video
                return (nil, audioBuffer)
            } else {
                // Audio is lagging, return nil for audio
                return (videoBuffer, nil)
            }
        }
    }
}
