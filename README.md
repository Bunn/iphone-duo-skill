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
