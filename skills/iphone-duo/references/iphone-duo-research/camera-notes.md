# iPhone Duo: camera and subject-display implementation notes

> Research snapshot: use the linked official Apple sources and the selected SDK for current verification. Companion Swift probes are bundled; successful typechecks recorded here are historical evidence from 19 September 2026.

Research date: 2026-09-19. Sources are Apple documentation retrieved from each page’s `.md` endpoint plus the installed Xcode 27.1 SDK. These are implementation notes for integration into the broader guide, not a claim of camera testing on physical hardware.

## Verified SDK and availability

The toolchain used for the original research reported **Xcode 27.1, build 27A9269**, and contained `iPhoneSimulator27.1.sdk`. A standalone [CameraAPIProbe.swift](CameraAPIProbe.swift) passed Swift 6 strict-concurrency typechecking with an `arm64-apple-ios27.1-simulator` target. It covers direction-coordinator creation, transferring a descriptor to a capture actor, SwiftUI accessory enablement/availability with an observable shared model, and UIKit registration plus scene connection.

This verifies declarations and compile-time isolation in that SDK. The probe does not create a capture session, run an app, display an accessory, or verify physical camera behavior. No existing application or global Xcode selection was modified.

| API | Earliest documented iOS/iPadOS | Practical purpose |
|---|---:|---|
| `AVCaptureDeviceDirectionCoordinator`, `AVCaptureDeviceDirectionMap`, `AVCaptureDeviceDescriptor` in AVKit | 27.1 | Determine camera direction relative to a particular UI view |
| `AVCaptureDevice.DeviceType.builtInInnerUltraWideCamera`, `.builtInOuterUltraWideCamera` | 27.1 | Discover the individual cameras above the inner and outer displays |
| SwiftUI `CameraCaptureAccessory` | 27.1 | Declare optional subject-facing camera content |
| UIKit `UISceneAccessory.cameraCapture(...)`, `.windowCameraCaptureAccessory` | 27.1 | Register and identify the camera accessory scene |
| SwiftUI `sceneAccessory(content:)`, `SceneAccessoryContent.onAvailabilityChange(perform:)` | 27.0 | General scene accessory infrastructure |
| UIKit `UISceneAccessory`, `UISceneAccessoryRegistration`, registration/unregistration, `sceneAccessoryUserInfo` | 27.0 | General accessory lifecycle, state, context |
| `AVCaptureDevice.RotationCoordinator` and `AVCaptureConnection.videoRotationAngle` | 17.0 | Correct preview/capture orientation; still essential on Duo |

