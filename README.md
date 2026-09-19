# iPhone Duo Skill

Give your coding agent practical iPhone Duo knowledge for **SwiftUI and UIKit**: adaptive UI, fold and camera regions, vertical bars, hinge interactions, multitasking, and camera APIs.

The skill combines a sourced developer guide with an implementation workflow and small Swift API probes. It tells agents to treat Duo as newly introduced hardware, assume remembered APIs are at most **Xcode 26.1-era**, and verify unfamiliar symbols against current Apple documentation and a Duo-capable SDK. The research was checked with **Xcode 27.1 (27A9269)** on **19 September 2026**.

[Read the developer guide](skills/iphone-duo/references/iPhone-Duo-Developer-Guide.md) · [Read the skill](skills/iphone-duo/SKILL.md) · [Contribute](CONTRIBUTING.md)

## Install

### Codex: paste this into a conversation

```text
$skill-installer install the iphone-duo skill from https://github.com/Bunn/iphone-duo-skill/tree/main/skills/iphone-duo
```

If the skill does not appear, restart Codex. Then invoke it with `$iphone-duo` or select **iPhone Duo** in the skill picker. See the [official Codex skills documentation](https://learn.chatgpt.com/docs/build-skills) for discovery and installation behavior.

### Skills CLI: choose your agent

With Node.js installed, run:

```sh
npx skills add Bunn/iphone-duo-skill --skill iphone-duo
```

The [Skills CLI](https://github.com/vercel-labs/skills) lets you select the agent and installation scope. For a personal Codex installation across projects:

```sh
npx skills add Bunn/iphone-duo-skill --skill iphone-duo --agent codex --global
```

Omit `--global` to install for the current project. Use `npx skills list --global` to inspect personal installations.

### Manual installation

This repository uses the open [Agent Skills format](https://agentskills.io/specification). Install the entire [`skills/iphone-duo`](skills/iphone-duo) folder using your agent's skill installer; keep `references/` alongside `SKILL.md`.

For a manual Codex installation, download or clone this repository and copy `skills/iphone-duo` into `~/.agents/skills/` for personal use, or your app repository's `.agents/skills/` for a shared project skill. Back up an existing `iphone-duo` folder before replacing it. Some older Codex installations use `$CODEX_HOME/skills` (typically `~/.codex/skills`); the built-in installer handles its configured destination. Install one copy in the location your client uses.

Installing the skill requires no Xcode, account credentials, MCP server, or background service. Building and testing an iOS app requires a suitable Apple development environment.

## Use with Xcode's skills (optional)

`iphone-duo` works on its own. Xcode's bundled Apple-authored skills can add layout modernization, SwiftUI migration, and UI testing guidance. This comparison covers the export inspected from **Xcode 27.1 (27A9269) on 19 September 2026**; recheck the contents of other builds.

| Skill | Coverage in the inspected material | Use alongside `iphone-duo` |
| --- | --- | --- |
| This repository's `iphone-duo` | Duo-specific reserved regions, arrangement containers, vertical bars, hinge input, cameras, availability, and validation | Coordinates Duo feature work and identifies checks that need hardware |
| Apple's `app-resizability` | Explicit Duo preparation through local geometry, orientation, scene lifecycle, safe areas, and idiom modernization | Audit relevant layout assumptions and configuration before adding Duo features |
| Apple's `swiftui-whats-new-27` | General SDK 27 SwiftUI changes, including toolbars, state macros, and result builders | Investigate affected APIs and compiler migration errors |
| Apple's `swiftui-specialist` | SwiftUI identity, state, composition, localization, and performance | Preserve state and sound view structure as layouts adapt |
| Apple's `device-interaction` | Device/simulator screenshots, UI hierarchy, touch, and orientation checks through Xcode's tools | Verify ordinary UI behavior when those tools are available |

The inspected Apple export does not cover the Duo reserved-region, arrangement, hinge, or camera APIs described here. Its device-interaction guidance does not establish folding, inner/outer display transitions, or simultaneous camera-display behavior. The [working-together guide](skills/iphone-duo/references/working-with-xcode-skills.md) explains task selection, verification, and known source disagreements.

### Export from your Xcode installation

Set `DUO_XCODE_DIR` to the selected Xcode's `Contents/Developer` directory, then check its version before exporting:

```sh
DUO_XCODE_DIR="/Applications/Xcode.app/Contents/Developer"
DEVELOPER_DIR="$DUO_XCODE_DIR" xcodebuild -version
DEVELOPER_DIR="$DUO_XCODE_DIR" \
  xcrun agent skills export --output-dir "$HOME/Desktop/xcode-skills"
```

This export command was verified with the build above. `DEVELOPER_DIR` applies only to each command; it does not change global Xcode selection. Use a destination that does not already exist and preserve earlier exports when refreshing. If another build behaves differently, inspect `xcrun agent skills export --help` using the same `DEVELOPER_DIR`.

**Exporting creates files; it does not install or activate them in your agent.** Inspect the exported `SKILL.md` files, then use your agent's skill installer to install only the folders relevant to your work, including their `references/` directories. Choose project or personal scope deliberately and back up any existing skill before replacing it. Apple's files are optional, are not redistributed in this repository, and retain their own terms. Exporting `device-interaction` does not supply the Xcode tools it expects.

For example, run the Skills CLI from your app repository to inspect the export and install two selected skills for Codex in that project:

```sh
npx skills add "$HOME/Desktop/xcode-skills" --list
npx skills add "$HOME/Desktop/xcode-skills" \
  --skill app-resizability swiftui-whats-new-27 --agent codex
```

Review the installer's destinations and any replacement warnings before confirming. Omit skills you do not need; use another agent's identifier if appropriate.

After installing the selected skills, a focused Codex prompt could be:

```text
$iphone-duo $app-resizability Improve this app's reader-and-notes screen
for Duo. Check its local geometry, safe areas, and state continuity.
Keep changes scoped to this feature and preserve the minimum OS target.
Verify relevant claims against current Apple documentation and the SDK,
then report build, simulator, and remaining hardware checks separately.
```

Select additional SwiftUI or device-interaction guidance only when the task needs it. Use your agent's equivalent skill-selection syntax where necessary.

## Use it

Open your app project and try:

```text
$iphone-duo Audit this app for iPhone Duo support. Inspect navigation,
layout assumptions, state continuity, toolbars, and presentations.
Identify the changes needed and verify the relevant SDK declarations.
```

```text
$iphone-duo Add an adaptive reader-and-notes layout for Duo. Preserve
the reading position and existing minimum OS support. Build the changed
code with the Duo-capable Xcode installation and report what was tested.
```

```text
$iphone-duo Review this camera flow for view-relative camera direction
and the outer-display capture accessory. Separate SDK validation from
the behavior that needs physical hardware testing.
```

In agents with different invocation syntax, select `iphone-duo` through that agent's skill interface.

## What it covers

| Area | Guidance |
| --- | --- |
| UI and UX | Inner/outer display continuity, local geometry, safe areas, accessibility, RTL, and state preservation |
| Navigation and bars | Vertical bars, semantic placements, overflow priorities, and sheets |
| Layout APIs | Reserved regions, fold/camera avoidance, and arrangement containers |
| Interaction and scenes | Hinge input, resizing, multitasking, and scene lifecycle |
| Cameras | Direction relative to the preview, concurrency, rotation, and capture accessories |
| Compatibility and validation | Per-symbol availability, older-OS fallbacks, Catalyst caveats, and a reusable test matrix |

The guide follows Apple's preparation overview, its **50 direct documentation references**, six Duo Tech Talks, two linked WWDC sessions, two Group Labs researched through captions, and selected supporting sources. It links the official sources and preserves unresolved documentation conflicts. See [research coverage](skills/iphone-duo/references/iPhone-Duo-Developer-Guide.md#14-research-coverage-and-source-catalog) for the exact scope.

## Evidence and limits

This is a dated research snapshot. Recheck current Apple documentation, the actual SDK declarations, and the selected toolchain before implementing or shipping. **Xcode 26.1 is the skill's conservative knowledge baseline, not the toolchain that supports Duo.** Related APIs have different introduction versions; the skill does not apply one availability guard to everything.

The four Swift files are declaration/typechecking probes, not complete sample apps. Passing a typecheck does not validate runtime behavior. Camera capture and simultaneous camera displays require physical hardware testing. The guide records beta limitations and source disagreements explicitly.

This is an independent community project, not an official Apple or OpenAI product. Apple documentation and videos remain at their original sources; this repository contains an original synthesis and examples.

## Maintain and validate

Run the package checks with Python 3:

```sh
python3 scripts/validate.py
```

GitHub Actions runs the same checks on pushes and pull requests. They validate package structure and local references; they do not check Apple's live website or compile Swift. See [CONTRIBUTING.md](CONTRIBUTING.md) for source updates and SDK validation.

## License

Original repository content is available under the [MIT License](LICENSE). Linked Apple documentation, videos, trademarks, and other third-party materials remain subject to their respective owners' terms.
