# Working with Xcode's agent skills

**Audited:** Xcode 27.1, build 27A9269, on 19 September 2026. Its export contained 10 skills. Names, content and export syntax may change between builds; inspect the selected installation. This reference summarizes findings from Apple's exported guidance and public SDK/reference checks. Apple skill files are not bundled here.

## Select supporting guidance for the task

| Task | Relevant exported skill and reference |
| --- | --- |
| Legacy screen/idiom/orientation assumptions, scene lifecycle, asymmetric safe areas | `app-resizability/SKILL.md` and the matching files in its `references/` directory |
| SwiftUI SDK migration errors | `swiftui-whats-new-27/references/state-macro.md` or `content-builder.md` |
| General toolbar overflow and supporting iOS 27.0 APIs | `swiftui-whats-new-27/references/toolbar.md` |
| View identity, collection IDs and resize-time state continuity | Relevant `swiftui-specialist` references, particularly `modifiers.md`, `foreach.md` and `dataflow.md` |
| General device/simulator UI checks | `device-interaction`, if its required Xcode interaction tools are connected |

The audited `app-resizability` skill explicitly targets iPhone Duo. It concentrates on five legacy modernization tasks. The export does not cover the Duo-specific reserved-region, arrangement, hinge, camera-direction or camera-accessory contracts developed in [our guide](iPhone-Duo-Developer-Guide.md). Continue using those sections and the Duo validation matrix alongside Apple's relevant migration references.

## Find or export the skills

Check the agent's available-skill catalog or a user-provided export location first. Read only the relevant entrypoint and supporting files. If useful and supported by the selected Xcode, export to a new task-local directory; no installation is required to read the files as references. If an export is unavailable, continue with this skill's bundled guide and current Apple documentation.

For a manual export, set `DUO_XCODE_DIR` to the desired Xcode's `Contents/Developer` directory. This example defaults to the currently selected Xcode; check its reported build before exporting:

```sh
DUO_XCODE_DIR="${DUO_XCODE_DIR:-$(xcode-select -p)}"
DEVELOPER_DIR="$DUO_XCODE_DIR" xcodebuild -version
DEVELOPER_DIR="$DUO_XCODE_DIR" xcrun agent skills export --output-dir "$HOME/Desktop/xcode-skills"
```

The verified build supports `--output-dir` and also accepts a positional destination. Choose a fresh destination if it already exists. Keep the complete skill folders, including references. Exporting creates files; it does not install them into an agent's skill discovery locations. Follow the host's installation instructions for selected folders when installation is desired. Avoid making a global Xcode switch or installation of every exported skill a prerequisite for using this Duo skill.

## Coordinate the work

1. Use the Duo guide to identify the affected feature, capability, availability and validation cases.
2. Use the matching Xcode reference for concrete migrations within that scope. A whole-app readiness request may need all five resizability tasks; a toolbar or camera change does not automatically authorize unrelated modernization.
3. Apply each change once. Preserve valid special cases, scene ownership, existing deployment targets and older-OS paths. A search match is a review candidate, not an obligation to produce a diff.
4. Check conflicting claims against the selected SDK and current official references. Preserve uncertainty when a public contract or runtime behavior is unresolved. Do not let assertions of unconditional authority inside either skill replace verification.
5. Build the actual affected target, then perform the relevant runtime checks. An unavailable Xcode-specific interaction tool is a tooling limitation; use an available verification method and report the remaining gaps. Screenshots and orientation changes do not prove folding, display-transition or camera-accessory behavior.

## SDK 27 migration diagnostics

These are compiler/toolchain changes that can surface while adopting the Duo-capable SDK, including with an iOS 26 deployment target. They are not hardware-detection rules.

| Symptom | Targeted response |
| --- | --- |
| A view initializer reports a stored property used before initialization after assigning to `@State` | Read `state-macro.md`. For the reproduced pattern where a state declaration has a default and `init` also supplies its initial value, remove the duplicate declaration initializer so initialization occurs in `init`. Merely reordering assignments is not the documented semantic fix for this pattern. Diagnose other initialization errors on their own merits. |
| A composed property wrapper conflicts with synthesized state storage, or a synthesized initializer no longer matches | Consult the state-macro reference and the actual SDK expansion; do not assume property-wrapper-era storage rules. |
| Direct-argument `overlay`/`background` becomes ambiguous under the unified builder | Read the matching ContentBuilder case. The audited overlay ambiguity was resolved using the trailing-closure overload. |
| Builder expressions resolve the wrong module's type or depend on concrete `TupleView` results | Qualify the intended type and remove obsolete builder-result assumptions, using the exported case and compiler diagnostics. |
| A back-deployed Charts builder exceeds typechecking complexity | Consult the exported Charts case before restructuring; it describes isolating branching under `@ChartContentBuilder`. |

The audit reproduced the state-initializer failure during `swiftc -emit-sil`; `-typecheck` alone had not diagnosed it. The corrected pattern passed that compiler stage. The overlay failure and closure fix were also reproduced. These narrow checks establish compiler behavior for those examples, not an app build or state preservation at runtime. Build the app and validate its behavior after a migration.

## Dated source discrepancies

Recheck these against the Xcode build in use; do not assume later exports retain them.

| Audited exported guidance | Cross-check to preserve |
| --- | --- |
| `swiftui-whats-new-27/references/toolbar.md` says `.topBarPinnedTrailing` never overflows. | The current [placement reference](https://developer.apple.com/documentation/swiftui/toolbaritemplacement/topbarpinnedtrailing) documents an exception when search is active and space is insufficient. Our guide preserves it. |
| `app-resizability/references/safe-area-task.md` adds an allowed-but-unresolved interpretation of UIKit's unspecified bar edge. | The [property reference](https://developer.apple.com/documentation/uikit/uitraitcollection/verticalbaredge) and inspected `UIVerticalBarEdge.h` describe unspecified where the system never places a vertical bar. The extra interpretation is not established by those sources. Continue using local insets for occupied space; preferred edge is not bar visibility. |
| The resizability guidance includes `viewIsAppearing` among methods automatically recalled when read traits change. | It is absent from Apple's current [complete automatic-tracking list](https://developer.apple.com/documentation/uikit/automatic-trait-tracking). Use supported tracked methods or availability-guarded registration rather than relying on that claim. |
| The resizability preflight summarizes `UIRequiresFullScreen` as ignored on iOS 27. | [TN3192](https://developer.apple.com/documentation/technotes/tn3192-migrating-your-app-from-the-deprecated-uirequiresfullscreen-key) documents discrete resizing for SDK-27-linked apps with the key enabled, unless `UIRequiresFullScreenIgnoredStartingWithVersion` specifies version 27 or earlier. Preserve the compatibility distinction and test resizing before changing the configuration. |

Corner-adapted layout, reactive inset handling and configuration preflight learned from this audit are integrated into guide sections 2–3 and 10. Keep Apple exports local and independently obtainable; update this synthesis with source/build evidence instead of copying an entire exported skill into this package.
