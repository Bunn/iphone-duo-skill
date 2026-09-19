# iPhone Duo: arrangement, reserved-region, and hinge API research

> Research snapshot: use the linked official Apple sources and the selected SDK for current verification. Companion Swift probes are bundled; successful typechecks recorded here are historical evidence from 19 September 2026.

Checked 2026-09-19 against Apple's live Markdown documentation, Tech Talks 111463 and 111464, and the iPhoneSimulator27.1 SDK supplied with Xcode 27.1 (27A9269). These notes distinguish published behavior, local SDK declarations, and recommendations. All new API examples below require iOS 27.1; guard their use for older deployment targets. The cited pages also list iPadOS 27.1.

## 1. Choose the right layout abstraction

Use standard navigation containers and presentations first. An arrangement is a layout container for exactly two roles, primary and secondary; it does not provide navigation. It computes placement and visibility from available bounds, size classes, and active division regions. It is a useful replacement for an existing custom two-pane `HStack`/`VStack` or foreground/background `ZStack` layout. It is not a reason to reconstruct working navigation. [ArrangementView](https://developer.apple.com/documentation/swiftui/arrangementview), [UIArrangementViewController](https://developer.apple.com/documentation/uikit/uiarrangementviewcontroller), [adaptive layouts video, 9:20 onward](https://developer.apple.com/videos/play/tech-talks/111463/?time=560).

| Choice | Documented behavior | Suitable existing pattern |
|---|---|---|
| Split arrangement | Separates primary and secondary along an adaptive axis; normally horizontal when the container is wider than tall and vertical when taller than wide. Adapts placement around the fold. | Two related views that should not obscure each other, such as playback plus transcript. |
| Overlay arrangement | Primary is above secondary in z-order without an active division. Partial folding can separate them into regions, with primary trailing/bottom and secondary leading/top by default. | Foreground controls over background content, where partial overlap is acceptable. |
| Reserved-region query | Supplies intersecting reserved geometry so a custom layout can decide where controls/content belong. | Custom canvases, games, grids, edge-to-edge controls, or floating UI not adequately handled by standard containers. |
| Hinge observation | Supplies hinge status and changing angle for interactions/effects. | Optional tilt-like effects, musical controls, or other creative responses to folding. Use arrangement/region APIs for layout. |

The first two rows are based on [Preparing your app](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo) and the arrangement references. The hinge/layout distinction is explicit in [multiple displays video, 2:35](https://developer.apple.com/videos/play/tech-talks/111464/?time=155).

**Nesting caveat:** The overview cautions against an arrangement *inside* a navigation split view, list, or scroll view. The video cautions against navigation containers such as `NavigationSplitView` *inside* an arrangement, and against arrangements inside scrollable containers. The sources differ in the direction of the navigation-split nesting warning; the safe reusable pattern is `NavigationStack → ArrangementView → content`, as demonstrated by Apple, or `UINavigationController → UIArrangementViewController → child content controllers`. Avoid either form of `NavigationSplitView`/arrangement nesting without specific validation. A content `ScrollView` within a pane is distinct from placing the entire arrangement inside a scrolling container. [Overview](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo), [video at 11:17](https://developer.apple.com/videos/play/tech-talks/111463/?time=677), [video at 16:09](https://developer.apple.com/videos/play/tech-talks/111463/?time=969).

## 2. SwiftUI arrangements

`ArrangementView<Primary, Secondary>` takes two view-builder closures. Its default `.automatic` style resolves to `.split`; use `.overlay` when that content relationship is intended. Styles support `axes(_:)` with `Axis.Set`, e.g. `.horizontal`, `.vertical`, or `[.horizontal, .vertical]`. [Initializer](https://developer.apple.com/documentation/swiftui/arrangementview/init(primary:secondary:)), [default style](https://developer.apple.com/documentation/swiftui/automaticarrangementviewstyle), [split axes](https://developer.apple.com/documentation/swiftui/splitarrangementviewstyle/axes(_:)).

```swift
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

**Axis restriction can hide content.** `.split.axes(.horizontal)` does not force two narrow columns in every pose. When the main layout axis is vertical and splitting on that axis is prohibited, the arrangement shows only the primary view. Provide another route or an inline representation for important secondary content. Apple's Podcasts example renders its transcript inline in this case. [Overview example](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo), [video at 12:00](https://developer.apple.com/videos/play/tech-talks/111463/?time=720).

Per-pane sizing controls are preferences/constraints on the child, rather than hard-coded phone dimensions:

| API | Meaning and caveat |
|---|---|
| `splitArrangementLayoutRatio(_ ratio: CGFloat?)` | Preferred share. Higher `layoutPriority` is allocated first. A share exceeding remaining room is limited to that room; when shares leave unused room, the highest-priority view fills it. Ratios need not behave like two independent fixed percentages. |
| `splitArrangementLayoutRatio(minHorizontal:idealHorizontal:maxHorizontal:minVertical:idealVertical:maxVertical:)` | Independent ratio constraints for horizontal and vertical splits; each argument defaults to `nil`. |
| `splitArrangementLayoutSize(minWidth:idealWidth:maxWidth:minHeight:idealHeight:maxHeight:)` | Point-size constraints. Width applies to horizontal splitting, height to vertical. Higher-priority views receive ideal size clamped to their bounds first. Each parameter defaults to `nil`. |
| `splitArrangementFixedLayoutSize(horizontal: Bool = true, vertical: Bool = true)` | Prefers the child's ideal size but can shrink it according to priority; “fixed” does not guarantee unchanging size. |

Sources: [ratio](https://developer.apple.com/documentation/swiftui/view/splitarrangementlayoutratio(_:)), [ratio ranges](https://developer.apple.com/documentation/swiftui/view/splitarrangementlayoutratio(minhorizontal:idealhorizontal:maxhorizontal:minvertical:idealvertical:maxvertical:)), [size constraints](https://developer.apple.com/documentation/swiftui/view/splitarrangementlayoutsize(minwidth:idealwidth:maxwidth:minheight:idealheight:maxheight:)), [fixed preferred size](https://developer.apple.com/documentation/swiftui/view/splitarrangementfixedlayoutsize(horizontal:vertical:)).

For overlay arrangements, `.overlayArrangementEdge(.trailing)` chooses the child's horizontal destination when separated. The installed SDK also exposes an overload accepting `VerticalEdge?`, allowing `.bottom` or `.top`; its declarations are in `SwiftUICore.swiftinterface:12811`. Explicitly type `nil` if needed because there are two optional-edge overloads. [Horizontal edge documentation](https://developer.apple.com/documentation/swiftui/view/overlayarrangementedge(_:)).

Read the result of arrangement decisions inside children:

- `@Environment(\.splitArrangementAxis) var axis`: `Axis?`, documented as `nil` outside a split arrangement; adapt inner controls for the pane's current axis.
- `@Environment(\.overlayArrangementZIndex) var zIndex`: `Int`; higher is visually above lower. Apple's sample uses `zIndex > 0` to choose a collapsed overlay and `0` for its expanded state. Do not treat this as a universal device-pose detector.

Sources: [splitArrangementAxis](https://developer.apple.com/documentation/swiftui/environmentvalues/splitarrangementaxis), [overlayArrangementZIndex](https://developer.apple.com/documentation/swiftui/environmentvalues/overlayarrangementzindex), [video at 13:59](https://developer.apple.com/videos/play/tech-talks/111463/?time=839).

`ArrangementViewStyle` also allows a custom `makeBody(configuration:)`; `ArrangementViewStyleConfiguration` exposes primary/secondary type-erased content and `ArrangementView(configuration)` can forward it. Recommendation: start with the built-in styles because a fully custom layout must preserve the adaptive behavior itself. [Style protocol](https://developer.apple.com/documentation/swiftui/arrangementviewstyle), [configuration](https://developer.apple.com/documentation/swiftui/arrangementviewstyleconfiguration).

## 3. UIKit arrangements

`UIArrangementViewController` uses `.primary` and `.secondary` placements. `setViewController(_:for:animated:)` defaults `animated` to `false`; passing `nil` removes the controller at that placement. `updateArrangement(_:animated:)` also defaults to `false`. Its initial style is split. `viewController(for:)`, `placement(for:)`, and `state(for:)` are optional-returning lookup APIs. `UIViewController.arrangementViewController` finds the nearest ancestor arrangement. [Controller](https://developer.apple.com/documentation/uikit/uiarrangementviewcontroller), [set controller](https://developer.apple.com/documentation/uikit/uiarrangementviewcontroller/setviewcontroller(_:for:animated:)), [update](https://developer.apple.com/documentation/uikit/uiarrangementviewcontroller/updatearrangement(_:animated:)), [ancestor](https://developer.apple.com/documentation/uikit/uiviewcontroller/arrangementviewcontroller).

```swift
@available(iOS 27.1, *)
@MainActor
func makeTwoPaneController(
    primary: UIViewController,
    secondary: UIViewController
) -> UINavigationController {
    let container = UIArrangementViewController()
    container.setViewController(primary, for: .primary)
    container.setViewController(secondary, for: .secondary)
    container.updateArrangement(.split) // allows the system's adaptive split
    return UINavigationController(rootViewController: container)
}
```

UIKit sizing customization is confirmed by the installed SDK's public interface, even where the individual Swift member pages are absent from the website:

```swift
var split = UISplitArrangement().axes(.horizontal)
var properties = split.defaultViewProperties
properties.width.minimum = .absolute(240)
properties.width.preferred = .fractional(0.4)
properties.width.maximum = .fractional(0.6)
properties.layoutPriority = 1
split.setViewProperties(properties, for: .primary)
container.updateArrangement(split, animated: true)

var overlay = UIOverlayArrangement()
var overlayProperties = overlay.defaultViewProperties
overlayProperties.edge = .trailing
overlay.setViewProperties(overlayProperties, for: .primary)
```

These numbers are example app preferences, not recommended device dimensions. `UISplitArrangement.Dimension` supports `.automatic`, `.intrinsic`, `.absolute(CGFloat)` in points, and `.fractional(CGFloat)` relative to the container. Each `ViewProperties` has `width`, `height` (`DimensionRange`: minimum/preferred/maximum), plus `layoutPriority`. Overlay view properties have an `NSDirectionalRectEdge` edge. Start with `defaultViewProperties`; the Swift structs do not expose a general public initializer for `ViewProperties`. The `axes` methods return a new value: assign the result. [Split type](https://developer.apple.com/documentation/uikit/uisplitarrangement-swift.struct), [Dimension](https://developer.apple.com/documentation/uikit/uisplitarrangement-swift.struct/dimension), [DimensionRange](https://developer.apple.com/documentation/uikit/uisplitarrangement-swift.struct/dimensionrange), [arrangement protocol](https://developer.apple.com/documentation/uikit/uiarrangementviewcontroller/arrangement). SDK: `UIKit.swiftinterface:2086–2201`, `UISplitArrangement.h`, `UIOverlayArrangement.h`.

The returned `ViewState` exposes `isHidden`, `splitAxis: UIAxis`, and `zIndex: Int`. It is a state query, not a newly discovered notification/delegate API. Read it when adapting the affected controller's UI; do not invent an `arrangementDidChange` method. [ViewState](https://developer.apple.com/documentation/uikit/uiarrangementviewcontroller/viewstate).

## 4. Reserved regions and custom layout

Exact signatures, confirmed in docs and SDK:

```swift
// SwiftUI.GeometryProxy
func reservedRegions(
    kind: ReservedRegion.Kind,
    options: ReservedRegion.QueryOptions = [],
    layoutDirectionBehavior: LayoutDirectionBehavior = .mirrors
) -> [ReservedRegion]

// UIKit.UIView — main actor
func reservedRegions(
    kind: UIView.ReservedRegion.Kind,
    options: UIView.ReservedRegion.QueryOptions = []
) -> [UIView.ReservedRegion]
```

Both region types describe `id`, `kind`, `frame`, `margins`, and `isActive`. `frame` is in the queried view's coordinates and **already includes margins** intended to protect interactive content. SwiftUI margins use `EdgeInsets`; UIKit uses `UIEdgeInsets`. Query `.division` for a split such as the hinge, `.occlusion` for an obstruction such as an active camera. These categories are not interchangeable: a division reorganizes content into parts, whereas an occlusion is an area to avoid. There may be zero or multiple returned regions. [GeometryProxy query](https://developer.apple.com/documentation/swiftui/geometryproxy/reservedregions(kind:options:layoutdirectionbehavior:)), [SwiftUI region](https://developer.apple.com/documentation/swiftui/reservedregion), [UIKit query](https://developer.apple.com/documentation/uikit/uiview/reservedregions(kind:options:)), [UIKit region](https://developer.apple.com/documentation/uikit/uiview/reservedregion).

**Active-state documentation discrepancy:** Apple's adaptive-layout video explicitly says default queries return active regions, and `.includeInactive` asks for inactive ones too. The fold region is inactive with zero width when flat, and active while partially folded; an inactive division may still inform a grid's even-column preference. However, the current prose of the `ReservedRegion` overviews and SwiftUI query page says intersecting regions are returned regardless of active state. Both signatures default to `options: []`, and SDK headers define `includeInactive` but do not independently settle runtime filtering. Treat the video's active-only default as the intended behavior, record the documentation discrepancy, and explicitly request `.includeInactive` whenever inactive geometry matters. Runtime filtering was not measured in this research. [Video at 7:03–8:39](https://developer.apple.com/videos/play/tech-talks/111463/?time=423), [SwiftUI option](https://developer.apple.com/documentation/swiftui/reservedregion/queryoptions/includeinactive), [UIKit option](https://developer.apple.com/documentation/uikit/uiview/reservedregion/queryoptions/includeinactive).

For an unambiguous active-only policy in app code, ask for all then filter:

```swift
// Within a GeometryReader's closure:
let activeDivisions = proxy.reservedRegions(
    kind: .division,
    options: .includeInactive
).filter(\.isActive)

// Within a UIKit view/controller's layout code:
let activeOcclusions = view.reservedRegions(
    kind: .occlusion,
    options: .includeInactive
).filter(\.isActive)
let protectedFrames = activeOcclusions.map(\.frame)
```

SwiftUI normally mirrors returned geometry for right-to-left layouts because SwiftUI `Layout` mirrors placed subviews. Keep that default for a layout which participates in this automatic mirroring. Use `layoutDirectionBehavior: .fixed` only for code that intentionally uses fixed physical coordinates and handles RTL itself. A camera does not physically move when language changes, but mixing mirrored and unmirrored coordinates will move controls to the wrong side. [Geometry and RTL discussion](https://developer.apple.com/documentation/swiftui/reservedregion).

Implementation recommendations derived from those contracts:

- Query at the container whose local coordinates drive your layout; convert coordinates explicitly if using the frames elsewhere.
- Do not add `margins` again to `frame`. Do not substitute screen-width constants or a fixed half-screen “hinge.”
- Reevaluate with geometry changes. SwiftUI's `GeometryReader` and `onGeometryChange` supply a geometry proxy; UIKit layout code can read regions for current bounds. No public `reservedRegionsDidChange` callback was found in the inspected `UIView` header; do not invent one.
- Treat a fold change, camera becoming active, resizing in multitasking, rotation, and RTL as separate test inputs.
- Preserve state when moving/reflowing content. Test control reachability and scroll access when an arrangement hides a secondary view.
- Custom reserved-region logic complements safe areas; normal interactive foreground content still belongs inside appropriate safe areas. Background artwork may extend farther. This does not justify universally ignoring safe areas. [Prepare video at 6:06–9:12](https://developer.apple.com/videos/play/tech-talks/111461/?time=366).

## 5. Hinge status and continuous effects

Use hinge APIs for effects and interaction; use layout size, arrangements, and reserved regions for placement. Do not infer fold visibility from an arbitrary angle threshold. SwiftUI says status is decided by the system using angle and device orientation. [DeviceHinge](https://developer.apple.com/documentation/swiftui/devicehinge), [multiple displays video](https://developer.apple.com/videos/play/tech-talks/111464/?time=78).

| SwiftUI | UIKit |
|---|---|
| `onHingeChange(isEnabled: Bool = true, _ action: (DeviceHingeContext, DeviceHingeContext) -> Void)` | `UIHingeInteraction(updateHandler: (UIHingeInteraction, UIHingeInteraction.Update) -> Void)` then `view.addInteraction(interaction)` |
| Callback contexts are old and new. `context.hinge: DeviceHinge?`. | Callback first parameter is the interaction, **not the old context**. `update.hinge: UIHinge?`. |
| `DeviceHinge.angle: Angle`; use `.degrees` or `.radians` explicitly. | `UIHinge.angle: CGFloat` is explicitly radians. |
| `DeviceHinge.Status` is a struct with `.closed`, `.partiallyOpen`, `.fullyOpen`. | `UIHinge.Status` is an enum with `.unknown`, `.closed`, `.partiallyOpen`, `.fullyOpen`; handle unknown/future values. |

Sources: [onHingeChange](https://developer.apple.com/documentation/swiftui/view/onhingechange(isenabled:_:)), [context](https://developer.apple.com/documentation/swiftui/devicehingecontext), [SwiftUI status](https://developer.apple.com/documentation/swiftui/devicehinge/status-swift.struct), [UIHingeInteraction](https://developer.apple.com/documentation/uikit/uihingeinteraction), [UIKit status](https://developer.apple.com/documentation/uikit/uihinge/status-swift.enum), [UIKit angle](https://developer.apple.com/documentation/uikit/uihinge/angle).

No contractual numeric angle range, zero-angle convention, or fixed update frequency was found in these public pages or headers. Do not assert a guaranteed `0...180°` range, derive “fully open” from equality with π, or depend on sensor precision. The UIKit angle documentation explicitly makes rate and granularity system policy. Prefer `status` if continuous angle is unnecessary. [Angle contract](https://developer.apple.com/documentation/uikit/uihinge/angle).

Apple's SwiftUI demo treats a nil hinge as lack of hinge hardware, but UIKit documentation also returns nil when the interaction leaves a hierarchy which provides hinge updates. Handle nil as **hinge unavailable for this context**, rather than permanently classifying the device. Reset optional effects when unavailable or when the desired state ends. The UIKit update handler runs initially and on updates, including hierarchy changes. It escapes, so avoid a retain cycle. Disabled interactions drop updates; re-enabling delivers the current hinge state if available. [Update](https://developer.apple.com/documentation/uikit/uihingeinteraction/update/hinge), [initializer](https://developer.apple.com/documentation/uikit/uihingeinteraction/init(updatehandler:)), [isEnabled](https://developer.apple.com/documentation/uikit/uihingeinteraction/isenabled).

```swift
@available(iOS 27.1, *)
struct HingeReadout: View {
    @State private var currentDegrees: Double?

    var body: some View {
        Text(currentDegrees.map { "Hinge: \($0)°" } ?? "Hinge inactive")
            .onHingeChange { _, context in
                guard let hinge = context.hinge,
                      hinge.status == .partiallyOpen else {
                    currentDegrees = nil // Reset app effects here too.
                    return
                }
                currentDegrees = hinge.angle.degrees
            }
    }
}
```

```swift
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
```

These examples report the actual API values and intentionally do not invent a normalized physical range. An app may map values into an artistic effect using its own calibrated, clamped policy and keep an equivalent conventional input available.

## Verification evidence

The original research inspected these public files beneath the iPhoneSimulator27.1 SDK's `System/Library/Frameworks/` directory. To locate the selected SDK, use the [guide's toolchain commands](../iPhone-Duo-Developer-Guide.md#2-build-availability-and-compatibility):

- `SwiftUICore.framework/Modules/SwiftUICore.swiftmodule/arm64-apple-ios-simulator.swiftinterface` — arrangements, sizing, both overlay-edge overloads, regions, hinge types, onHingeChange.
- `UIKit.framework/Modules/UIKit.swiftmodule/arm64-apple-ios-simulator.swiftinterface` — Swift overlays and property types.
- `UIKit.framework/Headers/UIArrangementViewController.h`, `UISplitArrangement.h`, `UIOverlayArrangement.h`, `UIViewReservedRegion.h`, `UIHinge.h`, `UIHingeInteraction.h` — public contracts/comments and availability.

The standalone companion [layout-api-examples.swift](layout-api-examples.swift) passed `swiftc -typecheck -warnings-as-errors -target arm64-apple-ios27.1-simulator` against that SDK on 2026-09-19. It checks the two-pane pattern, SwiftUI sizing and both overlay-edge overloads, arrangement environment values, both region queries/options, UIKit dimension/view properties, and both hinge observers. This establishes API/type correctness; it does not prove runtime adaptation, filtering, hardware sensor behavior, or visual quality.

The original research successfully retrieved 39 linked Apple Markdown pages and reviewed the transcripts for [adaptive layouts](https://developer.apple.com/videos/play/tech-talks/111463/) and [multiple displays and scenes](https://developer.apple.com/videos/play/tech-talks/111464/). Use the official sources linked throughout these notes to repeat or update that research.
