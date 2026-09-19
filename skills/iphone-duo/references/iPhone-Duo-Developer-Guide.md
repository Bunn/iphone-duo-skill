# iPhone Duo: UI/UX and API implementation guide

**Research date:** 19 September 2026. **Verified toolchain:** Xcode 27.1, build 27A9269; iPhoneSimulator27.1 SDK; iOS 27.1 simulator runtime 24A94401.

This is reusable implementation context for adding iPhone Duo support to existing SwiftUI and UIKit apps. It combines Apple's documentation, Human Interface Guidelines, video transcripts/captions, and checks against the installed SDK. It is an original synthesis, not a transcript collection. Apple behavior is linked to its source; recommendations for structuring app code and tests are identified as engineering guidance. Beta-specific findings must be revisited before shipping.

Start with sections 1–4 for the design model, then use the API sections that match the app. The migration checklist and test matrix are intended to be reused in implementation tasks.

**Skill bundle:** Portable copy of the guide researched on 19 September 2026. Original synthesis and historical validation are preserved; companion notes and Swift probes are bundled. Follow the linked official Apple sources and reverify relevant APIs and beta claims before implementation.

**Follow-up audit:** A separate review of Xcode 27.1's exported skills on 19 September 2026 added focused configuration, inset, corner-clearance, and compiler-migration guidance. Its evidence is distinguished from the original probes in section 11; [working with Xcode skills](working-with-xcode-skills.md) explains how to use the complementary material.

## Contents

