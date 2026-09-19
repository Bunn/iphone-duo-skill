// Extracted complete Swift snippets from the final guide.

import SwiftUI

@available(iOS 27.1, *)
struct DuoToolbarExample: View {
    var body: some View {
        NavigationStack {
            Text("Document")
                .toolbarVerticalCompressionBehavior(.prefersToolbarItems)
                .toolbar {
                    ToolbarItem(placement: .topBarPinnedTrailing) {
                        Button("Done", systemImage: "checkmark") { }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Details", systemImage: "info.circle") { }
                    }
                    .axisBehavior(.verticalPreferred)
                    .visibilityPriority(.high)

                    ToolbarOverflowMenu {
                        Button("Export", systemImage: "square.and.arrow.up") { }
                    }
                }
        }
    }
}

import SwiftUI

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

import UIKit

@available(iOS 27.1, *)
@MainActor
func makeTwoPaneController(
    primary: UIViewController,
    secondary: UIViewController
) -> UINavigationController {
    let arrangement = UIArrangementViewController()
    arrangement.setViewController(primary, for: .primary)
    arrangement.setViewController(secondary, for: .secondary)
    arrangement.updateArrangement(.split)
    return UINavigationController(rootViewController: arrangement)
}

import SwiftUI

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