Guard Duo-specific APIs with `if #available(iOS 27.1, *)` when retaining older deployment targets. API availability does not imply the hardware or a presentable accessory exists; discover cameras and observe availability. Some SDK declarations expose additional platforms beyond the documentation metadata (for example AVKit’s header annotates Mac Catalyst 27.1); this guide only claims the verified iOS path. Sources: [direction coordinator](https://developer.apple.com/documentation/avkit/avcapturedevicedirectioncoordinator), [inner camera](https://developer.apple.com/documentation/avfoundation/avcapturedevice/devicetype-swift.struct/builtininnerultrawidecamera), [outer camera](https://developer.apple.com/documentation/avfoundation/avcapturedevice/devicetype-swift.struct/builtinouterultrawidecamera), [CameraCaptureAccessory](https://developer.apple.com/documentation/swiftui/cameracaptureaccessory), [sceneAccessory](https://developer.apple.com/documentation/swiftui/view/sceneaccessory(content:)), [UIKit camera factory](https://developer.apple.com/documentation/uikit/uisceneaccessory/cameracapture(sceneconfiguration:userinfo:)).

## Choose the minimum camera adaptation that fits the app

For an app whose camera is incidental, start with its existing front-camera discovery. On Duo, requesting front-position `.builtInWideAngleCamera` or `.builtInUltraWideCamera` returns a **virtual front camera**: the system switches its physical source to follow the display containing the app. Its supported feature set is the intersection of both physical cameras’ capabilities. Do not assume a virtual camera necessarily means multiple rear lenses. Use `isVirtualDevice` and `activePrimaryConstituent`; the latter can initially be nil and changes over time.

A specialist capture app may choose individual inner/outer cameras to expose all of their capabilities. That choice also makes the app responsible for reacting to direction changes. The physical types are discoverable through `AVCaptureDevice.DiscoverySession`; do not assume the generic default-device lookup exposes them. Sources: [camera-direction adoption article](https://developer.apple.com/documentation/avkit/choosing-a-camera-by-the-direction-it-faces), [activePrimaryConstituent](https://developer.apple.com/documentation/avfoundation/avcapturedevice/activeprimaryconstituent), [discovery session](https://developer.apple.com/documentation/avfoundation/avcapturedevice/discoverysession), [physical inner camera](https://developer.apple.com/documentation/avfoundation/avcapturedevice/devicetype-swift.struct/builtininnerultrawidecamera).

## Camera position is hardware identity; direction is relative to a view

The architectural change is that `.front` and `.back` cannot answer “does this camera face the person using this preview?” A rear camera may become a selfie camera; a physical front camera can face away from a particular display. Model product intent as **toward the viewer** or **away from the viewer**, then select a descriptor from the appropriate direction-map array. Avoid scattering fold-state or model-name conditionals through capture code.

Create and retain `AVCaptureDeviceDirectionCoordinator(view:deviceTypes:changeHandler:)` on the main actor. Give it the actual preview view as its reference frame and include every built-in camera type the app can use, including relevant rear cameras. It ignores external, Continuity, and Desk View cameras; the virtual front camera is also excluded, since its switching belongs to the system. Use the physical inner/outer types for explicit direction tracking. Each simultaneous preview on a different display needs its own coordinator.

The first callback supplies initial directions asynchronously; `deviceDirections` is empty beforehand. Either array can subsequently be empty. Do not interpret initial emptiness as permanent lack of camera hardware. Single-display iPhones also work with this abstraction: front and rear cameras keep their usual respective directions. Sources: [direction coordinator](https://developer.apple.com/documentation/avkit/avcapturedevicedirectioncoordinator), [initializer](https://developer.apple.com/documentation/avkit/avcapturedevicedirectioncoordinator/init(view:devicetypes:changehandler:)), [deviceDirections](https://developer.apple.com/documentation/avkit/avcapturedevicedirectioncoordinator/devicedirections), [direction map](https://developer.apple.com/documentation/avkit/avcapturedevicedirectionmap).

`AVCaptureDeviceDescriptor` and direction maps are `Sendable`. Read descriptive metadata on the main actor, then pass the descriptor to the actor/serial execution context owning capture. Resolve `AVCaptureDevice(uniqueID:)` there, handling nil because a descriptor identifies a device without reserving it. A coordinator callback is not a place to configure AVFoundation. Sources: [descriptor](https://developer.apple.com/documentation/avkit/avcapturedevicedescriptor), [direction map](https://developer.apple.com/documentation/avkit/avcapturedevicedirectionmap).

Integration recommendations, inferred from those contracts:

- Preserve the selected camera if it still satisfies the user’s chosen direction; choose a replacement using the app’s explicit lens/capability preference, rather than treating array order as a documented priority.
- Serialize reconfiguration. Rapid device changes can enqueue stale work; retain the latest requested direction/map and confirm the requested device is still appropriate before committing expensive changes.
- Track requested and successfully applied camera separately; a failed switch must not make the UI report a camera that never became active.
- Mask an outgoing preview during switching, and reveal the replacement only after it supplies frames. Keep failure and empty-direction states understandable.
- Prefer switching one video input to building a multi-camera session solely to handle opening/closing. Use `beginConfiguration`/`commitConfiguration` and restore the old input if the replacement cannot be added.

These are production-hardening suggestions, not assertions that the minimal sample implements cancellation, failure UI, or a full session state machine.

## Mirroring and orientation require independent policies

Automatic mirroring follows physical camera position. A direction-aware selfie preview must instead follow the camera’s direction relative to its view. Check `isVideoMirroringSupported` and disable `automaticallyAdjustsVideoMirroring` before assigning `isVideoMirrored`; assignment while unsupported or while automatic handling remains enabled can raise an exception. Reapply after input changes because they produce new connections. Sources: [mirroring support](https://developer.apple.com/documentation/avfoundation/avcaptureconnection/isvideomirroringsupported), [automatic mirroring](https://developer.apple.com/documentation/avfoundation/avcaptureconnection/automaticallyadjustsvideomirroring), [isVideoMirrored](https://developer.apple.com/documentation/avfoundation/avcaptureconnection/isvideomirrored), [camera-direction adoption article](https://developer.apple.com/documentation/avkit/choosing-a-camera-by-the-direction-it-faces).

A robust app-owned preview policy can apply both outcomes on every known direction change. This avoids leaving a previous override active when the same connection later faces the opposite direction. The following is an illustrative integration fragment; the full camera pipeline is intentionally omitted:

```swift
// Run in the appropriate isolation context for this preview connection.
@available(iOS 27.1, *)
func applyPreviewMirroring(
    connection: AVCaptureConnection,
    deviceID: String,
    map: AVCaptureDeviceDirectionMap
) {
    guard connection.isVideoMirroringSupported else { return }
    let forward = map.forwardFacingDeviceDescriptors.contains { $0.uniqueID == deviceID }
    let backward = map.backwardFacingDeviceDescriptors.contains { $0.uniqueID == deviceID }
    guard forward || backward else { return } // Direction is not known yet.
    connection.automaticallyAdjustsVideoMirroring = false
    connection.isVideoMirrored = forward
}
```

Preview mirroring and saved-media mirroring are different product choices. Check text, barcodes, and subject-facing controls; do not accidentally mirror labels or save reversed content just because the preview acts as a mirror. This is a UI/UX recommendation based on separate connection/output behavior, not a Duo-specific mandatory rule.

Use `AVCaptureDevice.RotationCoordinator` for preview and capture angles, even if the app never explicitly switches cameras. Display migration can change the required angle. A coordinator binds to one device and preview layer: recreate it on camera changes, and when the real preview layer becomes available if it was originally nil. Read initial angles as well as observing changes; a preview-only angle should not be substituted for the output angle. Attach the preview layer to its window before relying on its placement. Cancel observations for the outgoing device and reapply the latest capture angle after adding a new output. Sources: [RotationCoordinator](https://developer.apple.com/documentation/avfoundation/avcapturedevice/rotationcoordinator), [rotation sample](https://developer.apple.com/documentation/avfoundation/supporting-device-rotation-in-your-camera-app).

Validate `isVideoRotationAngleSupported(_:)` before assignment. The inspected 27.1 documentation and header list quarter-turn angles. Preview layers transform their presentation; photo output uses Exif and movie output uses track metadata. Video/depth data outputs physically rotate buffers and can incur per-frame cost and capture-pipeline reconfiguration. Avoid double rotation when your renderer already transforms buffers; Apple recommends connection angle zero for app-managed rotation and ProRes RAW, and a writer-input transform for `AVAssetWriter` workflows. Sources: [videoRotationAngle](https://developer.apple.com/documentation/avfoundation/avcaptureconnection/videorotationangle), local `AVFoundation.framework/Headers/AVCaptureSession.h` (SDK 27.1).

## Outer-display camera accessories: useful but optional

The subject display is appropriate for a script, countdown, framing feedback, or a small capture-related interaction. The app registers content; the system decides presentation location/timing. It can appear with the device open, the main capture interface on the inner display, the app foregrounded, and a running capture session. It may disappear when any of those conditions changes. All essential camera actions must remain available in the main capture interface. Source: [camera accessory adoption article](https://developer.apple.com/documentation/avfoundation/registering-a-camera-capture-accessory-on-iphone-duo).

**SwiftUI:** attach `.sceneAccessory { CameraCaptureAccessory(...) { ... } }` to the capture view, rather than globally to unrelated app screens. Share an existing observable model with the accessory. For controls requiring bindings to observable properties, use `@Bindable var model: Model` in the accessory view; the compiled probe demonstrates this detail. Persist recording/script state outside the ephemeral accessory view.

**UIKit:** create a `UISceneConfiguration` with its delegate class, create `.cameraCapture(sceneConfiguration:userInfo:)`, then call `registerSceneAccessory(_:)` on the capture view controller and retain the returned registration. The delegate receives context via `connectionOptions.sceneAccessoryUserInfo`; retain the shared model yourself. The system assigns `.windowCameraCaptureAccessory`; do not manufacture this role or add a scene-manifest entry for it. Source APIs: [SwiftUI CameraCaptureAccessory](https://developer.apple.com/documentation/swiftui/cameracaptureaccessory), [UIKit factory](https://developer.apple.com/documentation/uikit/uisceneaccessory/cameracapture(sceneconfiguration:userinfo:)), [registration](https://developer.apple.com/documentation/uikit/uiviewcontroller/registersceneaccessory(_:)), [context](https://developer.apple.com/documentation/uikit/uiscene/connectionoptions/sceneaccessoryuserinfo), [scene role](https://developer.apple.com/documentation/uikit/uiscenesession/role-swift.struct/windowcameracaptureaccessory).

Keep three states distinct:

| State | Owner / observation | Meaning |
|---|---|---|
| Available | System; `.onAvailabilityChange` or registration `.isAvailable` | The system can present the accessory |
| Enabled | App/user; `isEnabled` binding or registration property | The user wants the content shown when possible |
| Presented / active | Content lifecycle; `onAppear`, `onDisappear`, `scenePhase`, UIKit scene delegate | The accessory’s content currently exists/is active |

Hide controls for an unavailable subject display. Enablement defaults on, but expose a way to turn it off; an off toggle is not evidence that availability became false. In UIKit, reading `isAvailable` from `updateProperties()` participates in observation. Unregister when the feature ceases to be offered; use `isEnabled` for temporary user disablement. Sources: [sceneAccessory lifecycle](https://developer.apple.com/documentation/swiftui/view/sceneaccessory(content:)), [availability callback](https://developer.apple.com/documentation/swiftui/sceneaccessorycontent/onavailabilitychange(perform:)), [isAvailable](https://developer.apple.com/documentation/uikit/uisceneaccessoryregistration/isavailable), [isEnabled](https://developer.apple.com/documentation/uikit/uisceneaccessoryregistration/isenabled), [unregister](https://developer.apple.com/documentation/uikit/uiviewcontroller/unregistersceneaccessory(_:)).

The topmost registration of the same kind wins; navigation into another capture view can temporarily displace the previous accessory. Different accessory kinds do not compete, so camera subject content and an external presentation can coexist. Do not infer “only one accessory exists globally.” Source: [camera accessory adoption article](https://developer.apple.com/documentation/avfoundation/registering-a-camera-capture-accessory-on-iphone-duo).

## Permission, testing, and gaps

Keep normal capture authorization: provide `NSCameraUsageDescription`, request video access at a relevant interaction, and handle denied/restricted status before session setup. Add microphone usage description and audio permission if recording audio. Saving into Photos has its own permission requirements. Source: [capture and media authorization](https://developer.apple.com/documentation/avfoundation/requesting-authorization-to-capture-and-save-media).

**Unresolved accessory-entitlement requirement:** [Group Lab 285 at 4:12–4:33](https://developer.apple.com/videos/play/meet-with-apple/285/?time=252) says a camera companion display needs an entitlement plus an active capture session, but does not identify the entitlement. The current accessory adoption article, camera accessory symbol pages, public iOS 27.1 UIKit/AVKit headers, the [public entitlements index](https://developer.apple.com/documentation/bundleresources/entitlements), the installed iPhoneOS SDK `Entitlements.plist`, and Xcode's cached portal-capabilities catalog did not yield a corresponding public entitlement key. This is a source discrepancy, not proof that no entitlement is necessary. Confirm current Apple provisioning guidance before shipping this feature; do not guess a key or substitute the unrelated multitasking-camera entitlement. The documented rule that accessory scenes have no scene-manifest entry is separate from code-signing entitlement requirements. Compile-time validation cannot resolve a provisioning/runtime requirement.

Simulator and previews are useful for accessory layout and shared-model tests, but Apple explicitly requires a physical device to test camera-dependent accessory behavior.

[Group Lab 286 at 44:40–45:21](https://developer.apple.com/videos/play/meet-with-apple/286/?time=2680) further clarifies that Simulator can exercise hinge/pose transitions but cannot simulate both displays lit for camera capture. In 27.1 a camera-using app can launch with no cameras discovered, allowing its surrounding UI to be tested; that is not an actual camera feed or accessory presentation test.

The following are a recommended integration test matrix, not completed tests:

- Open and close during live preview, a countdown, photo capture, and recording; verify app/session state and understandable transitions.
- For each supported camera, test forward/backward direction relative to each visible preview, mirroring, upright saved media, and preview/capture angle differences.
- Test rapid changes, no eligible descriptors, failed device resolution/input replacement, interruptions, and permission denial.
- Test accessory disappearance on navigation, backgrounding, capture stop, closing, and user disablement; confirm the main interface still completes every core task.
- Test state persistence after accessory recreation and synchronization of controls between main and subject views.
- Check readable scripts, Dynamic Type, contrast, accessible controls, and touch targets; ensure mirroring is limited to camera imagery.
- Test on a normal iPhone and earlier supported iOS to validate capability and availability fallbacks.

Do not treat typechecking as validation of frame-switch timing, camera lens specifications, thermal behavior, multicamera support, recording continuity, or accessory presentation. Those require the corresponding runtime/device tests. No source inspected here establishes that folding automatically restarts an interrupted recording, reserves a camera, or permits arbitrary second-screen app UI.
