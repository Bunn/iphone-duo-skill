import SwiftUI
import UIKit

@available(iOS 27.1, *)
struct AdaptiveToolbarExample: View {
    @Environment(\.toolbarVerticalEdge) private var preferredVerticalEdge
    @State private var showDetails = false

    var body: some View {
        NavigationStack {
            Text("Document")
                .toolbarVerticalCompressionBehavior(.prefersToolbarItems)
                .toolbar {
                    ToolbarItem(placement: .topBarPinnedTrailing) {
                        Button("Done", systemImage: "checkmark") { }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Details", systemImage: "info.circle") {
                            showDetails = true
                        }
                    }
                    .axisBehavior(.verticalPreferred)
                    .visibilityPriority(.high)
                    ToolbarOverflowMenu {
                        Button("Export", systemImage: "square.and.arrow.up") { }
                    }
                }
                .sheet(isPresented: $showDetails) {
                    Text("Details").presentationPlacement(.trailing)
                }
        }
    }
}

@available(iOS 27.1, *)
@MainActor
func configureToolbar(_ controller: UIViewController) {
    let done = UIBarButtonItem(
        title: "Done", image: UIImage(systemName: "checkmark"),
        primaryAction: UIAction { _ in })
    controller.navigationItem.pinnedTrailingGroup = UIBarButtonItemGroup(
        barButtonItems: [done], representativeItem: nil)
    let details = UIBarButtonItem(
        title: "Details", image: UIImage(systemName: "info.circle"),
        primaryAction: UIAction { _ in })
    details.axisBehavior = .verticalPreferred
    details.visibilityPriority = .high
    controller.toolbarItems = [details]
    controller.navigationItem.verticalBarCompressionBehavior = .prefersBarItems
    controller.navigationItem.additionalOverflowItems = UIDeferredMenuElement.uncached {
        completion in
        completion([UIAction(title: "Export", image: UIImage(systemName: "square.and.arrow.up")) { _ in }])
    }
    controller.sheetPresentationController?.preferredPlacement = .trailing
    _ = controller.traitCollection.verticalBarEdge
}
