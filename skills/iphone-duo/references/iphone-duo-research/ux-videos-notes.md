# iPhone Duo: UI/UX and video research notes

> Research snapshot: use the linked official Apple sources and the selected SDK for current verification. Companion Swift probes are bundled; successful typechecks recorded here are historical evidence from 19 September 2026.

Researched 2026-09-19. Original summaries of official Apple material. This file is an input to the consolidated support guide; API spellings should be checked against the installed 27.1 SDK. Videos were researched using their complete published transcripts, not by watching every frame. Group Lab coverage is tracked separately below.

## Core UI/UX rules

[Designing for iPhone Duo — HIG](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo)

- Preserve app state, functionality, and information hierarchy across displays; use extra width to reveal existing levels of hierarchy.
- Build compact and regular layouts rather than six pose-specific screens. Keep changes during folding small enough to follow visually.
- The outer camera region always exists; the inner camera region becomes relevant when its camera activates. The folding region becomes active when partially open.
- Prefer an even column count for grids around the fold. Group related elements so they move together.
- Navigation belongs outside arrangement containers; arrangements organize content without providing navigation.
- Bar position follows hardware, including in right-to-left languages. Split View puts each app's bar at its outside edge.
- Keep pane-specific controls with their pane. Primary navigation appears above prominent actions; preserve meaningful toolbar groups.
- Prefer system overflow, reserving ellipsis for it. Prioritize frequent actions and meaningful badges.
- Games should stay playable in every pose, maintain text/control sizing, and preferably adapt aspect ratio rather than letterbox.

## Findings from the six direct Tech Talks

### Prepare your app for iPhone Duo — 111461

