#!/usr/bin/env python3
"""Check this skill package with Python 3.9+, no dependencies, network, or Xcode.

Metadata deliberately uses a small YAML subset: single-line string values,
with JSON-style double quoting when needed. This is not a general YAML parser.
Markdown checks cover inline and reference-style file links, not URL availability
or heading anchors. Swift probes are checked for presence, not compiled here.
"""

import json
import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parents[1]
SKILL_PATH = Path("skills/iphone-duo")
REFERENCES = (
    "references/iPhone-Duo-Developer-Guide.md",
    "references/working-with-xcode-skills.md",
    "references/iphone-duo-research/layout-api-notes.md",
    "references/iphone-duo-research/camera-notes.md",
    "references/iphone-duo-research/ux-videos-notes.md",
    "references/iphone-duo-research/BarsProbe.swift",
    "references/iphone-duo-research/layout-api-examples.swift",
    "references/iphone-duo-research/CameraAPIProbe.swift",
    "references/iphone-duo-research/GuideExamples.swift",
)
PERSONAL_PATH = re.compile(r"/Users/|/home/|/private/var/folders/|[A-Za-z]:[\\/]Users[\\/]")
INLINE_LINK = re.compile(r"!?\[[^\]\n]*\]\(\s*(<[^>\n]+>|[^\s)]+)")
REFERENCE_LINK = re.compile(r"^ {0,3}\[[^\]\n]+\]:\s*(<[^>\n]+>|\S+)", re.MULTILINE)


def string_fields(lines, *, indent=0):
    """Read this repository's restricted string-only metadata convention."""
    fields = {}
    for line in lines:
        if not line.strip():
            continue
        match = re.fullmatch(r" {%d}([a-z][a-z0-9_-]*): (.+)" % indent, line)
        if not match:
            raise ValueError("use single-line string fields with the expected indentation")
        key, raw = match.groups()
        if key in fields:
            raise ValueError(f"duplicate field: {key}")
        if raw.startswith('"'):
            try:
                value = json.loads(raw)
            except json.JSONDecodeError as error:
                raise ValueError(f"{key}: use a JSON-style quoted string") from error
        elif re.fullmatch(r"[A-Za-z][A-Za-z0-9 _.,;()/+-]*", raw):
            value = raw
        else:
            raise ValueError(f"{key}: use a plain string or JSON-style double quotes")
        if not isinstance(value, str) or not value.strip():
            raise ValueError(f"{key}: expected a nonempty string")
        fields[key] = value
    return fields


def prose_only(text):
    """Remove fenced and inline code before examining Markdown links."""
    lines = []
    fence = None
    for line in text.splitlines():
        marker = re.match(r"^ {0,3}(`{3,}|~{3,})", line)
        if marker:
            run = marker.group(1)
            if fence is None:
                fence = run
            elif run[0] == fence[0] and len(run) >= len(fence):
                fence = None
            lines.append("")
        elif fence is None:
            lines.append(re.sub(r"(`+).*?\1", "", line))
        else:
            lines.append("")
    return "\n".join(lines)


def local_links(text):
    prose = prose_only(text)
    for pattern in (INLINE_LINK, REFERENCE_LINK):
        for match in pattern.finditer(prose):
            target = match.group(1).strip("<>")
            parsed = urlsplit(target)
            if parsed.scheme or parsed.netloc or not parsed.path:
                continue
            yield unquote(parsed.path)


def validate(root):
    errors = []
    skill = root / SKILL_PATH
    required = [Path(name) for name in ("README.md", "LICENSE", "CONTRIBUTING.md")]
    required += [SKILL_PATH / name for name in ("SKILL.md", "LICENSE", "agents/openai.yaml", *REFERENCES)]
    for relative in required:
        path = root / relative
        if not path.is_file() or not path.read_bytes().strip():
            errors.append(f"{relative}: required file is missing or empty")

    skill_file = skill / "SKILL.md"
    if skill_file.is_file():
        content = skill_file.read_text(encoding="utf-8")
        lines = content.splitlines()
        try:
            if not lines or lines[0] != "---":
                raise ValueError("start with a YAML frontmatter delimiter (---)")
            closing = lines.index("---", 1)
            fields = string_fields(lines[1:closing])
            if not {"name", "description"}.issubset(fields):
                raise ValueError("frontmatter needs name and description")
            if fields["name"] != skill.name:
                raise ValueError(f"name must match the directory: {skill.name}")
            if len(fields["description"]) > 1024:
                raise ValueError("description must be at most 1024 characters")
            if not any(line.strip() for line in lines[closing + 1:]):
                raise ValueError("skill instructions are empty")
        except ValueError as error:
            errors.append(f"{SKILL_PATH}/SKILL.md: {error}")
        linked = set(local_links(content))
        for reference in REFERENCES:
            if reference not in linked:
                errors.append(f"{SKILL_PATH}/SKILL.md: missing link to {reference}")

    metadata = skill / "agents/openai.yaml"
    if metadata.is_file():
        try:
            lines = metadata.read_text(encoding="utf-8").splitlines()
            if not lines or lines[0] != "interface:":
                raise ValueError("start with the interface: mapping")
            fields = string_fields(lines[1:], indent=2)
            if not {"display_name", "short_description"}.issubset(fields):
                raise ValueError("interface needs display_name and short_description")
            if set(fields) - {"display_name", "short_description", "default_prompt"}:
                raise ValueError("unsupported interface field; extend this validator when adding metadata")
            if not 25 <= len(fields["short_description"]) <= 64:
                raise ValueError("short_description must be 25–64 characters")
        except ValueError as error:
            errors.append(f"{SKILL_PATH}/agents/openai.yaml: {error}")

    skipped = {".git", ".venv", "node_modules", "__pycache__"}
    for path in sorted(root.rglob("*")):
        relative = path.relative_to(root)
        if skipped.intersection(relative.parts) or not path.is_file():
            continue
        if path.suffix.lower() not in {".md", ".swift", ".yaml", ".yml"}:
            continue
        content = path.read_text(encoding="utf-8")
        for number, line in enumerate(content.splitlines(), 1):
            if PERSONAL_PATH.search(line):
                errors.append(f"{relative}:{number}: replace personal-machine paths with portable paths")
        if path.suffix.lower() != ".md":
            continue
        # An installed skill must work without files from its source repository.
        boundary = skill.resolve() if path.is_relative_to(skill) else root.resolve()
        for target in local_links(content):
            resolved = (path.parent / target).resolve()
            if not resolved.is_relative_to(boundary):
                errors.append(f"{relative}: link leaves the package: {target}")
            elif not resolved.exists():
                errors.append(f"{relative}: missing local link target: {target}")
    return errors


def main():
    errors = validate(ROOT)
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        print(f"Validation failed: {len(errors)} error(s).", file=sys.stderr)
        return 1
    print("Package validation passed (metadata, bundled references, local links, portable paths).")
    print("External URLs and Swift compilation are not checked.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
