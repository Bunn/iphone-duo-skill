// API/strict-concurrency typecheck probe, not a complete camera app.
import AVFoundation
import AVKit
import Observation
import SwiftUI
import UIKit

@available(iOS 27.1, *)
func applyPreviewMirroring(
    connection: AVCaptureConnection,
    deviceID: String,
    map: AVCaptureDeviceDirectionMap
) {
    guard connection.isVideoMirroringSupported else { return }
    let forward = map.forwardFacingDeviceDescriptors.contains { $0.uniqueID == deviceID }
    let backward = map.backwardFacingDeviceDescriptors.contains { $0.uniqueID == deviceID }
    guard forward || backward else { return }
    connection.automaticallyAdjustsVideoMirroring = false
    connection.isVideoMirrored = forward
}

@available(iOS 27.1, *)
@MainActor
final class DuoDirectionProbe {
    private var coordinator: AVCaptureDeviceDirectionCoordinator?
    private let capture = DuoCaptureProbe()

    func attach(to view: UIView) {
        coordinator = AVCaptureDeviceDirectionCoordinator(
            view: view,
            deviceTypes: [
                .builtInOuterUltraWideCamera,
                .builtInInnerUltraWideCamera,
                .builtInDualWideCamera
            ]
        ) { [weak self] directions in
            guard let self,
                  let descriptor = directions.forwardFacingDeviceDescriptors.first
            else { return }
            Task { await self.capture.inspect(descriptor) }
        }
    }
}

@available(iOS 27.1, *)
actor DuoCaptureProbe {
    func inspect(_ descriptor: AVCaptureDeviceDescriptor) {
        guard let device = AVCaptureDevice(uniqueID: descriptor.uniqueID) else { return }
        _ = device.position
    }
}

@Observable
@MainActor
final class DuoScriptModel {
    var speed: Double = 1
    var isPlaying = false
}

@available(iOS 27.1, *)
struct DuoAccessoryProbe: View {
    @State private var model = DuoScriptModel()
    @State private var isEnabled = true
    @State private var isAvailable = false

    var body: some View {
        Text("Capture interface placeholder")
            .toolbar {
                if isAvailable {
                    Toggle("Subject display", isOn: $isEnabled)
                }
            }
            .sceneAccessory {
                CameraCaptureAccessory(isEnabled: $isEnabled) {
                    DuoScriptControls(model: model)
                }
                .onAvailabilityChange { isAvailable = $0 }
            }
    }
}

struct DuoScriptControls: View {
    @Bindable var model: DuoScriptModel

    var body: some View {
        VStack {
            Toggle("Play", isOn: $model.isPlaying)
            Slider(value: $model.speed, in: 0.5...2)
        }
    }
}

@available(iOS 27.1, *)
@MainActor
final class DuoUIKitAccessoryProbe: UIViewController {
    private let model = DuoScriptModel()
    private var registration: UISceneAccessoryRegistration?

    override func viewDidLoad() {
        super.viewDidLoad()
        let configuration = UISceneConfiguration()
        configuration.delegateClass = DuoAccessorySceneDelegate.self
        let accessory = UISceneAccessory.cameraCapture(
            sceneConfiguration: configuration, userInfo: model
        )
        registration = registerSceneAccessory(accessory)
    }

    override func updateProperties() {
        super.updateProperties()
        _ = registration?.isAvailable
    }

    func stopOfferingAccessory() {
        guard let registration else { return }
        unregisterSceneAccessory(registration)
        self.registration = nil
    }
}

@available(iOS 27.1, *)
@MainActor
final class DuoAccessorySceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard session.role == .windowCameraCaptureAccessory,
              let windowScene = scene as? UIWindowScene,
              let model = connectionOptions.sceneAccessoryUserInfo as? DuoScriptModel
        else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: DuoScriptControls(model: model))
        window.makeKeyAndVisible()
        self.window = window
    }
}