1. [The essential model](#1-the-essential-model)
2. [Build, availability, and compatibility](#2-build-availability-and-compatibility)
3. [Adaptive UI and continuity](#3-adaptive-ui-and-continuity)
4. [Navigation, vertical bars, overflow, and sheets](#4-navigation-vertical-bars-overflow-and-sheets)
5. [Reserved regions](#5-reserved-regions)
6. [Arrangement containers](#6-arrangement-containers)
7. [Hinge interactions](#7-hinge-interactions)
8. [Multitasking and scene lifecycle](#8-multitasking-and-scene-lifecycle)
9. [Cameras and the outer-display accessory](#9-cameras-and-the-outer-display-accessory)
10. [Migration workflow](#10-migration-workflow)
11. [Validation matrix](#11-validation-matrix)
12. [Beta limitations and documentation discrepancies](#12-beta-limitations-and-documentation-discrepancies)
13. [Distribution and design resources](#13-distribution-and-design-resources)
14. [Research coverage and source catalog](#14-research-coverage-and-source-catalog)
15. [Reusable context for future app work](#15-reusable-context-for-future-app-work)

## 1. The essential model

iPhone Duo has an outer display and a folding inner display. Apps must respond to display transitions, changing available size, system bars at a vertical edge, a curved fold, and changing camera occlusion. Treat these as independent inputs rather than a small set of hardcoded device modes. Apple's starting point is a resizable app using standard containers, local geometry, and size classes. [Preparation overview](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo)

The user should experience one continuous app: preserve its task, navigation hierarchy, selection, and available functionality while its presentation adapts. A tabletop arrangement may put media above and controls below, but opening or folding the phone should not be required to reach a feature. [Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo)

| Situation | Design implication |
| --- | --- |
| Closed, outer display | Wider and shorter than a traditional portrait iPhone; protect vertical space and respect asymmetric insets. |
| Inner display, fully open | Use the additional room meaningfully: content, columns, or contextual controls. A flat fold is not an active division. |
| Inner display, partially folded | Keep essential fixed controls and centered content out of the curved region; consider two coordinated content areas. |
| Inner display, portrait tabletop use | Media or passive content above; frequently touched controls on the stable lower portion, where appropriate. |
| Side-by-side multitasking | Your app has only its assigned scene area; it can occupy either side. |
| Video pinned above the app | Available app height changes, including while the device is folded. |

The normal outer display uses compact width and the full inner display offers regular width; **query the actual traits**, because multitasking, presentations, and containers alter the space available to a specific view. Design with size classes and content constraints, not physical display dimensions. [Design talk](https://developer.apple.com/videos/play/tech-talks/111466/?time=222), [Modernize your UIKit app](https://developer.apple.com/videos/play/wwdc2026/278/?time=300)

Duo retains the `.phone` user-interface idiom. A wide scene is still a phone scene, so an idiom test cannot select its expanded layout. [Lab 286, idiom](https://developer.apple.com/videos/play/meet-with-apple/286/?time=3176)

### Choose the right signal

| Need | Use | Avoid |
| --- | --- | --- |
| Choose compact versus expanded navigation | Size classes, standard navigation/split/tab containers | Device-name or `.phone`/`.pad` layout branches |
| Fit or position a custom view | Its container bounds, safe area, layout margins | `UIScreen.main.bounds` and static screen sizes |
| Avoid the fold or camera | Local reserved regions and arrangement containers | Hinge-angle thresholds or hardcoded camera rectangles |
| Drive an expressive physical interaction | Hinge context and angle | Making fundamental functionality hinge-only |
| Position custom content near system bars | Preferred vertical-bar edge plus actual geometry/insets | Assuming a non-nil edge means a visible bar |
| Choose the camera facing the user/scene | Direction relative to the displayed view | Treating physical camera position as a permanent direction |

## 2. Build, availability, and compatibility

Build with the Duo-capable Xcode 27.1 SDK to use the new APIs and validate Duo behavior. Build SDK and minimum deployment target are separate choices: an app can keep an older deployment target and guard new functionality with availability checks. Do not raise the minimum merely to obtain layout support unless the product intentionally drops old OS versions.

The overview says apps built with Xcode 26 or earlier don't extend under the status bar and camera on Duo. Rebuilding can therefore reveal assumptions hidden by the old presentation. Rebuilding is a starting point, not proof of a good layout. [Preparation overview](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo), [Prepare your app, compatibility chapter](https://developer.apple.com/videos/play/tech-talks/111461/?time=30)

### Configuration preflight

Inspect the built app's `Info.plist` and relevant generated build settings, including launch-screen configuration, scene lifecycle, supported orientations, and full-screen compatibility keys. TN3208 says uploads built with the iOS 27 SDK or later need at least one launch-screen configuration key: `UILaunchStoryboardName`, `UILaunchStoryboards`, `UILaunchScreen`, or `UILaunchScreens`. This is a documented submission requirement; the research did not attempt an upload. An app with a valid existing launch screen needs no replacement. [TN3208: Launch-screen requirements](https://developer.apple.com/documentation/technotes/tn3208-preparing-your-apps-launch-screen-to-meet-app-store-requirements)

Check scene adoption and the intended resizing behavior separately. Section 8 covers the scene-lifecycle requirement and TN3192's conditions for discrete resizing with `UIRequiresFullScreen`; do not interpret that compatibility key as a promise of fixed bounds.

### API availability map

Versions below refer to iOS/iPadOS API introduction, not a guarantee that every device provides the associated hardware capability. Catalyst requires separate attention in this beta.

| Capability | SwiftUI | UIKit / AVKit / AVFoundation | Introduced |
| --- | --- | --- | --- |
| Fold/camera geometry | `ReservedRegion`, `GeometryProxy.reservedRegions(...)` | `UIView.ReservedRegion`, `UIView.reservedRegions(...)` | 27.1 |
| Adaptive two-part arrangement | `ArrangementView`, split/overlay styles and related layout modifiers | `UIArrangementViewController`, `UISplitArrangement`, `UIOverlayArrangement` | 27.1 |
| Hinge interactions | `onHingeChange`, `DeviceHinge`, `DeviceHingeContext` | `UIHingeInteraction`, `UIHinge`, `UIHingeInteraction.Update` | 27.1 |
| Vertical-bar behavior and preferred edge | `toolbarVerticalBehavior`, `toolbarVerticalEdge` | `preferredVerticalBarBehavior`, `verticalBarEdge` | 27.1 |
| Toolbar axis preference | `axisBehavior` | `UIBarButtonItem.axisBehavior` | 27.1 |
| Which bar compresses first | `toolbarVerticalCompressionBehavior` | `UINavigationItem.verticalBarCompressionBehavior` | 27.1 |
| Item overflow priority | `visibilityPriority` | `UIBarButtonItem.visibilityPriority` | 27.0 |
| Pinned prominent item | `.topBarPinnedTrailing` | `pinnedTrailingGroup` | SwiftUI 27.0; UIKit 16.0 |
| Explicit overflow content | `ToolbarOverflowMenu` | `additionalOverflowItems` | SwiftUI 27.0; UIKit 16.0 |
| Sheet placement | `presentationPlacement` | `UISheetPresentationController.preferredPlacement` | 27.0 |
| Background extension | `backgroundExtensionEffect` | `UIBackgroundExtensionView` | 26.0 |
| Corner-adapted content clearance | — | `layoutGuide(for:)`, `directionalEdgeInsets(for:)` with `.safeArea(cornerAdaptation:)` | 26.0 |
| Camera direction | — | `AVCaptureDeviceDirectionCoordinator`, direction map/descriptors in AVKit | 27.1 |
| Camera capture accessory | `CameraCaptureAccessory` | `UISceneAccessory.cameraCapture(...)` | 27.1 |
| General scene-accessory infrastructure | `sceneAccessory` | Scene-accessory infrastructure | 27.0 |

Availability was checked against the individual symbol pages and local declarations. The guide's toolbar probe also typechecked with an **iOS 26 deployment target and explicit 27.1 guards**, demonstrating that the sample need not force the deployment target to 27.1.

Select the Duo-capable Xcode installation per command without changing the machine's global Xcode selection. Set `DUO_XCODE_DIR` to that installation's `Contents/Developer` directory. The default below uses the currently selected directory; check the reported version and SDK before proceeding:

```sh
DUO_XCODE_DIR="${DUO_XCODE_DIR:-$(xcode-select -p)}"
DEVELOPER_DIR="$DUO_XCODE_DIR" xcodebuild -version
DEVELOPER_DIR="$DUO_XCODE_DIR" xcrun --sdk iphonesimulator --show-sdk-path
DEVELOPER_DIR="$DUO_XCODE_DIR" xcrun simctl list runtimes
DEVELOPER_DIR="$DUO_XCODE_DIR" xcrun simctl list devices available
```

## 3. Adaptive UI and continuity

### Geometry and safe areas

Use local geometry for local layout. A detail column, sheet, or app in multitasking does not occupy the full display. In UIKit, use view bounds; use `UIWindowScene.effectiveGeometry` for scene-level decisions and its delegate callback for geometry changes. Prefer `traitCollection.displayScale` over a global screen for scale. [Effective geometry](https://developer.apple.com/documentation/uikit/uiwindowscene/effectivegeometry), [Geometry updates](https://developer.apple.com/documentation/uikit/uiwindowscenedelegate/windowscene(_:didupdateeffectivegeometry:))

Keep important content and actions within applicable safe areas and margins. Backgrounds may extend beneath bars. Asymmetric insets are expected: do not "correct" them by adding an equal inset on the opposite edge. Center text/forms and constrained content within their usable content region. Let edge-to-edge imagery retain its intended visual composition while protecting overlaid controls. [Duo HIG](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo)

For imagery that should visually continue under a sidebar or vertical bar, use `backgroundExtensionEffect()` or `UIBackgroundExtensionView`. These extend background appearance while protecting real content; they are not blanket permission for controls to ignore safe areas. SwiftUI's effect clips its source and creates blurred, mirrored extensions; use it selectively for visual clarity and performance. [SwiftUI effect](https://developer.apple.com/documentation/swiftui/view/backgroundextensioneffect()), [UIKit extension view](https://developer.apple.com/documentation/uikit/uibackgroundextensionview)

For custom surfaces near curved container edges, use `ConcentricRectangle` or `UICornerConfiguration` instead of copying a fixed screen corner radius. Both date to iOS 26 and can calculate corner treatment independently, which is useful for Duo's geometry. In SwiftUI custom containers, supply an appropriate `containerShape` so concentricity can resolve. [ConcentricRectangle](https://developer.apple.com/documentation/swiftui/concentricrectangle), [UICornerConfiguration](https://developer.apple.com/documentation/uikit/uicornerconfiguration-swift.struct)

Rounded surface shapes and content clearance solve different problems. In UIKit, rectangular safe-area insets alone can leave content exposed to curved corners. Where that matters, iOS 26 provides `view.layoutGuide(for: .safeArea(cornerAdaptation: .horizontal))` for constraints and `view.directionalEdgeInsets(for: .safeArea(cornerAdaptation: .horizontal))` for manual layout. Use the region on the view whose content needs clearance, and preserve the returned leading/trailing semantics. Guard these APIs when supporting older OS versions. [Corner-adapted safe area](https://developer.apple.com/documentation/uikit/uiview/layoutregion/safearea(corneradaptation:)), [Layout guide](https://developer.apple.com/documentation/uikit/uiview/layoutguide(for:)), [Directional insets](https://developer.apple.com/documentation/uikit/uiview/directionaledgeinsets(for:))

### Reactive UIKit insets

Insets can change while bounds stay the same, for example when system bars change. Read them from the view being laid out: a sheet, split column, and its window can each have different insets. Prefer constraints to the appropriate layout guide. For manual layout, read current values during layout rather than preserving a one-time setup value. Use `safeAreaInsetsDidChange()` or `viewSafeAreaInsetsDidChange()` to invalidate dependent layout, then let the next pass use current geometry. Invalidate constraints with `setNeedsUpdateConstraints()` when that is where the dependency lives; do not assume constrained child frames have already updated inside the notification callback. [View callback](https://developer.apple.com/documentation/uikit/uiview/safeareainsetsdidchange()), [Controller callback](https://developer.apple.com/documentation/uikit/uiviewcontroller/viewsafeareainsetsdidchange())

Set `additionalSafeAreaInsets` only to the extra space needed by app-owned chrome. Adding the existing safe area into that value counts it twice. Likewise, when a scroll view's inset-adjustment policy includes the safe area in `adjustedContentInset`, do not add it again. Preserve deliberate edge-to-edge layouts and review the adjustment policy before changing it. [Additional insets](https://developer.apple.com/documentation/uikit/uiviewcontroller/additionalsafeareainsets), [Adjusted scroll insets](https://developer.apple.com/documentation/uikit/uiscrollview/adjustedcontentinset)

For keyboard avoidance expressed through constraints, prefer the local view's `keyboardLayoutGuide` over storing keyboard notification frames in screen coordinates. Keep notifications when needed for separate behavior, such as revealing an edited field. [Keyboard layout guide](https://developer.apple.com/documentation/uikit/uiview/keyboardlayoutguide)

### Continuity and responsiveness — engineering guidance

- Keep document identity, navigation path, selection, scroll/reading anchor, drafts, media position, and editing state in stable models. Reflow views without replacing the whole feature model.
- When width changes, restore a meaningful content anchor rather than blindly restoring an old pixel offset. This matters for text reflow, paginated readers, grids, and zoomable canvases.
- Recalculate bounds-dependent caches, preview layers, rendering surfaces, and hit targets when their container changes. Avoid assuming changes occur only at launch or rotation.
- Keep resize-time layout work cheap. Defer expensive asset regeneration where possible; UIKit exposes interactive-resizing state through scene geometry for appropriate cases. Do not stop essential rendering or interaction during resize.
- Preserve ongoing gestures sensibly. Clamp pan/zoom to new bounds without jumping to unrelated content; test transitions while a drag, pinch, edit, or recording is active.

These are implementation consequences of Apple's continuity/adaptivity guidance, not guarantees the frameworks will preserve arbitrary custom state for you. [Flexible UIKit apps](https://developer.apple.com/videos/play/wwdc2025/282/)

### Trait updates in UIKit

Read relevant traits in supported automatically tracked methods. Use `updateProperties()` for content/styling changes that may invalidate layout; use layout methods for actual layout. Use targeted `registerForTraitChanges` when the work belongs outside tracked methods, including invalidating external caches. Do not assume every property read in any callback is automatically tracked. Repeatedly invalidating layout from layout callbacks can create excessive work. [Automatic trait tracking](https://developer.apple.com/documentation/uikit/automatic-trait-tracking), [Responding to trait changes](https://developer.apple.com/documentation/uikit/adapting-your-app-when-traits-change)

## 4. Navigation, vertical bars, overflow, and sheets

### Let navigation containers own the bars

In SwiftUI, attach toolbar content to `NavigationStack` or `NavigationSplitView` and use `TabView` as appropriate. In UIKit, use `UINavigationController`/`UITabBarController` and set the view controller's items. Standalone custom instances of `UIToolbar`, `UINavigationBar`, or `UITabBar` do not acquire the container-managed vertical behavior merely by existing. [Raise the bar, adoption](https://developer.apple.com/videos/play/tech-talks/111462/?time=120)

Information-dense apps can optionally prefer a sidebar when enough space is available. In SwiftUI, combine `.tabViewStyle(.sidebarAdaptable)` with `.defaultTabBarPlacement(.sidebar)`; UIKit offers `tabBarController.sidebar.preferredPlacement = .sidebar`. These are 27.0 supporting APIs. iPhone does not provide the same user-controlled tab/sidebar morphing as iPad; preserve access to nested destinations when a sidebar is unavailable. [SwiftUI placement](https://developer.apple.com/documentation/swiftui/view/defaulttabbarplacement(_:)), [UIKit placement](https://developer.apple.com/documentation/uikit/uitabbarcontroller/sidebar-swift.class/preferredplacement)

Vertical bars consolidate navigation, toolbar, and tab items in a region also shared with changing system UI. They commonly appear on the outer display and landscape inner display; inner portrait commonly uses horizontal bars. Let the system resolve the actual context. In a multi-column navigation split view, the detail participates in vertical bars while sidebar/content columns keep horizontal bars; expanded inspectors do not get another vertical bar. [Shared bar region](https://developer.apple.com/videos/play/tech-talks/111462/?time=189)

The hardware-facing bar edge stays physically consistent in right-to-left languages. In system side-by-side multitasking, the app at the left can receive a left-side bar. This is different from semantic leading/trailing ordering inside your content. Query the system instead of encoding "Duo bars are always on the right." [Design talk](https://developer.apple.com/videos/play/tech-talks/111466/), [Bar ordering](https://developer.apple.com/videos/play/tech-talks/111462/?time=269)

### Item design and ordering

Provide both an icon and a meaningful title, usually with a SwiftUI `Label` or `Button(_:systemImage:action:)`. The system can use an icon in a narrow vertical bar and both pieces of information in overflow. A text-only toolbar item stays horizontal by default; tab items have different adaptation rules, though icons plus titles remain recommended. Complex/custom toolbar views also stay horizontal unless explicitly adapted and opted in. Use meaningful accessibility labels even when only a symbol is visible.

Use semantic placement: Back/Close first, then prominent completion actions, then related action groups; tabs remain navigation destinations. Use `.cancellationAction` for a custom Close/Back action; use `.topBarPinnedTrailing` for prominent completion. UIKit equivalents include `leadingItemGroups` and `pinnedTrailingGroup`. The automatic navigation Back button should not be duplicated. [Preparation overview](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo)

| Concern | SwiftUI | UIKit | Practical meaning |
| --- | --- | --- | --- |
| Keep a symbol/text-changing item horizontal | `.axisBehavior(.horizontalOnly)` | `item.axisBehavior = .horizontalOnly` | Avoid controls jumping between axes when their state changes. |
| Permit an adapted custom item vertically | `.axisBehavior(.verticalPreferred)` | `item.axisBehavior = .verticalPreferred` | First make the custom representation fit the constrained width. |
| Preserve an important action longer | `.visibilityPriority(.high)` | `item.visibilityPriority = .high` | Lower-priority items overflow first; this is not an absolute visibility guarantee. |
| Always include an action in overflow | `ToolbarOverflowMenu` | `additionalOverflowItems` | Merge ad-hoc overflow into the system menu where appropriate. |
| Favor task controls over tabs | `.toolbarVerticalCompressionBehavior(.prefersToolbarItems)` | `navigationItem.verticalBarCompressionBehavior = .prefersBarItems` | Tabs compress before action items. |
| Favor primary navigation | `.toolbarVerticalCompressionBehavior(.prefersTabBar)` | `... = .prefersTabBar` | Preserve tab access longer; navigation-focused default described by the talk. |

Sources: [Axis behavior](https://developer.apple.com/documentation/swiftui/toolbarcontent/axisbehavior(_:)), [Visibility priority](https://developer.apple.com/documentation/swiftui/toolbarcontent/visibilitypriority(_:)), [Overflow](https://developer.apple.com/documentation/swiftui/toolbaroverflowmenu), [Compression behavior](https://developer.apple.com/documentation/swiftui/view/toolbarverticalcompressionbehavior(_:)), [UIKit compression](https://developer.apple.com/documentation/uikit/uinavigationitem/verticalbarcompressionbehavior).

`topBarPinnedTrailing` can still overflow when search is active and space is insufficient. UIKit's `pinnedTrailingGroup` documentation instead says the group cannot overflow and recommends a representative item when it contains multiple items. Do not assume the two descriptions promise identical edge-case behavior. [SwiftUI pinned placement](https://developer.apple.com/documentation/swiftui/toolbaritemplacement/topbarpinnedtrailing), [UIKit pinned group](https://developer.apple.com/documentation/uikit/uinavigationitem/pinnedtrailinggroup)

For custom items, supply an appropriate overflow representation (`UIBarButtonItem.menuRepresentation` in UIKit). Keep substantive text, such as a price, when the symbol cannot communicate it; use a badge for a simple count where suitable. Keyboard accessory controls stay attached to the keyboard. Avoid adding artificial spacer items to recreate old bar spacing. Verify custom content with Reduce Transparency enabled. [Custom content and overflow](https://developer.apple.com/videos/play/tech-talks/111462/?time=540), [Menu representation](https://developer.apple.com/documentation/uikit/uibarbuttonitem/menurepresentation)

### Preferred edge is not visibility

`@Environment(\.toolbarVerticalEdge)` returns `HorizontalEdge?`; UIKit's `traitCollection.verticalBarEdge` uses `UIVerticalBarEdge`. They describe the preferred edge **even when a bar isn't currently visible**. `nil`/unspecified means the context does not support a vertical placement. Use actual safe-area/container geometry to avoid visible UI; do not turn the preferred edge into a Boolean bar-presence detector. [SwiftUI edge](https://developer.apple.com/documentation/swiftui/environmentvalues/toolbarverticaledge), [UIKit edge](https://developer.apple.com/documentation/uikit/uitraitcollection/verticalbaredge)

### Sheets, inspectors, and opting out

The outer display normally gives sheets vertical bars. On the inner display, centered/leading sheets use horizontal bars and trailing sheets can use vertical bars. Set `presentationPlacement` or `UISheetPresentationController.preferredPlacement` as a preference; only sheets honor the SwiftUI placement modifier. Inspect sheet content and dismissal controls after every resize. [Sheet placement](https://developer.apple.com/documentation/swiftui/view/presentationplacement(_:)), [Duo overview](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo)

The installed UIKit header additionally states that `preferredPlacement` is ignored when the sheet's `sourceView` is non-nil. Check source anchoring when a placement preference appears ineffective. Source: `UIKit.framework/Headers/UISheetPresentationController.h` in the verified 27.1 SDK.

Disable vertical layout selectively for a composition that benefits from horizontal bars, such as a calculator, fullscreen player, or control-heavy sheet. Use `.toolbarVerticalBehavior(.disabled)` or override `preferredVerticalBarBehavior`. This is a stable design decision: do not toggle it repeatedly with transient view state. To hide bars, use visibility APIs instead. SwiftUI resolves the preference from the top navigation destination, selected tab, or trailing-most split column. [SwiftUI vertical behavior](https://developer.apple.com/documentation/swiftui/view/toolbarverticalbehavior(_:)), [UIKit vertical behavior](https://developer.apple.com/documentation/uikit/uiviewcontroller/preferredverticalbarbehavior)

### Small SwiftUI example

This example's API usage typechecked against the installed iOS 27.1 simulator SDK with an iOS 26 deployment target. Action bodies are placeholders. Invoke this view only inside a matching availability branch in an older-deployment app.

```swift
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
```

## 5. Reserved regions

Reserved regions describe system-known parts of the display that a custom layout may need to accommodate. Query them in the coordinate system of the actual view being laid out. The return value is a collection, not necessarily a single central rectangle.

| Kind | Meaning | Typical policy |
| --- | --- | --- |
| `.division` | A region that can separate content into independently usable areas, such as an active fold | Displace fixed controls or divide related panes. |
| `.occlusion` | Content can be obscured, such as by a camera | Keep meaningful foreground content and controls clear. |

The outer camera always occludes; the inner camera is hidden when inactive and becomes relevant when active. The fold becomes an active division when partially open. `ReservedRegion` provides `id`, `kind`, `frame`, `margins`, and `isActive`. **Its frame already incorporates protective margins.** Do not add those margins a second time. [SwiftUI regions](https://developer.apple.com/documentation/swiftui/reservedregion), [UIKit regions](https://developer.apple.com/documentation/uikit/uiview/reservedregion)

### Query APIs

```swift
// SwiftUI.GeometryProxy
func reservedRegions(
    kind: ReservedRegion.Kind,
    options: ReservedRegion.QueryOptions = [],
    layoutDirectionBehavior: LayoutDirectionBehavior = .mirrors
) -> [ReservedRegion]

// UIKit.UIView
@MainActor
func reservedRegions(
    kind: UIView.ReservedRegion.Kind,
    options: UIView.ReservedRegion.QueryOptions = []
) -> [UIView.ReservedRegion]
```

Sources: [SwiftUI query](https://developer.apple.com/documentation/swiftui/geometryproxy/reservedregions(kind:options:layoutdirectionbehavior:)), [UIKit query](https://developer.apple.com/documentation/uikit/uiview/reservedregions(kind:options:)).

The adaptive-layout talk describes active-only results by default and `.includeInactive` for obtaining inactive regions too. Current overview prose on some symbol pages contradicts that description. To make the application's active-only policy explicit, request all and filter:

```swift
// Inside GeometryReader { proxy in ... }
let activeDivisions = proxy.reservedRegions(
    kind: .division,
    options: .includeInactive
).filter(\.isActive)

// Inside a UIKit view/controller's current layout pass:
let activeOcclusions = view.reservedRegions(
    kind: .occlusion,
    options: .includeInactive
).filter(\.isActive)
```

Inactive regions can be useful for planning a grid that will divide cleanly before the phone bends; inactive geometry should not automatically reserve a blank gutter. Runtime default filtering was not measured in this research. [Query option](https://developer.apple.com/documentation/swiftui/reservedregion/queryoptions/includeinactive), [Adaptive-layout talk](https://developer.apple.com/videos/play/tech-talks/111463/?time=423)

### What should move?

Keep a continuous article, feed, list, or scrolling document stable through the curved region. Avoid making it jump to another pane merely because a fold activates. Move fixed interactive controls and constrained/centered content where visibility and targeting would otherwise suffer. Move closely related controls as a group; independent controls may move independently. For grids, consider an even number of columns around the division. These are content-specific choices, not a rule to split every screen. [Duo HIG](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo), [Displacement guidance](https://developer.apple.com/videos/play/tech-talks/111463/?time=146)

### Coordinates and right-to-left layouts

SwiftUI defaults to `.mirrors`, which works with the mirroring performed by SwiftUI's layout system. Use `.fixed` only when the consumer intentionally uses fixed physical coordinates and manages semantic mirroring itself. Mixing a mirrored region frame with a nonmirrored positioning layer can avoid the wrong side of the screen. UIKit frames are local to the queried view; convert them explicitly if another view consumes them. [ReservedRegion coordinate guidance](https://developer.apple.com/documentation/swiftui/reservedregion)

For a custom layout engine, these are recommended safeguards:

1. Intersect returned frames with the current local content area; tolerate empty and multiple results.
2. Do not assume a division crosses the middle of this particular container. A detail column may only touch the fold or not intersect it at all.
3. Distinguish the fold's axis from device orientation; a horizontal division and a vertical division require different placement.
4. Keep physical camera avoidance separate from semantic leading/trailing placement and reading direction.
5. Reevaluate after resize, display transition, active-region changes, and camera activation. Do not cache geometry only at launch.
6. Combine reserved-region handling with safe areas; one is not a universal replacement for the other.

These safeguards are engineering guidance based on local-coordinate APIs. No `reservedRegionsDidChange` delegate method was found in the inspected public UIView headers; do not invent one.

## 6. Arrangement containers

`ArrangementView` and `UIArrangementViewController` coordinate **two roles**, primary and secondary. They are layout containers, not navigation systems. Use them when an existing custom layout already has two related areas, such as playback and transcript or content and a control palette. Keep working navigation containers when they already solve the problem. [SwiftUI ArrangementView](https://developer.apple.com/documentation/swiftui/arrangementview), [UIKit arrangement controller](https://developer.apple.com/documentation/uikit/uiarrangementviewcontroller)

| Style | Without an active division | With a division |
| --- | --- | --- |
| Split | Normally side-by-side in a wider container, stacked in a taller one | Adapts the two areas around the reserved division. |
| Overlay | Primary above secondary in z-order | Can separate primary toward trailing/bottom and secondary toward leading/top. |

The default automatic SwiftUI style resolves to split. Both styles permit axis restrictions. **Restricting a split to `.horizontal` can hide the secondary view when vertical splitting would be required.** Preserve a route to important secondary functionality. [Automatic style](https://developer.apple.com/documentation/swiftui/automaticarrangementviewstyle), [Split axes](https://developer.apple.com/documentation/swiftui/splitarrangementviewstyle/axes(_:)), [Preparation overview](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo)

### SwiftUI pattern

```swift
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
```

Keep model ownership outside transient pane rearrangements. Use `.overlay` instead when one view should cover the other until the fold separates them. A scrolling content view can live **within** a pane; placing the **entire arrangement inside** a `ScrollView` or `List` can make content inaccessible.

Apple's overview and video disagree about the direction of their warning concerning `NavigationSplitView` nesting. The conservative integration recommendation is `NavigationStack → ArrangementView → content` and avoiding arrangement/navigation-split nesting in either direction until explicitly validated. This is a precaution derived from two differently worded sources, not a new compiler restriction. [Overview nesting warning](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo), [Video composition guidance](https://developer.apple.com/videos/play/tech-talks/111463/?time=969)

### Sizing and child adaptation

| SwiftUI API | Use and limitation |
| --- | --- |
| `splitArrangementLayoutRatio(_:)` | Preferred share of space. Allocation respects layout priority and remaining room; two values are not unconditional percentages. |
| `splitArrangementLayoutRatio(minHorizontal:idealHorizontal:maxHorizontal:minVertical:idealVertical:maxVertical:)` | Separate ratio preferences for each axis. |
| `splitArrangementLayoutSize(minWidth:idealWidth:maxWidth:minHeight:idealHeight:maxHeight:)` | Content-driven point constraints; width applies to horizontal splitting, height to vertical. |
| `splitArrangementFixedLayoutSize(horizontal:vertical:)` | Prefers ideal content size, but the child can still shrink. |
| `overlayArrangementEdge(_:)` | Customize the separated edge; the local SDK exposes horizontal and vertical edge overloads. |
| `EnvironmentValues.splitArrangementAxis` | Lets a child adapt to the current split axis; optional, including nil outside a split arrangement. |
| `EnvironmentValues.overlayArrangementZIndex` | Describes overlay stacking for expanded/collapsed child presentation; not a general device-pose detector. |

Sources: [Ratio](https://developer.apple.com/documentation/swiftui/view/splitarrangementlayoutratio(_:)), [Ratio constraints](https://developer.apple.com/documentation/swiftui/view/splitarrangementlayoutratio(minhorizontal:idealhorizontal:maxhorizontal:minvertical:idealvertical:maxvertical:)), [Size constraints](https://developer.apple.com/documentation/swiftui/view/splitarrangementlayoutsize(minwidth:idealwidth:maxwidth:minheight:idealheight:maxheight:)), [Fixed size preference](https://developer.apple.com/documentation/swiftui/view/splitarrangementfixedlayoutsize(horizontal:vertical:)), [Overlay edge](https://developer.apple.com/documentation/swiftui/view/overlayarrangementedge(_:)), [Split axis](https://developer.apple.com/documentation/swiftui/environmentvalues/splitarrangementaxis), [Overlay order](https://developer.apple.com/documentation/swiftui/environmentvalues/overlayarrangementzindex).

### UIKit pattern

```swift
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
```

UIKit's split `ViewProperties` offer width/height `DimensionRange` values and `layoutPriority`. Dimensions include `.automatic`, `.intrinsic`, `.absolute(...)`, and `.fractional(...)`. Start from `defaultViewProperties`, change preferences, assign them to a placement, then update the arrangement. `axes(_:)` returns a value, so use its result. `ViewState` provides `isHidden`, `splitAxis`, and `zIndex`; it is a query, not an `arrangementDidChange` callback. [Split arrangement](https://developer.apple.com/documentation/uikit/uisplitarrangement-swift.struct), [View state](https://developer.apple.com/documentation/uikit/uiarrangementviewcontroller/viewstate)

## 7. Hinge interactions

Use hinge input for expressive effects or optional interaction, such as an instrument bend or artwork response. Use reserved regions and arrangements for layout. This separation avoids guessing the system's fold thresholds. [Multiple displays and scenes](https://developer.apple.com/videos/play/tech-talks/111464/?time=49)

| SwiftUI | UIKit |
| --- | --- |
| `.onHingeChange(isEnabled:_:)` provides previous and current `DeviceHingeContext`. | `UIHingeInteraction(updateHandler:)` is attached with `view.addInteraction(...)`; callback arguments are the interaction and update, not old/new contexts. |
| `context.hinge` is optional. | `update.hinge` is optional. |
| `DeviceHinge.angle` is an `Angle`: explicitly request `.degrees` or `.radians`. | `UIHinge.angle` is a `CGFloat` in radians. |
| Status constants: `.closed`, `.partiallyOpen`, `.fullyOpen`. | Enum includes `.unknown` as well as closed/partially open/fully open. |

No guaranteed numeric angle range, zero-angle convention, or update frequency was found in the inspected public contracts. Do not assume `0...180°` or infer fully open from equality to π. Status is system determined. Nil means unavailable in this context; in UIKit it can also result from leaving the relevant view hierarchy. Reset effects on nil or when their intended status ends. [SwiftUI modifier](https://developer.apple.com/documentation/swiftui/view/onhingechange(isenabled:_:)), [DeviceHinge](https://developer.apple.com/documentation/swiftui/devicehinge), [UIKit interaction](https://developer.apple.com/documentation/uikit/uihingeinteraction), [UIKit angle](https://developer.apple.com/documentation/uikit/uihinge/angle)

```swift
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
```

UIKit handlers run initially and on changes, including hierarchy changes. Avoid retain cycles in escaping closures. Disabled interactions discard updates; re-enabling supplies current state when available. Keep high-frequency effects cheap, respect accessibility preferences, and provide a conventional alternative input for essential actions. The last three are implementation recommendations. [Interaction initializer](https://developer.apple.com/documentation/uikit/uihingeinteraction/init(updatehandler:)), [Enablement](https://developer.apple.com/documentation/uikit/uihingeinteraction/isenabled)

## 8. Multitasking and scene lifecycle

### Resizing is foundational

Duo introduces two-app side-by-side use and app resizing beneath pinned video. Supporting system multitasking is distinct from supporting **multiple instances of your own app**. An app may resize beside another app without offering multiple own windows. Inner-display new-window creation is dynamic and is unavailable on the outer display; handle failed activation requests. [Multitasking talk](https://developer.apple.com/videos/play/tech-talks/111464/?time=179)

Use `UIWindowScene.ActivationAction` (Objective-C name `UIWindowSceneActivationAction`) for an appropriate system menu action. It can hide or supply an alternate action when window creation is unavailable. Do not cache a permanent "Duo supports new windows" Boolean. [Activation action](https://developer.apple.com/documentation/uikit/uiwindowscene/activationaction), [Multiple scene support](https://developer.apple.com/documentation/uikit/uiapplication/supportsmultiplescenes)

UIKit apps must adopt scene lifecycle when linking the latest iOS 27 SDK, according to Apple's WWDC26 migration guidance. This does **not** require enabling multiple windows. Put scene-specific navigation, selections, and restoration in scene-owned state; avoid choosing an arbitrary `connectedScenes.first` as the app's window. [Modernize your UIKit app](https://developer.apple.com/videos/play/wwdc2026/278/?time=142), [Scene lifecycle migration](https://developer.apple.com/documentation/uikit/transitioning-to-the-uikit-scene-based-life-cycle), [Multiple windows](https://developer.apple.com/documentation/uikit/supporting-multiple-windows-on-ipad)

### State ownership

Shared app storage remains shared across app instances; scene navigation does not. Coordinate document writes, capture ownership, and shared resources separately from presentation state. SwiftUI switching entire container trees in `if sizeClass` branches can discard local state. Prefer stable adaptive containers or deliberately lift state ownership above the branch. [Lab 285, state](https://developer.apple.com/videos/play/meet-with-apple/285/?time=3430), [Lab 286, SwiftUI identity](https://developer.apple.com/videos/play/meet-with-apple/286/?time=1162)

When closing from Split View, the system chooses which app continues on the outer display. Reopening can restore the pair or expand the current app according to system policy. Do not implement app behavior around undocumented timing heuristics; test restoration and continuity instead. [Lab 286, transitions](https://developer.apple.com/videos/play/meet-with-apple/286/?time=190)

### Orientation and `UIRequiresFullScreen`

Do not use orientation lock or `UIRequiresFullScreen` as a Duo resizing opt-out. The outer and inner displays have different orientation/compatibility behavior. Even games using compatibility handling must survive display transitions and new bounds. WWDC26 describes updated discrete-resizing behavior for games; the older property-list page primarily describes iPad behavior. Keep ordinary apps fully adaptive and treat compatibility modes as separately tested exceptions. [Preparation talk](https://developer.apple.com/videos/play/tech-talks/111461/?time=166), [Current UIKit adaptivity talk](https://developer.apple.com/videos/play/wwdc2026/278/), [Property-list reference](https://developer.apple.com/documentation/bundleresources/information-property-list/uirequiresfullscreen)

TN3192 specifies the current condition more precisely: on iOS/iPadOS 27, apps built with SDK 27 or later and `UIRequiresFullScreen = YES` use discrete resizing unless `UIRequiresFullScreenIgnoredStartingWithVersion` selects version 27 or earlier. During a discrete resize, scene size changes when the drag finishes. This differs from continuous resizing and still requires the app to handle new scene bounds. Review the key and any version-specific fallback deliberately; do not assume the system simply ignores it. [TN3192: Full-screen compatibility migration](https://developer.apple.com/documentation/technotes/tn3192-migrating-your-app-from-the-deprecated-uirequiresfullscreen-key)

### Adjacent benefit: iPhone Mirroring

The same resize work benefits mirrored iPhone apps and iPhone apps on iPad. Also test indirect input: standard pinch/rotation/pan recognizers, appropriate `allowedScrollTypesMask`, and custom sheet dismissal. Review `UIApplicationSupportsIndirectInputEvents` if it explicitly opts out. Biometrics in Mirroring need a supported companion-device policy where appropriate to the app's authentication design. This is related platform work, not a Duo-only requirement. [TN3210: iPhone Mirroring](https://developer.apple.com/documentation/technotes/tn3210-optimizing-your-app-for-iphone-mirroring)

## 9. Cameras and the outer-display accessory

### Choose the simplest camera strategy that meets the feature

For incidental capture, the generic front wide/ultrawide camera on Duo is virtual: the system switches its physical source to follow the display containing the app. Its usable feature set is the intersection of the physical cameras' capabilities. This may be sufficient without explicit fold handling. `activePrimaryConstituent` can change and can initially be nil. [Choosing a camera by direction](https://developer.apple.com/documentation/avkit/choosing-a-camera-by-the-direction-it-faces), [Active constituent](https://developer.apple.com/documentation/avfoundation/avcapturedevice/activeprimaryconstituent)

Specialist camera apps can discover `.builtInInnerUltraWideCamera` and `.builtInOuterUltraWideCamera` to access physical-camera capabilities directly. Use a discovery session and inspect supported formats. The Duo camera talk states limits of 1080p/60 fps for the virtual front and physical inner camera, and up to 4K/120 fps for the physical outer camera; treat these as announced capabilities, never as a substitute for runtime format selection. Physical access is needed for depth use described in that talk. [Duo camera talk](https://developer.apple.com/videos/play/tech-talks/111465/?time=58), [Inner camera type](https://developer.apple.com/documentation/avfoundation/avcapturedevice/devicetype-swift.struct/builtininnerultrawidecamera), [Outer camera type](https://developer.apple.com/documentation/avfoundation/avcapturedevice/devicetype-swift.struct/builtinouterultrawidecamera)

### Direction is relative to a view

Physical `.front`/`.back` position cannot reliably mean "toward the person looking at this preview" on a folding device. Model user intent as toward/away from the viewer and use AVKit's `AVCaptureDeviceDirectionCoordinator` with the actual preview view. Each preview on a different display needs its own reference view/coordinator. [Direction coordinator](https://developer.apple.com/documentation/avkit/avcapturedevicedirectioncoordinator)

The coordinator provides forward/backward arrays of `AVCaptureDeviceDescriptor`. It excludes external/Continuity/Desk View devices and the system-managed virtual front camera. Include the physical types and rear types your app can use. Initial direction delivery is asynchronous; arrays may initially or subsequently be empty. Do not treat empty initial state as a permanent hardware conclusion. [Initializer](https://developer.apple.com/documentation/avkit/avcapturedevicedirectioncoordinator/init(view:devicetypes:changehandler:)), [Direction map](https://developer.apple.com/documentation/avkit/avcapturedevicedirectionmap)

Retain the direction coordinator strongly for the lifetime of its preview so it continues delivering updates.

The coordinator is main-actor UI work. Pass its Sendable descriptors to the actor/serial execution context that owns capture; resolve `AVCaptureDevice(uniqueID:)` there and handle failure. Descriptors identify devices without reserving them. Avoid configuring the capture session in the UI callback. [Device descriptor](https://developer.apple.com/documentation/avkit/avcapturedevicedescriptor)

Production integration recommendations:

- Keep the current camera if it still satisfies the requested direction and capability policy; array order is not a documented camera-ranking contract.
- Serialize reconfiguration, discard stale choices, and track requested versus successfully applied device separately.
- Use a deliberate transition treatment while the preview source changes; wait for usable replacement frames.
- Prefer replacing one video input to creating a multicamera session merely for folding. Handle `canAddInput` failure and restore a valid configuration.
- Test camera interruption and ongoing recording across transitions; switching devices is not a promise of seamless recording.

### Mirroring, rotation, and crop are independent

Automatic mirroring follows physical position. For an app-managed selfie preview, apply mirroring according to direction relative to its view. Check `isVideoMirroringSupported`, set `automaticallyAdjustsVideoMirroring = false`, then set `isVideoMirrored`. Reapply to new connections after switching. Apply both true and false outcomes, otherwise an old override may remain. Decide separately whether saved media should be mirrored. [Automatic mirroring](https://developer.apple.com/documentation/avfoundation/avcaptureconnection/automaticallyadjustsvideomirroring), [Mirroring property](https://developer.apple.com/documentation/avfoundation/avcaptureconnection/isvideomirrored)

Use `AVCaptureDevice.RotationCoordinator` for preview and capture orientation. Recreate it when its device or actual preview layer changes, read initial values, and remove old observations. Preview and capture angles are distinct. Verify supported angles before assigning `videoRotationAngle`. Custom pipelines must avoid rotating buffers twice; data-output rotation can cost processing and reconfiguration, while photo/movie paths also use metadata. [Rotation coordinator](https://developer.apple.com/documentation/avfoundation/avcapturedevice/rotationcoordinator), [Rotation sample](https://developer.apple.com/documentation/avfoundation/supporting-device-rotation-in-your-camera-app), [Connection angle](https://developer.apple.com/documentation/avfoundation/avcaptureconnection/videorotationangle)

Lay out preview imagery independently from controls. Use the appropriate preview gravity and only supported aspect ratios. The related Center Stage talk warns that changing capture aspect ratio changes sample dimensions and stops `AVCaptureMovieFileOutput` recording; custom writers need a deliberate policy such as segmentation. Do not claim every Duo camera supports every Center Stage or smart-framing feature: inspect device/format capabilities. [Center Stage support, recording](https://developer.apple.com/videos/play/wwdc2026/341/?time=713)

### Optional subject-facing content

A camera capture accessory can present a script, countdown, framing help, or small capture-related interaction on the outer display while the camera UI is on the inner display. The system owns presentation and availability. Requirements described in the adoption article include foreground capture, the inner display, and a running capture session; the talk further describes full-screen inner-display use. Keep every essential camera action available without the accessory. [Accessory adoption](https://developer.apple.com/documentation/avfoundation/registering-a-camera-capture-accessory-on-iphone-duo), [Accessory talk](https://developer.apple.com/videos/play/tech-talks/111464/?time=262)

In SwiftUI, attach `.sceneAccessory { CameraCaptureAccessory(...) { ... } }` to the capture view, observe `.onAvailabilityChange`, and share stable model state with the accessory. Use `@Bindable` in a child that needs bindings to an observable model. In UIKit, build a `UISceneConfiguration` and set its `delegateClass`, create `UISceneAccessory.cameraCapture(sceneConfiguration:userInfo:)`, register on the capture view controller, and retain the registration. Read `sceneAccessoryUserInfo` on connection, and retain the shared model independently in the app. The system assigns the `.windowCameraCaptureAccessory` role; don't add a manifest entry to fabricate that accessory role. [SwiftUI accessory](https://developer.apple.com/documentation/swiftui/cameracaptureaccessory), [UIKit factory](https://developer.apple.com/documentation/uikit/uisceneaccessory/cameracapture(sceneconfiguration:userinfo:)), [Scene role](https://developer.apple.com/documentation/uikit/uiscenesession/role-swift.struct/windowcameracaptureaccessory)

| Accessory state | Meaning | Appropriate response |
| --- | --- | --- |
| Available | System conditions permit presentation | Reflect this in the main UI; do not infer it from a device model. |
| Enabled | The app/user wants the accessory shown when possible | Offer an understandable toggle; defaults on. |
| Presented/active | Accessory content actually exists/is active | Observe its lifecycle and avoid tying persistent capture state to ephemeral views. |

Observe `UISceneAccessoryRegistration.isAvailable` and `isEnabled`; `updateProperties()` can participate in observation tracking. Unregister when the app stops offering the feature; disable temporarily for the user's preference. Among registrations of the same kind the topmost wins; different kinds can coexist. [Registration availability](https://developer.apple.com/documentation/uikit/uisceneaccessoryregistration/isavailable), [Enablement](https://developer.apple.com/documentation/uikit/uisceneaccessoryregistration/isenabled), [SwiftUI lifecycle](https://developer.apple.com/documentation/swiftui/view/sceneaccessory(content:))

Normal camera/microphone and media-library permission requirements remain. Test denial/restriction and interruptions. The entitlement question raised in the prerelease Group Lab is recorded in section 12; don't invent an entitlement name from that remark. [Capture authorization](https://developer.apple.com/documentation/avfoundation/requesting-authorization-to-capture-and-save-media)

## 10. Migration workflow

This is a recommended engineering sequence for each app. It is not a claim that the app has already been audited.

When a toolchain update introduces SwiftUI state-initialization or builder errors, consult the conditional `@State` and `ContentBuilder` diagnostics in [working with Xcode skills](working-with-xcode-skills.md). These are SDK migration issues, independent of Duo hardware. Build the actual app: the follow-up audit reproduced a state-initializer failure during SIL generation even though `-typecheck` passed. Do not apply unrelated compiler migrations merely to complete a Duo task.

### Phase A — establish adaptive behavior

1. Identify the build SDK, deployment targets, platforms, scene lifecycle, and custom rendering/camera components; check the built configuration described in section 2.
2. Build with the Duo-capable SDK and run the current app before rewriting UI. Record failures with screen, pose, orientation, size, and interaction state.
3. Audit global screen measurements, idiom/orientation layout checks, fixed phone widths, symmetric-safe-area assumptions, and root-view swaps.
4. Repair local sizing, constraints, scrollability, keyboard avoidance, and state ownership. Verify sheets/popovers, onboarding, authentication, paywalls, empty/error states, and settings as well as the main screen.
5. Preserve the existing older-OS path with guarded adoption. If the app also targets Catalyst, apply the documented beta compile-time workaround where needed.

Useful audit search, run in an app's source tree:

```sh
rg -n 'UIScreen\.main|UIScreen\.screens|userInterfaceIdiom|UIDevice\.current|interfaceOrientation|isLandscape|isPortrait|UIRequiresFullScreen|ignoresSafeArea|safeAreaInsets|connectedScenes\.first' .
```

These are review candidates, not a list to replace mechanically. Some orientation and screen queries are valid for nonlayout tasks; some backgrounds should ignore safe areas.

### Phase B — bars and interaction

1. Move appropriate custom bars into navigation-container ownership.
2. Give actions a title, icon, semantic placement, and suitable overflow behavior.
3. Prioritize frequent actions and meaningful status; choose toolbar-versus-tab compression per task.
4. Adapt custom items to vertical width or keep them horizontal deliberately.
5. Check Back/Close/Done, search, keyboard accessories, Live Activity pressure, PiP pressure, and system overflow.
6. Test RTL, larger text, VoiceOver order, Reduce Motion, Reduce Transparency, increased contrast, and light/dark appearance. Confirm the accessible name survives a symbol-only representation.

### Phase C — fold-aware custom content

1. Decide whether standard containers already handle the feature.
2. Use arrangements for genuine two-part content relationships.
3. Use local reserved regions for custom canvases, fixed overlays, grids, and controls.
4. Avoid displacing continuous scrolling content unnecessarily.
5. Preserve secondary functionality when axis restrictions hide a pane.
6. Keep query geometry, physical coordinates, RTL, and content reading order consistent.

### Phase D — optional Duo capabilities

- Adopt multi-instance scenes only if the product benefits; keep per-scene state independent.
- Add hinge effects only when useful, with a non-hinge path to essential actions.
- For camera apps, choose virtual versus physical discovery, direction handling, rotation/mirroring, and optional subject display deliberately.
- Document which items are baseline support and which are enhancements. A robust conventional app does not require a special hinge gimmick or camera accessory.

### Applying the model to common app types

| App type | Likely priorities | Common mistake |
| --- | --- | --- |
| Reader, comics, PDF, EPUB | Preserve reading anchor, page identity, zoom, progress; distinguish continuous scrolling from a fitted page; keep controls clear. | Rebuilding the reader or jumping to page start on resize. |
| Video/audio player | Media plus reachable controls/transcript; playback continuity; PiP and short-height layouts. | Hiding playback controls when the secondary pane disappears. |
| Editor or document app | Stable document/session state, adaptive inspectors, keyboard and selection continuity. | Replacing the editor model when switching compact/regular presentation. |
| Gallery, library, dashboard | Content-driven grid columns; even-column preference near a fold; stateful selection. | Hardcoding one wide-screen grid because the idiom is still phone. |
| Utility or calculator | Reachable controls at small heights; justified stable horizontal-bar preference. | Using a screen-shaped fixed frame or automatic vertical-bar opt-out everywhere. |
| Camera/video call | Direction, framing, active camera occlusion, mirroring, rotation, interruptions; subject display only if useful. | Assuming front/back remains viewer-relative or testing cameras only in Simulator. |
| Game/custom renderer | Resize render surface, viewports and hit targets; preserve game state; profile asset changes. | Assuming fullscreen compatibility means fixed bounds. |

## 11. Validation matrix

### What the original research actually validated

| Check | Result | Limit |
| --- | --- | --- |
| Installed Xcode | 27.1, build 27A9269 | Snapshot of the research environment, not a shipping release guarantee. |
| Simulator SDK | `iPhoneSimulator27.1.sdk` | Used for public-header/interface inspection and typechecking. |
| Runtime and device | iOS 27.1 runtime 24A94401; iPhone Duo device available and already booted | Existence only; no application pose walkthrough performed. |
| Toolbar SwiftUI/UIKit probe | Typecheck passed, including compression, priority, overflow, placement and edge APIs | iOS 26 deployment target with 27.1 availability guards; no runtime UI assertions. |
| Arrangement/regions/hinge probe | Typecheck passed with warnings as errors | No runtime measurement of filtering, layout or hinge delivery. |
| Camera/accessory probe | Swift 6 strict-concurrency typecheck passed | No actual capture session, accessory presentation or physical-camera test. |
| Four complete Swift examples extracted from this guide | Swift 6 strict-concurrency typecheck passed with warnings as errors and iOS 26 target | API declarations and context-dependent fragments are reference material, not standalone programs. |
| Existing apps | No app implementation changed | This deliverable is research context, not certification of any app. |

Companion probes and detailed evidence are retained in [iphone-duo-research](iphone-duo-research/): [bars](iphone-duo-research/BarsProbe.swift), [layout and hinge](iphone-duo-research/layout-api-examples.swift), [camera/accessory](iphone-duo-research/CameraAPIProbe.swift), and [guide examples](iphone-duo-research/GuideExamples.swift). The main guidance above is self-contained; these files make the compile-time checks reproducible.

Example typecheck command, using the selected SDK and a guarded probe. Run from the skill's `iphone-duo/` directory and configure `DUO_XCODE_DIR` as described in section 2:

```sh
DUO_XCODE_DIR="${DUO_XCODE_DIR:-$(xcode-select -p)}"
DUO_SDK_PATH="$(DEVELOPER_DIR="$DUO_XCODE_DIR" xcrun --sdk iphonesimulator --show-sdk-path)"
DEVELOPER_DIR="$DUO_XCODE_DIR" xcrun --sdk iphonesimulator swiftc \
  -typecheck -target arm64-apple-ios26.0-simulator \
  -sdk "$DUO_SDK_PATH" references/iphone-duo-research/BarsProbe.swift
```

For an app, build and test the actual scheme, entitlements, persistence and launch path. Do not remove signing/entitlements merely to make a simulator build pass if the app depends on those capabilities.

### Separate Xcode-skills audit — 19 September 2026

The follow-up audit inspected Xcode 27.1 (27A9269), checked relevant current Apple references, and typechecked a guarded corner-region/vertical-edge probe against iPhoneSimulator27.1 with Swift 6, complete strict concurrency, warnings as errors, and an iOS 26 deployment target. Targeted SwiftUI probes also reproduced state-initializer and overlay-overload failures and confirmed corresponding fixes; one failure required SIL generation to surface. These checks supplement the original evidence above and do not mean its probes were rerun. No app runtime, physical Duo behavior, or App Store submission was tested. See [working with Xcode skills](working-with-xcode-skills.md) for the bounded migration guidance and source discrepancies.

### Required app scenarios — not yet executed

Use Device Hub's available open/closed/fold/rotation controls and resizable previews. Test transitions in both directions without relaunching. Avoid assuming every physical pose or camera condition can be simulated. [Running on devices](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices), [Preparation talk, testing](https://developer.apple.com/videos/play/tech-talks/111461/)

| Scenario | Verify |
| --- | --- |
| Closed outer display, all supported orientations | Compact and short layouts, safe areas, camera avoidance, every primary action. |
| Fully open inner display, both aspect directions | Useful expansion, appropriate bars, no unnecessary fold gutter. |
| Partially folded with vertical and horizontal division | Controls readable and reachable; grouped controls stay coherent; hidden secondary content remains accessible. |
| Repeated open ↔ partial ↔ closed transitions | Navigation, selections, scroll anchors, drafts, focus, playback and game state persist. |
| Transition during scrolling, pinch/zoom, drag, edit or recording | No reset, stale hit targets, invalid constraints, or unexplained loss of work. |
| Left and right system Split View positions | Local bounds/insets, bar edge and active control placement remain correct. |
| Pinned PiP/video and height changes | Important content can scroll; overflow and completion actions remain usable. |
| Navigation split detail and inspectors | Correct ownership of bars; collapsed navigation remains logical. |
| Centered, leading, trailing sheets and popovers | Placement, dismissal, source anchoring and keyboard avoidance survive changes. |
| Keyboard, search, status/Live Activity pressure | Sensible compression; no duplicate/custom overflow competing with system overflow. |
| Inner camera active/inactive and outer camera | Reserved-region updates; no static geometry assumption. |
| RTL and long localization | Physical avoidance versus semantic ordering; title truncation and overflow labels. |
| Dynamic Type including accessibility sizes | Wrapping, scrolling, readable text and usable control groups in small clear regions. |
| VoiceOver, reduced motion/transparency, contrast, dark mode | Labels/order/focus, understandable transitions and legible custom content. |
| Multiple own scenes, when supported | Independent presentation state, shared data synchronization, failed activation handling. |
| Camera hardware and accessory | Correct viewer direction, preview/output rotation and mirroring, switching/interruptions, optional accessory lifecycle. |
| Optional hinge feature | Nil/unavailable, closed/partial/full and unknown statuses; effect reset, hierarchy exit, disable/re-enable and conventional input fallback. |
| Older supported OS, ordinary iPhone and iPad | Availability guards and baseline behaviors remain correct. |
| Catalyst, if shipped | Compile-time exclusions and supported fallback build on the actual target. |

### Meaningful automated coverage — engineering guidance

If a feature has custom layout math, test empty regions, both division axes, inactive regions, several occlusions, local nonzero origins, partial/edge intersections, very small content areas, and RTL coordinate handling. Verify important rectangles remain usable rather than merely snapshotting helper output. Test state continuity separately from geometry. For camera code, unit-test selection/failure policy with app-owned mock camera records or protocols, then integration-test real descriptors; `AVCaptureDeviceDescriptor` has no public initializer for creating synthetic instances.

Record runtime evidence per app: toolchain, OS/device, starting screen/state, transition performed, expected/actual result, screenshots/video where useful, and unresolved limitations. Synthetic geometry tests do not establish actual system region delivery or hardware ergonomics.

## 12. Beta limitations and documentation discrepancies

### Current toolchain constraints

The Xcode 27.1 beta release notes list slow initial Simulator launch, unavailable StandBy in the Duo runtime, and unavailable running/debugging for most app extensions. They also list Catalyst compile failures for iOS 27.1 APIs, recommending compile-time exclusions such as `#if !targetEnvironment(macCatalyst)`, and a separate Catalyst 27.0 minimum deployment workaround when no Catalyst destination appears. Canvas display overrides can preview an alternative device display. [Xcode 27.1 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27_1-release-notes)

A numerically newer beta is not proof of Duo support: the inspected Xcode 27.2 beta release notes direct Duo development to the separate 27.1 release. Confirm the SDK's actual declarations and simulator support before switching toolchains. [Xcode 27.2 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27_2-release-notes)

The Group Lab explains that the 27.1 Simulator can launch camera apps without finding cameras, allowing surrounding-UI tests. It cannot validate real capture or light both displays for the camera experience. Use physical hardware for that behavior. [Lab 286, camera Simulator limits](https://developer.apple.com/videos/play/meet-with-apple/286/?time=2677)

### Keep these uncertainties visible

| Topic | Evidence conflict or gap | Rule for implementation |
| --- | --- | --- |
| Reserved-region default active filtering | Layout talk says active-only; some current reference prose says active and inactive. | Explicitly use `.includeInactive` plus `.filter(\.isActive)` for an active-only policy; verify runtime behavior if default semantics matter. |
| Arrangement/navigation-split nesting | Overview and video warn about opposite nesting directions. | Prefer navigation stack outside arrangement; avoid either split-view nesting form without targeted validation. |
| Compression API name | Speech says `toolbarCompressionBehavior`; SDK exposes `toolbarVerticalCompressionBehavior`. | Use exact SDK declarations, as in the compiled probe. |
| General availability statements in labs | Some answers loosely say iOS 27. | Use per-symbol 27.1 guards for Duo-specific APIs. |
| Camera-accessory entitlement | Lab 285 mentions an entitlement without a name; current adoption docs, public headers, SDK entitlement metadata and Xcode capability catalog inspected here provide no matching public key. | Unresolved. Verify current signing/capability requirements with Apple before shipping this optional feature; do not invent an entitlement or confuse it with the documented lack of a scene-manifest entry. |
| Numeric hinge range/rate | Public inspected contracts do not define a stable range, zero convention or delivery rate. | Use status and explicit units; treat effect mapping as app policy. |
| Orientation/fullscreen compatibility | Earlier references and current talks describe different generations and contexts. | Test current inner/outer and resizable behavior; never depend on it to avoid resizing. |
| WebKit pose exposure, table-surface detection, motion details discussed in labs | Panel responses included uncertainty and did not establish a complete public contract. | No web pose API or reliable table-detection promise is made by this guide. |

Entitlement source: [Lab 285, accessory discussion](https://developer.apple.com/videos/play/meet-with-apple/285/?time=252), compared with [current accessory adoption article](https://developer.apple.com/documentation/avfoundation/registering-a-camera-capture-accessory-on-iphone-duo). These open items are deliberately preserved so future implementation does not turn tentative remarks into requirements or guarantees.

The TN3210 indirect-input section says to remove a `NO` opt-out or enable the key, but its adjacent XML example currently shows `<false/>`. Follow the prose and authoritative property semantics when implementing; do not copy that contradictory fragment. [TN3210](https://developer.apple.com/documentation/technotes/tn3210-optimizing-your-app-for-iphone-mirroring)

## 13. Distribution and design resources

Use [Apple Design Resources](https://developer.apple.com/design/resources/) for Duo design kits. Apple announced updated Figma/Sketch resources alongside the 27.1 beta on September 18. These are useful for mockups; their dimensions should not become layout constants. [Resource announcement](https://developer.apple.com/news/?id=nyuppv9r)

App Store Connect's current screenshot specifications list:

| Display | Accepted screenshot pixel sizes |
| --- | --- |
| Outer | 1398 × 2034 or 2034 × 1398 |
| Inner | 2007 × 2853 or 2853 × 2007 |

These are marketing asset sizes, **not point dimensions or layout breakpoints**. The page currently says Duo asset uploads will become available later in the year; recheck at submission time. [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)

The current app-preview page lists 886 × 1920 portrait or 1920 × 886 landscape as accepted Duo preview sizes, with the same upload-availability note. Its device-resolution/aspect-ratio labels should not be used to infer app geometry. Confirm the live requirements before rendering final marketing videos. Beta build installability or local typechecking does not establish App Store submission acceptance. [App-preview specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications), [App Store Connect release notes](https://developer.apple.com/help/app-store-connect/release-notes/)

## 14. Research coverage and source catalog

The linked preparation overview was the starting point. All **50 unique direct documentation references** in its body/related-documentation section were fetched successfully, including generic framework/container references. The six Duo Tech Talks and both directly linked WWDC talks were read through their full published transcripts. Additional API members, HIG guidance, release notes, design resources, and distribution references were followed where relevant to adoption.

Both related Duo Group Labs had empty web transcript tabs. Their substantive Q&A was researched through the English captions provided by Apple's linked HLS streams. Videos were researched through transcripts/captions and available code, not by visually inspecting every demonstration frame. General Apple site navigation, every inherited protocol/member on framework pages, and unrelated WWDC topics were not recursively crawled. This catalog describes bounded adoption research, not a claim to have exhausted Apple's entire documentation graph.

### Main videos and targeted follow-ups

| Source | Coverage | Best use |
| --- | --- | --- |
| [Design for iPhone Duo — 111466](https://developer.apple.com/videos/play/tech-talks/111466/) | Full transcript | Start here for the design rationale and continuity. |
| [Prepare your app for iPhone Duo — 111461](https://developer.apple.com/videos/play/tech-talks/111461/) | Full transcript | SDK behavior, sizing, safe areas and testing. |
| [Raise the bar with iPhone Duo — 111462](https://developer.apple.com/videos/play/tech-talks/111462/) | Full transcript | Bar ownership, item axes, overflow and custom controls. |
| [Strike a pose with adaptive layouts — 111463](https://developer.apple.com/videos/play/tech-talks/111463/) | Full transcript | Displacement, reserved regions and arrangements. |
| [Leverage multiple displays and scenes — 111464](https://developer.apple.com/videos/play/tech-talks/111464/) | Full transcript | Hinge interaction, multitasking and accessories. |
| [Build a great camera experience — 111465](https://developer.apple.com/videos/play/tech-talks/111465/) | Full transcript | Camera discovery, direction, preview and concurrency. |
| [Modernize your UIKit app — WWDC26/278](https://developer.apple.com/videos/play/wwdc2026/278/) | Full transcript | Current adaptivity and scene-lifecycle migration. |
| [Make your UIKit app more flexible — WWDC25/282](https://developer.apple.com/videos/play/wwdc2025/282/) | Full transcript | Scene restoration, flexible containers and rendering. |
| [iPhone Duo Group Lab — 285](https://developer.apple.com/videos/play/meet-with-apple/285/) | Substantive Q&A captions | Layout, accessibility, state and prerelease questions. |
| [iPhone Duo Group Lab — 286](https://developer.apple.com/videos/play/meet-with-apple/286/) | Substantive Q&A captions | Transitions, SwiftUI identity and simulator constraints. |
| [What's new in SwiftUI — WWDC26/269](https://developer.apple.com/videos/play/wwdc2026/269/) | Resizability/toolbar portions | Supporting 27.0 bar APIs and previews. |
| [Support the Center Stage front camera — WWDC26/341](https://developer.apple.com/videos/play/wwdc2026/341/) | Full transcript | Format-dependent framing, aspect ratios and recording. |
| [Get to know the new design system — WWDC25/356](https://developer.apple.com/videos/play/wwdc2025/356/) | Full transcript | Grouping, symbols, continuity and system styling. |

### Design and implementation entry points

- [Duo developer hub](https://developer.apple.com/iphone-duo/) and [preparation overview](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo).
- [Duo HIG](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo), [Layout](https://developer.apple.com/design/human-interface-guidelines/layout), [Split views](https://developer.apple.com/design/human-interface-guidelines/split-views), [Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars), [Designing for iOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-ios), and the relevant adaptivity portion of [Designing for games](https://developer.apple.com/design/human-interface-guidelines/designing-for-games).
- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass): supporting system-design context; avoid stacking legacy custom backgrounds/decorations over container-managed bars without a design reason.
- [Camera direction adoption](https://developer.apple.com/documentation/avkit/choosing-a-camera-by-the-direction-it-faces) and [camera accessory adoption](https://developer.apple.com/documentation/avfoundation/registering-a-camera-capture-accessory-on-iphone-duo).
- [Xcode 27.1 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27_1-release-notes) and [running on devices](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices).

Individual API links are attached to the relevant guidance above. A complete direct-link list appears after the reusable context below. Detailed supporting notes are retained for deeper follow-up: [layout/hinge](iphone-duo-research/layout-api-notes.md), [camera](iphone-duo-research/camera-notes.md), and [UX/videos](iphone-duo-research/ux-videos-notes.md).

## 15. Reusable context for future app work

The following can be included in a future implementation task alongside this document:

> Add iPhone Duo support while preserving the app's existing behavior and older-OS support. Read this guide and recheck current Apple documentation for any beta-specific items. First inspect the app's navigation, scene lifecycle, layout assumptions, state ownership, toolbars, presentations, custom rendering, and cameras. Use local container geometry and actual traits, standard navigation containers, and safe areas. Adopt reserved regions or arrangements only where needed; use hinge input for optional interaction rather than layout thresholds. Preserve task state and access to all functionality through display changes, folding, resizing and multitasking. Give toolbar actions semantic placement, titles/icons and overflow priorities. Guard 27.1 APIs and test Catalyst separately if applicable. For cameras, distinguish physical position from viewer-relative direction and validate accessory behavior on hardware. Report actual compile/runtime evidence separately from recommended or unavailable tests; never infer device behavior solely from a passing geometry test.
## Appendix: direct documentation links from the overview

The 50 direct documentation destinations below were successfully retrieved during the original research. Follow these official links for current source material. Generic framework roots are reference entry points; the adoption-specific contracts are summarized in the main guide.

### AVFoundation

- [AVFoundation](https://developer.apple.com/documentation/avfoundation)
- [Registering a camera capture accessory on iPhone Duo](https://developer.apple.com/documentation/avfoundation/registering-a-camera-capture-accessory-on-iphone-duo)

### AVKit

- [AVKit](https://developer.apple.com/documentation/avkit)
- [Choosing a camera by the direction it faces](https://developer.apple.com/documentation/avkit/choosing-a-camera-by-the-direction-it-faces)

### SwiftUI

- [ArrangementView](https://developer.apple.com/documentation/swiftui/arrangementview)
- [toolbarVerticalEdge](https://developer.apple.com/documentation/swiftui/environmentvalues/toolbarverticaledge)
- [GeometryProxy](https://developer.apple.com/documentation/swiftui/geometryproxy)
- [reservedRegions(kind:options:layoutDirectionBehavior:)](https://developer.apple.com/documentation/swiftui/geometryproxy/reservedregions(kind:options:layoutdirectionbehavior:))
- [GeometryReader](https://developer.apple.com/documentation/swiftui/geometryreader)
- [HStack](https://developer.apple.com/documentation/swiftui/hstack)
- [NavigationSplitView](https://developer.apple.com/documentation/swiftui/navigationsplitview)
- [NavigationStack](https://developer.apple.com/documentation/swiftui/navigationstack)
- [ReservedRegion](https://developer.apple.com/documentation/swiftui/reservedregion)
- [axisBehavior(_:)](https://developer.apple.com/documentation/swiftui/toolbarcontent/axisbehavior(_:))
- [visibilityPriority(_:)](https://developer.apple.com/documentation/swiftui/toolbarcontent/visibilitypriority(_:))
- [ToolbarItem](https://developer.apple.com/documentation/swiftui/toolbaritem)
- [ToolbarItemPlacement](https://developer.apple.com/documentation/swiftui/toolbaritemplacement)
- [cancellationAction](https://developer.apple.com/documentation/swiftui/toolbaritemplacement/cancellationaction)
- [topBarPinnedTrailing](https://developer.apple.com/documentation/swiftui/toolbaritemplacement/topbarpinnedtrailing)
- [ToolbarOverflowMenu](https://developer.apple.com/documentation/swiftui/toolbaroverflowmenu)
- [backgroundExtensionEffect()](https://developer.apple.com/documentation/swiftui/view/backgroundextensioneffect())
- [presentationPlacement(_:)](https://developer.apple.com/documentation/swiftui/view/presentationplacement(_:))
- [toolbar(content:)](https://developer.apple.com/documentation/swiftui/view/toolbar(content:))
- [toolbarVerticalBehavior(_:)](https://developer.apple.com/documentation/swiftui/view/toolbarverticalbehavior(_:))
- [VStack](https://developer.apple.com/documentation/swiftui/vstack)
- [ZStack](https://developer.apple.com/documentation/swiftui/zstack)

### TechnologyOverviews

- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)

### Technotes

- [TN3210: Optimizing your app for iPhone Mirroring](https://developer.apple.com/documentation/technotes/tn3210-optimizing-your-app-for-iphone-mirroring)

### UIKit

- [Adapting your app when traits change](https://developer.apple.com/documentation/uikit/adapting-your-app-when-traits-change)
- [Automatic trait tracking](https://developer.apple.com/documentation/uikit/automatic-trait-tracking)
- [UIArrangementViewController](https://developer.apple.com/documentation/uikit/uiarrangementviewcontroller)
- [UIBackgroundExtensionView](https://developer.apple.com/documentation/uikit/uibackgroundextensionview)
- [axisBehavior](https://developer.apple.com/documentation/uikit/uibarbuttonitem/axisbehavior-swift.property)
- [visibilityPriority](https://developer.apple.com/documentation/uikit/uibarbuttonitem/visibilitypriority)
- [userInterfaceIdiom](https://developer.apple.com/documentation/uikit/uidevice/userinterfaceidiom)
- [UIInterfaceOrientation](https://developer.apple.com/documentation/uikit/uiinterfaceorientation)
- [UINavigationBar](https://developer.apple.com/documentation/uikit/uinavigationbar)
- [additionalOverflowItems](https://developer.apple.com/documentation/uikit/uinavigationitem/additionaloverflowitems)
- [leadingItemGroups](https://developer.apple.com/documentation/uikit/uinavigationitem/leadingitemgroups)
- [pinnedTrailingGroup](https://developer.apple.com/documentation/uikit/uinavigationitem/pinnedtrailinggroup)
- [preferredPlacement](https://developer.apple.com/documentation/uikit/uisheetpresentationcontroller/preferredplacement)
- [UITabBar](https://developer.apple.com/documentation/uikit/uitabbar)
- [UIToolbar](https://developer.apple.com/documentation/uikit/uitoolbar)
- [horizontalSizeClass](https://developer.apple.com/documentation/uikit/uitraitcollection/horizontalsizeclass)
- [verticalBarEdge](https://developer.apple.com/documentation/uikit/uitraitcollection/verticalbaredge)
- [verticalSizeClass](https://developer.apple.com/documentation/uikit/uitraitcollection/verticalsizeclass)
- [UIView.ReservedRegion](https://developer.apple.com/documentation/uikit/uiview/reservedregion)
- [reservedRegions(kind:options:)](https://developer.apple.com/documentation/uikit/uiview/reservedregions(kind:options:))
- [preferredVerticalBarBehavior](https://developer.apple.com/documentation/uikit/uiviewcontroller/preferredverticalbarbehavior)

### Xcode

- [Running your app on simulated or physical devices](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices)
