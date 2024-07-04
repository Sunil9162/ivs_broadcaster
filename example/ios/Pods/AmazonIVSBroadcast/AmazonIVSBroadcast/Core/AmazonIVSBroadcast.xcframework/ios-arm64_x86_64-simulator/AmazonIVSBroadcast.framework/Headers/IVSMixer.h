//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <AmazonIVSBroadcast/IVSBase.h>

@protocol IVSDevice;
@class IVSMixerSlotConfiguration;

NS_ASSUME_NONNULL_BEGIN

/// The mixer determines the final on-screen and in-ear state for visual elements and audio.
///
/// An element is represented by an `IVSMixerSlotConfiguration` that has a number of associated parameters to place
/// an image stream spatially and set the gain of an audio stream from a device.
///
/// Each slot can be bound to a single image device (such as a camera) and a single audio device (such as a microphone).
IVS_EXPORT
@interface IVSMixer : NSObject

IVS_INIT_UNAVAILABLE

/// Returns the currently added slots.
/// @note for slots that are performing an animated transition, this will return the state of the slot before the transition.
- (NSArray<IVSMixerSlotConfiguration *> *)slots;

/// Transition a slot to a new state.
///
/// Multiple concurrent transitions are not supported on the same slot. If you initiate a second transition
/// before the first is finished, the transition will start over from the original slot state and transition to the
/// new state as if the first transition had never been made.
///
/// If there are no devices to to the slot being animated, the duration parameter will be ignored and the slot will be updated immediately.
///
/// @param slotName The target slot's name
/// @param nextState The new state for the slot
/// @param duration The amount of time to animate the transition for
/// @param onComplete An optional callback that will be called when the animation has completed
/// @return true if a matching slot was found and updated, false otherwise
- (BOOL)transitionSlotWithName:(NSString *)slotName
                       toState:(IVSMixerSlotConfiguration *)nextState
                      duration:(NSTimeInterval)duration
                    onComplete:(nullable void (^)(void))onComplete;

/// Add a new slot to the mixer configuration
/// @param slot The slot configuration to be added
/// @return Success
- (BOOL)addSlot:(IVSMixerSlotConfiguration *)slot;

/// Remove a slot from the mixer configuration
/// @param slotName The slot to be removed
/// @return Success
- (BOOL)removeSlotWithName:(NSString *)slotName;

/// Bind a device's output to the first mixer slot that isn't already bound for this device's stream type, and matches the device type.
/// @param device The device to bind to the mixer
/// @return The name of the slot the device was bound to. `nil` if no compatible slot was found.
- (nullable NSString *)bindDeviceToFirstCompatibleSlot:(id<IVSDevice>)device;

/// Bind a device's output to a mixer slot (specified in the mixer configuration).
/// A common source of failure for this API is if a slot does not exist matching the provided slotName.
/// Use `slots` to verify the slot exists.
/// @param device The device to bind to the mixer
/// @param slotName The target slot's name
/// @return true if the bind was successful.
- (BOOL)bindDevice:(id<IVSDevice>)device toSlotWithName:(NSString *)slotName;

/// Unbind a device from the mixer.
/// @param device The device to unbind
/// @return true if a binding was found and removed.
- (BOOL)unbindDevice:(id<IVSDevice>)device;

/// Get a device's current binding, if it is bound.
/// @param device The device to query
/// @return A slot name if it is bound, otherwise `nil`.
- (nullable NSString *)bindingForDevice:(id<IVSDevice>)device;

/// Get a slot's current bindings, if any are bound.
/// @param slotName The name of the slot to query
/// @return A list of device URNs bound to the slot. This will be empty if the slot exists but no devices are bound, but `nil` if no matching slot exists.
- (nullable NSArray<NSString *> *)devicesBoundToSlotWithName:(NSString *)slotName;

@end

NS_ASSUME_NONNULL_END
