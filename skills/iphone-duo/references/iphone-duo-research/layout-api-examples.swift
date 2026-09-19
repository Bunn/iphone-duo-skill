import SwiftUI
import UIKit

@available(iOS 27.1, *)
struct TwoPaneScreen<Primary: View, Secondary: View>: View {
    let primary: Primary
    let secondary: Secondary

    var body: some View {
        NavigationStack {
            ArrangementView {
                primary
            } secondary: {
                secondary
            }
            .arrangementViewStyle(.split)
        }
    }
}

@available(iOS 27.1, *)
struct ArrangementConfigurationExample: View {
    var body: some View {
        ArrangementView {
            Text("Controls")
                .splitArrangementLayoutRatio(0.4)
                .splitArrangementLayoutRatio(
                    minHorizontal: 0.2,
                    idealHorizontal: 0.4,
                    maxHorizontal: 0.6,
                    idealVertical: 0.5)
                .splitArrangementLayoutSize(
                    minWidth: 240, idealWidth: 320, maxWidth: 400)
                .splitArrangementFixedLayoutSize(horizontal: true, vertical: false)
                .layoutPriority(1)
                .overlayArrangementEdge(.trailing)
                .overlayArrangementEdge(.bottom)
        } secondary: {
            Text("Content")
        }
        .arrangementViewStyle(.split.axes([.horizontal, .vertical]))
    }
}

@available(iOS 27.1, *)
struct ArrangementEnvironmentExample: View {
    @Environment(\.splitArrangementAxis) private var axis
    @Environment(\.overlayArrangementZIndex) private var zIndex

    var body: some View {
        Text(verbatim: "Horizontal: \(axis == .horizontal), z: \(zIndex)")
    }
}

@available(iOS 27.1, *)
struct ReservedRegionsExample: View {
    var body: some View {
        GeometryReader { proxy in
            let activeDivisions = proxy.reservedRegions(
                kind: .division,
                options: .includeInactive
            ).filter(\.isActive)
            let physicalOcclusions = proxy.reservedRegions(
                kind: .occlusion,
                options: .includeInactive,
                layoutDirectionBehavior: .fixed
            )
            Text("Divisions: \(activeDivisions.count), occlusions: \(physicalOcclusions.count)")
        }
    }
}

@available(iOS 27.1, *)
@MainActor
func makeTwoPaneController(
    primary: UIViewController,
    secondary: UIViewController
) -> UINavigationController {
    let container = UIArrangementViewController()
    container.setViewController(primary, for: .primary)
    container.setViewController(secondary, for: .secondary)
    container.updateArrangement(.split)
    return UINavigationController(rootViewController: container)
}

@available(iOS 27.1, *)
@MainActor
func configureArrangements(container: UIArrangementViewController) {
    var split = UISplitArrangement().axes(.horizontal)
    var properties = split.defaultViewProperties
    properties.width.minimum = .absolute(240)
    properties.width.preferred = .fractional(0.4)
    properties.width.maximum = .fractional(0.6)
    properties.height.preferred = .intrinsic
    properties.height.maximum = .automatic
    properties.layoutPriority = 1
    split.setViewProperties(properties, for: .primary)
    container.updateArrangement(split, animated: true)

    var overlay = UIOverlayArrangement()
    var overlayProperties = overlay.defaultViewProperties
    overlayProperties.edge = .trailing
    overlay.setViewProperties(overlayProperties, for: .primary)
    container.updateArrangement(overlay.axes([.horizontal, .vertical]))

    _ = container.state(for: .primary)?.isHidden
    _ = container.state(for: .primary)?.splitAxis
    _ = container.state(for: .primary)?.zIndex
    let activeOcclusions = container.view.reservedRegions(
        kind: .occlusion,
        options: .includeInactive
    ).filter(\.isActive)
    _ = activeOcclusions.map(\.frame)
}

@available(iOS 27.1, *)
struct HingeReadout: View {
    @State private var currentDegrees: Double?

    var body: some View {
        Text(currentDegrees.map { "Hinge: \($0)°" } ?? "Hinge inactive")
            .onHingeChange { _, context in
                guard let hinge = context.hinge,
                      hinge.status == .partiallyOpen else {
                    currentDegrees = nil
                    return
                }
                currentDegrees = hinge.angle.degrees
            }
    }
}

@available(iOS 27.1, *)
final class HingeReadoutController: UIViewController {
    private var currentRadians: CGFloat?

    override func viewDidLoad() {
        super.viewDidLoad()
        let interaction = UIHingeInteraction { [weak self] _, update in
            guard let self else { return }
            guard let hinge = update.hinge,
                  hinge.status == .partiallyOpen else {
                self.currentRadians = nil
                return
            }
            self.currentRadians = hinge.angle
        }
        view.addInteraction(interaction)
    }
}
