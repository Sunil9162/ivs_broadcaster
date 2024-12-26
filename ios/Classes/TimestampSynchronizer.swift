//
//  TimestampSynchronizer.swift
//  Pods
//
//  Created by Gitesh Dang iOS on 04/10/24.
//


import AVFoundation
import CoreMedia

class TimestampSynchronizer {
    private var videoBufferQueue: [CMSampleBuffer] = []
    private var audioBufferQueue: [CMSampleBuffer] = []
    private let lock = DispatchQueue(label: "com.synchronizer.lock")
    private let syncThreshold: Double = 0.05 // Increased threshold to allow minor mismatches
    private let maxQueueSize = 10

    func addVideoBuffer(_ videoBuffer: CMSampleBuffer) -> (video: CMSampleBuffer, audio: CMSampleBuffer)? {
        lock.sync {
            videoBufferQueue.append(videoBuffer)
            if videoBufferQueue.count > maxQueueSize {
                videoBufferQueue.removeFirst() // Prevent excessive accumulation
            }
            return tryToPairBuffers()
        }
    }

    func addAudioBuffer(_ audioBuffer: CMSampleBuffer) -> (video: CMSampleBuffer, audio: CMSampleBuffer)? {
        lock.sync {
            if !CMSampleBufferIsValid(audioBuffer) {
                print("Invalid audio buffer detected, dropping")
                return nil
            }
            audioBufferQueue.append(audioBuffer)
            if audioBufferQueue.count > maxQueueSize {
                audioBufferQueue.removeFirst() // Prevent excessive accumulation
            }
            return tryToPairBuffers()
        }
    }

    private func tryToPairBuffers() -> (video: CMSampleBuffer, audio: CMSampleBuffer)? {
        guard let videoBuffer = videoBufferQueue.first,
              let audioBuffer = audioBufferQueue.first else { return nil }

        let videoPTS = CMSampleBufferGetPresentationTimeStamp(videoBuffer)
        let audioPTS = CMSampleBufferGetPresentationTimeStamp(audioBuffer)
        return (video: videoBuffer, audio: audioBuffer)
        let timeDifference = CMTimeSubtract(videoPTS, audioPTS).seconds

        // Debugging logs for analysis
        print("Video PTS: \(videoPTS.seconds), Audio PTS: \(audioPTS.seconds), Difference: \(timeDifference)")

        // Synchronization threshold
        let syncThreshold = 0.05 // 50 milliseconds

        if abs(timeDifference) < syncThreshold {
            videoBufferQueue.removeFirst()
            audioBufferQueue.removeFirst()
            return (video: videoBuffer, audio: audioBuffer)
        }

        // Handle large discrepancies (e.g., >1 second)
        if timeDifference > 1 {
            print("Audio significantly ahead. Dropping audio buffer.")
            audioBufferQueue.removeFirst()
        } else if timeDifference < -1 {
            print("Video significantly ahead. Dropping video buffer.")
            videoBufferQueue.removeFirst()
        } else {
            // Normal mismatch: Drop the earlier frame
            if timeDifference < 0 {
                videoBufferQueue.removeFirst()
            } else {
                audioBufferQueue.removeFirst()
            }
        }

        return nil
    }

}


