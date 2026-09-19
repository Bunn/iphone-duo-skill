---
name: iphone-duo
description: "Implement, review, or troubleshoot iPhone Duo support in SwiftUI and UIKit apps using researched Apple documentation and verified SDK APIs. Use for Duo layouts, fold and camera regions, vertical bars, hinge interactions, multitasking, and camera accessories; do not rely on older iPhone API knowledge."
license: MIT
---

# iPhone Duo

## New device: do not rely on prior model knowledge

**Treat iPhone Duo as newly introduced Apple hardware whose behavior and APIs you do not already know. Assume your remembered Apple API knowledge is at most Xcode 26.1-era for this task.** This is a conservative working assumption, not a claim about a model's actual training cutoff. Do not dismiss the device or an unfamiliar API as fictional, unavailable, or misspelled solely because you do not recognize it. Do not replace an unfamiliar documented Duo API with an older workaround before checking the evidence.

**Xcode 26.1 is the older knowledge baseline, not the Duo toolchain.** The bundled research verified Duo-specific APIs with **Xcode 27.1 (27A9269), iOS 27.1 SDK**, on **19 September 2026**. Related APIs have different introduction versions, including 26.0 and 27.0. Do not blindly assign every API a 27.1 availability guard or assume a numerically newer beta includes Duo support.

The guide is a dated research snapshot, not permanent proof of current shipping status, SDK support, or unresolved beta behavior. Prefer current official Apple sources and the selected SDK's public declarations to remembered API names or informal video phrasing.

## Read the relevant reference before advising or implementing

Start with [the developer guide](references/iPhone-Duo-Developer-Guide.md), sections **1–2** (device model and availability) and **12** (limitations and contradictions). Then read the sections needed for the request:

| Task | Guide sections | Deeper reference, when needed |
| --- | --- | --- |
| General adoption, UI/UX, state continuity | 3–4, 10–11 | [UX and video notes](references/iphone-duo-research/ux-videos-notes.md) |
| Fold/camera avoidance or arrangements | 5–6 | [Layout API notes](references/iphone-duo-research/layout-api-notes.md) |
| Hinge interaction | 7 | Layout API notes, hinge contract |
| Multiple scenes and display transitions | 8 | Guide's linked scene documentation |
| Camera direction, rotation, subject display | 9 | [Camera API notes](references/iphone-duo-research/camera-notes.md) |
| Release readiness or source verification | 11–14 and appendix | Current linked release notes and API pages |

The consolidated guide is the starting synthesis; supporting notes supply detail. Check current sources when resolving differences instead of silently choosing the convenient claim. Do not load the whole reference archive for a small, unrelated edit.

## Verify the new APIs and the actual toolchain

- Before introducing or changing a Duo API, confirm its exact declaration, framework, OS availability, isolation and relevant behavior in the installed public SDK and/or its current Apple reference. Check both when a discrepancy could affect the implementation. Apple documentation's `.md` endpoints are useful if the rendered page requires JavaScript.
- If a symbol is missing, first check the selected developer directory, SDK version, import and destination/platform. A failure under Xcode 26.1 does not prove a 27.1 API is nonexistent. Do not invent a similarly named method.
- Select the Duo-capable Xcode installation available in the current environment. Set `DUO_XCODE_DIR` to its `Contents/Developer` directory, or use `xcode-select -p` to inspect the currently selected directory. Verify `xcodebuild -version` and `xcrun --sdk iphonesimulator --show-sdk-path` with a command-local `DEVELOPER_DIR`; avoid changing global Xcode selection. The guide includes portable command examples.
- Keep the existing deployment target unless the task calls for changing it. Use symbol-specific availability checks and older-OS fallback behavior. Compile shared Catalyst code for that target separately; runtime guards alone may not resolve unavailable SDK declarations.
- For implementation, typecheck/build the affected code with the intended SDK. If the SDK is unavailable, continue useful source-based work and state what remains uncompiled; do not substitute guessed APIs or report runtime validation.

## Preserve these Duo-specific invariants

- Duo still uses the `.phone` idiom. Layout follows actual size classes, local container bounds, safe areas and margins; a view may be a detail column, sheet, or multitasking scene rather than the full display.
- Preserve navigation, selection, editing, reading/scroll anchors and media state across display transitions. Avoid replacing whole SwiftUI container trees without stable state ownership.
- Use navigation-container-managed bars with semantic placements, meaningful titles/icons and intentional overflow priorities. The preferred vertical-bar edge is not a visibility flag. Verify exact compression API spelling in the guide.
- Use reserved regions for divisions and occlusions, and arrangements for appropriate two-part content. Region frames already include margins. Keep physical coordinates, SwiftUI mirroring and RTL content order consistent. Do not unnecessarily displace continuous scrolling content.
- Arrangement axis restrictions can hide secondary content. Preserve access to that functionality and respect the documented navigation/scroll-container nesting caveats.
- Use hinge input for optional effects/interactions, not angle-based layout thresholds. Handle unavailable/unknown state and effect resets. Do not invent an angle range, zero convention or update rate.
- Camera direction is relative to the preview view, not permanently determined by physical front/back position. Keep capture work in its own isolation context; distinguish accessory availability, enablement and actual presentation.

## Validate and report with the right level of evidence

Adapt the guide's section 11 matrix to the changed feature. Relevant cases include both displays, fold axes, rotations, transitions during interaction, either multitasking side, sheets/keyboard, RTL, accessibility and older-OS fallback. Camera capture and simultaneous camera displays require hardware validation; Simulator and typechecking cannot establish those behaviors.

The bundled [toolbar](references/iphone-duo-research/BarsProbe.swift), [layout/hinge](references/iphone-duo-research/layout-api-examples.swift), [camera/accessory](references/iphone-duo-research/CameraAPIProbe.swift), and [guide examples](references/iphone-duo-research/GuideExamples.swift) are small declaration probes with a historical successful typecheck, not complete apps or production implementations. Read or rerun only the relevant probe; test the actual integration separately.

Keep unresolved items explicit: default reserved-region filtering, arrangement/split nesting wording, accessory entitlement requirements, and beta platform limitations. Recheck the linked current sources when they affect the task; do not invent an entitlement or strengthen a tentative lab answer into a guarantee. Report what changed, which SDK/build was checked, actual test evidence, and any remaining source or hardware uncertainty.