[SDK behavior, 0:30](https://developer.apple.com/videos/play/tech-talks/111461/?time=30): rebuilding with iOS 27.1 enables edge-to-edge presentation and the new bars. Earlier SDKs remain compatible with different screen usage.

[Size classes, 2:46](https://developer.apple.com/videos/play/tech-talks/111461/?time=166): outer portrait is compact-width/regular-height; outer landscape compact/compact; inner display regular/regular. These describe available experience, not device identity. Avoid orientation and idiom as layout proxies. `UIRequiresFullScreen` does not prevent resizing during display transitions; compatibility orientation/scaling behavior needs independent attention.

[Screen assumptions, 3:57](https://developer.apple.com/videos/play/tech-talks/111461/?time=237): prefer local geometry, environment, and traits; if a screen is essential, obtain it dynamically from the window scene. Use display-scale traits rather than `UIScreen.main`. Concentric shapes support Duo's geometry.

[Navigation, 5:01](https://developer.apple.com/videos/play/tech-talks/111461/?time=301): system split/tab containers adapt automatically; sidebar placement is optional. Sheets and contextual presentations adapt too.

[Safe areas, 6:06](https://developer.apple.com/videos/play/tech-talks/111461/?time=366): constrain interactive foreground independently on all four sides; backgrounds can bleed beyond insets. Test both Split View positions. Device Hub supports opening, closing, folding, and rotating.

### Raise the bar with iPhone Duo — 111462

[Container eligibility, 2:00](https://developer.apple.com/videos/play/tech-talks/111462/?time=120): use container-managed bars; standalone `UIToolbar`, `UINavigationBar`, and `UITabBar` do not qualify. Only edge-adjacent detail columns participate; expanded inspectors do not gain another vertical bar.

[Ordering, 4:29](https://developer.apple.com/videos/play/tech-talks/111462/?time=269): use cancellation placement for custom Back/Close and pinned trailing placement for prominent actions.

[Content, 5:56](https://developer.apple.com/videos/play/tech-talks/111462/?time=356): provide both symbol and title; title remains useful in menus. Text-only controls stay horizontal. Custom controls need a fitting vertical representation and explicit axis preference. Keep symbol/text-changing actions horizontal; keyboard accessories stay attached to the keyboard.

[Custom views, 10:07](https://developer.apple.com/videos/play/tech-talks/111462/?time=607): inspect the vertical-bar edge, remove manual spacers, and check legibility with Reduce Transparency.

[Overflow, 11:40](https://developer.apple.com/videos/play/tech-talks/111462/?time=700): toolbars compress before tabs by default; task screens may prefer preserving toolbar actions. Prioritize groups before individual items. Keyboard, PiP, and outer landscape increase pressure.

[Exceptions, 14:21](https://developer.apple.com/videos/play/tech-talks/111462/?time=861): disabling vertical bars can suit bottom-heavy single-screen utilities or sheets with one action.

### Strike a pose with adaptive layouts on iPhone Duo — 111463

[Displacement, 2:26](https://developer.apple.com/videos/play/tech-talks/111463/?time=146): move independently usable controls individually and coupled elements together. Preserve context; continuous articles, feeds, documents, and lists should not jump between regions. Book-style alerts favor the trailing region; tabletop content favors the upper region and tappable controls the stable lower region.

[Region queries, 6:39](https://developer.apple.com/videos/play/tech-talks/111463/?time=399): query local division and occlusion regions. Only active regions are returned by default. Including inactive division regions can inform an even-column grid before folding; inactive fold width is zero.

[Arrangements, 9:20](https://developer.apple.com/videos/play/tech-talks/111463/?time=560): inputs include size classes, aspect ratio, and active divisions. A split arrangement fits existing side-by-side or stacked content; overlay fits foreground/background relationships. Split normally follows the longer axis; constraining its axes can cause it to show only one view. Overlay Z-index can drive collapsed/expanded content.

[Composition limits, 16:09](https://developer.apple.com/videos/play/tech-talks/111463/?time=969): put arrangements inside navigation containers and outside scrolling containers. Do not wrap a navigation split view in an arrangement, or put an arrangement inside a `List`/`ScrollView`.

### Leverage multiple displays and scenes on iPhone Duo — 111464

[Hinge, 0:49](https://developer.apple.com/videos/play/tech-talks/111464/?time=49): SwiftUI `onHingeChange` and UIKit `UIHingeInteraction` expose discrete state and continuous angle. A missing hinge is a normal capability result. Use angle for effects or interactions; arrangements and regions remain the layout tools. Reset effects when their activation conditions no longer hold.

[Multitasking, 2:59](https://developer.apple.com/videos/play/tech-talks/111464/?time=179): all apps participate in Duo multitasking; support live geometry changes. Multiple instances can be created on the inner display, but creation is unavailable on the outer display. Handle errors; `UIWindowSceneActivationAction` hides itself when unavailable.

[Accessories, 4:22](https://developer.apple.com/videos/play/tech-talks/111464/?time=262): accessory availability is dynamic. Camera capture accessories can show supplementary outer-display content while the main camera UI occupies the full inner display with an active camera session. Register the accessory with the camera view, observe availability, and reflect it in enable/disable controls. The example is a toggled teleprompter, useful as a pattern for subject-facing content.

### Build a great camera experience for iPhone Duo — 111465

[Camera choice, 0:58](https://developer.apple.com/videos/play/tech-talks/111465/?time=58): front wide/ultrawide discovery returns a virtual front camera that switches automatically. Its shared limit is 1080p/60 fps; physical outer supports up to 4K/120 fps, inner up to 1080p/60 fps. Depth requires physical-camera access.

[Direction, 2:46](https://developer.apple.com/videos/play/tech-talks/111465/?time=166): physical `.front`/`.back` position does not describe which way a camera faces relative to the UI. AVKit's direction coordinator follows a view; use one per displayed view. Forward-facing rear-camera selfies need appropriate mirroring.

[Concurrency, 5:38](https://developer.apple.com/videos/play/tech-talks/111465/?time=338): coordinator callbacks are main-actor isolated. Pass sendable device descriptors to the camera actor rather than doing capture work directly in the callback.

[Preview, 7:03](https://developer.apple.com/videos/play/tech-talks/111465/?time=423): choose full preview versus reserving space for controls; use preview-layer gravity and supported dynamic aspect ratios. Rotation coordination must handle display changes. Once correct, disabling sensor-orientation compensation can improve performance.

### Design for iPhone Duo — 111466

[Design principles, 0:28](https://developer.apple.com/videos/play/tech-talks/111466/?time=28): wider, shorter proportions explain moving controls sideways; the vertical system region includes status and expanding Live Activities. Split View is 50/50. Pinned picture-in-picture resizes the app vertically, and its occupied height changes during folding.

[Adapting, 3:42](https://developer.apple.com/videos/play/tech-talks/111466/?time=222): target size classes, margins, and safe-area geometry rather than screen-specific breakpoints. Optional tabletop experiences must retain ordinary functionality and hierarchy.

[Outer display, 6:33](https://developer.apple.com/videos/play/tech-talks/111466/?time=393): most content centers within the safe area, naturally offset from the controls. An immersive non-scrolling canvas may center on the full display if controls remain clear. Full-width background with inset scrolling foreground is another valid composition.

[Inner display, 7:34](https://developer.apple.com/videos/play/tech-talks/111466/?time=454): expose hierarchy in split views, rearrange stacks into columns, or optionally use sidebars for information-dense apps.

[Sheets, 8:36](https://developer.apple.com/videos/play/tech-talks/111466/?time=516): inner-display sheets use horizontal bars by default. Standard sheets and contextual controls automatically avoid the fold.

## Related design guidance inspected

- [Layout](https://developer.apple.com/design/human-interface-guidelines/layout): reviewed adaptivity, size-class, and safe-area sections. Test all four size-class combinations, intermediate sizes, localization, and large Dynamic Type. Text-size changes may require stacking content and increasing row height. Orientation-locked apps still need resizing.
- [Split views](https://developer.apple.com/design/human-interface-guidelines/split-views): reviewed iOS/iPadOS guidance. Split layouts need sufficient width; ensure logical navigation when panes collapse. Consider drag-and-drop between panes where useful.
- [Designing for iOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-ios): existing iPhone conventions still apply; retain support for appearance, orientation, and text-size choices.
- [Designing for games](https://developer.apple.com/design/human-interface-guidelines/designing-for-games): reviewed UI-adaptivity guidance. Keep menus legible at different aspect ratios, use relative constraints and safe areas, and preserve accessible controls. This generic page's prose and table currently disagree about minimum touch sizes; do not copy a numeric minimum from it without resolving against current Buttons guidance.
- [Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars): inspected grouping and component anatomy as background for Duo's bars.

## Related video coverage

| Title | URL | Transcript coverage | Relevance / limitation |
|---|---|---|---|
| Prepare your app for iPhone Duo | https://developer.apple.com/videos/play/tech-talks/111461/ | Full | SDK adoption, local geometry, safe areas, simulator testing |
| Raise the bar with iPhone Duo | https://developer.apple.com/videos/play/tech-talks/111462/ | Full | Detailed bar eligibility, axes, custom content, overflow |
| Strike a pose with adaptive layouts on iPhone Duo | https://developer.apple.com/videos/play/tech-talks/111463/ | Full | Displacement, reserved regions, arrangement composition |
| Leverage multiple displays and scenes on iPhone Duo | https://developer.apple.com/videos/play/tech-talks/111464/ | Full | Hinge interactions, multiwindow creation, scene accessories |
| Build a great camera experience for iPhone Duo | https://developer.apple.com/videos/play/tech-talks/111465/ | Full | Camera switching, direction, threading, preview/rotation |
| Design for iPhone Duo | https://developer.apple.com/videos/play/tech-talks/111466/ | Full | Design rationale and continuity |
| What's new in SwiftUI | https://developer.apple.com/videos/play/wwdc2026/269/ | Resizability and toolbar portions | Reusable toolbar priority/overflow/pinned actions; remaining document, performance, and interaction sections outside Duo scope |
| Support the Center Stage front camera in your iOS app | https://developer.apple.com/videos/play/wwdc2026/341/ | Full | Supporting square-sensor and recording context; device/format capabilities must be checked on Duo |
| Get to know the new design system | https://developer.apple.com/videos/play/wwdc2025/356/ | Full | Foundation for grouping, symbols, continuity, and concentric geometry |
| iPhone Duo Group Lab — 285 | https://developer.apple.com/videos/play/meet-with-apple/285/ | Complete substantive Q&A via English HLS captions | Web transcript is empty; caption segments recovered from linked video manifest |
| iPhone Duo Group Lab — 286 | https://developer.apple.com/videos/play/meet-with-apple/286/ | Complete substantive Q&A via English HLS captions | Same recovery method; live panel answers sometimes express uncertainty |

### Supporting videos: actionable additions

[SwiftUI toolbar controls, 6:15](https://developer.apple.com/videos/play/wwdc2026/269/?time=375): assign visibility priorities to related actions, move rare actions into system overflow, and reserve pinned trailing placement for an action that needs persistent visibility. This is pre-Duo API groundwork, not a reason to replace adaptive containers. Xcode 27 resizable previews help inspect a continuum of sizes. [Scroll minimization, 7:37](https://developer.apple.com/videos/play/wwdc2026/269/?time=457) introduces `toolbarMinimizeBehavior` for navigation bars; verify interaction with Duo's vertical bars rather than assuming identical behavior.

[Center Stage dynamic aspect ratio, 3:56](https://developer.apple.com/videos/play/wwdc2026/341/?time=236): inspect supported aspect ratios on formats instead of assuming a square sensor exposes every option. The API changes crops without rebuilding the capture session; its completion timestamp identifies the first affected buffer. [Video recording, 11:53](https://developer.apple.com/videos/play/wwdc2026/341/?time=713): movie samples require stable dimensions, so changing the aspect ratio stops `AVCaptureMovieFileOutput` recording. Custom writers need deliberate segmentation. Smart-framing and Center Stage support remain separate, format-dependent capabilities. [Orientation compensation, 9:24](https://developer.apple.com/videos/play/wwdc2026/341/?time=564): validate delivered photo rotation before disabling compensation. This talk predates Duo and discusses other iPhone hardware; its physical-camera limits are not Duo specifications.

[Design-system structure, 6:16](https://developer.apple.com/videos/play/wwdc2025/356/?time=376): express hierarchy through semantic grouping and placement. Remove legacy bar decorations that conflict with system treatment. Related symbols can share a group; text and symbols placed in one undifferentiated group can look like one button. Keep primary completion separate. Put contextual actions with their content, not in persistent global accessories. [Continuity, 13:34](https://developer.apple.com/videos/play/wwdc2025/356/?time=814): retain shared anatomy and core behavior across sizes; use text where a glyph would be ambiguous.

### Group Lab additions and limits

[Lab 285: navigation, 12:16](https://developer.apple.com/videos/play/meet-with-apple/285/?time=736): standard vertical tab bars reveal labels during touch/drag. Recreating position alone misses these interactions. [Accessibility, 29:04](https://developer.apple.com/videos/play/meet-with-apple/285/?time=1744): inspect large Dynamic Type/readable content and Reduce Transparency. [Inner geometry, 44:23](https://developer.apple.com/videos/play/meet-with-apple/285/?time=2663): regular/regular does not imply one immutable arrangement; use actual available width and content needs within that class. [Resizability, 47:13](https://developer.apple.com/videos/play/meet-with-apple/285/?time=2833): the panel says apps linked with iOS 27 cannot opt out of iPhone resizing. [State, 57:10](https://developer.apple.com/videos/play/meet-with-apple/285/?time=3430): app instances share app storage, reinforcing the need to separate per-scene presentation state. WebKit, CoreMotion reference frames, and exact table-surface detection were not authoritatively answered. The panel mentioned an accessory entitlement without identifying it; use current documentation/SDK for that requirement. Its SDK-release predictions are historical remarks, not current installation facts.

[Lab 286: transitions, 3:10](https://developer.apple.com/videos/play/meet-with-apple/286/?time=190): a full-screen app continues on the outer display when closed. In Split View, the system promotes the interacted-with app; reopening may restore the pair or expand the surviving app depending on undisclosed timing. Test state continuity without depending on that heuristic. [SwiftUI identity, 19:22](https://developer.apple.com/videos/play/meet-with-apple/286/?time=1162): switching whole containers with size-class `if` branches can discard state; retain stable containers or lift state ownership. [Camera UX, 29:46](https://developer.apple.com/videos/play/meet-with-apple/286/?time=1786): keep important video-call content near the camera to improve gaze while keeping floating self-preview clear of its active region. [Simulator limits, 43:37](https://developer.apple.com/videos/play/meet-with-apple/286/?time=2617): 27.1 can launch camera apps with no-camera results, but does not validate real capture or simultaneous-display camera behavior. [Idiom, 52:56](https://developer.apple.com/videos/play/meet-with-apple/286/?time=3176): Duo reports phone. Broad panel availability statements should not override precise 27.1 declarations.

## Validation caveats

- Transcript speech sometimes uses an approximate API name. For example, spoken `reservedRegion` differs from the published code's `reservedRegions`; use SDK declarations.
- The bar talk also says `toolbarCompressionBehavior` in speech. Root validation found the real SwiftUI modifier is `toolbarVerticalCompressionBehavior(_:)`, with `.prefersToolbarItems` / `.prefersTabBar`; UIKit uses `navigationItem.verticalBarCompressionBehavior`, with `.prefersBarItems` / `.prefersTabBar`.
- The preparation talk contains nuanced orientation/full-screen compatibility wording. Do not simplify this into either “orientation always locks” or “orientation never matters”; distinguish native adaptive layouts from compatibility scaling.
- These notes verify documented behavior, not physical-device ergonomics or camera performance. All six transcripts were read; no claim is made that every demonstration frame was visually inspected.
