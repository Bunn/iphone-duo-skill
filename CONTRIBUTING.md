# Contributing

Corrections backed by current Apple documentation, SDK declarations, and reproducible tests are welcome. Keep the installable skill self-contained under `skills/iphone-duo/`.

## Update the research

1. Read the relevant guide section and section 12, which records unresolved contracts and beta limitations.
2. Verify the claim in a current official Apple source and, for API spelling or availability, the public declarations of the selected SDK. Include the exact source URL, date, Xcode build, SDK, and destination where relevant.
3. Update the consolidated guide first, then any affected supporting notes and probes. Distinguish Apple's contract from engineering advice. Preserve historical validation dates; add new evidence without implying older tests covered it.
4. Keep the skill's new-device warning and Xcode 26.1 knowledge baseline. A missing symbol in an older SDK is not evidence that a Duo API does not exist. Treat the baseline as a conservative assumption, not a claim about every model's training cutoff.
5. Describe remaining uncertainty. A successful typecheck is not a simulator run or a physical-device test. Do not turn a tentative lab answer into a guarantee.

Summarize sources in your own words and link to Apple. Do not add full transcripts, scraped documentation archives, proprietary SDK headers, signing material, or personal machine paths.

When refreshing the [Xcode skills comparison](skills/iphone-duo/references/working-with-xcode-skills.md), export into a new directory with a command-local `DEVELOPER_DIR` and record the date and exact Xcode build. Recheck the selected skills, source disagreements, and relevant SDK probes before changing the dated comparison. Keep the Duo skill standalone and preserve existing personal installations during validation. Summarize and link evidence; do not redistribute Apple's exported skill files in this repository.

## Validate the package

From the repository root:

```sh
python3 scripts/validate.py
git diff --check
```

The package check uses only the Python standard library and runs in GitHub Actions. It checks this repository's simple metadata format, required resources, portable paths, and relative Markdown file links. It does not validate live URLs or Apple's API behavior.

For an installation smoke check, copy `skills/iphone-duo` into an empty temporary skill directory and confirm that `SKILL.md` and all relative references remain available. Avoid replacing your working personal skill during validation. A GitHub install check should use the contributor's fork and branch until the pull request is merged.

## Validate API changes

Use a Duo-capable Xcode installation and a command-local `DEVELOPER_DIR`. Set `DUO_XCODE_DIR` to its `Contents/Developer` directory; do not change global Xcode selection. Record `xcodebuild -version`, the SDK, target triple, and exact command used.

The bundle contains four probes. Adapt the example typecheck command in guide section 11 for the relevant file and deployment target:

- [Toolbar declarations](skills/iphone-duo/references/iphone-duo-research/BarsProbe.swift)
- [Layout and hinge declarations](skills/iphone-duo/references/iphone-duo-research/layout-api-examples.swift)
- [Camera and accessory declarations](skills/iphone-duo/references/iphone-duo-research/CameraAPIProbe.swift)
- [Guide examples](skills/iphone-duo/references/iphone-duo-research/GuideExamples.swift)

Typecheck changed examples with the intended SDK and deployment target. Then validate relevant integration behavior in an app. Use the [guide's test matrix](skills/iphone-duo/references/iPhone-Duo-Developer-Guide.md#11-validation-matrix), and identify tests that still require hardware. GitHub's ordinary Linux package check cannot validate Duo APIs.

## Report a correction

Open an issue with the affected section or symbol, expected behavior, current source link, and reproduction details. For a pull request, explain the concrete correction and evidence. Keep installation instructions focused, and keep the skill readable without loading every reference for every task.
