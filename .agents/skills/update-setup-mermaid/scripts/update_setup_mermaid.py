#!/usr/bin/env python3
"""Update or check the README setup-flow Mermaid block."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


README_SECTION = "### Step 3: Let setup do the unattended work"


CANONICAL_MERMAID = """flowchart LR
  subgraph Setup["bin/setup"]
    direction TB
    S0["Start"]
    S1{"Running as root?"}
    S2["Exit: rerun without sudo"]
    S3["Call bin/preflight"]
    S4{"--dry-run?"}
    S5["Preview mobile-dev and app installs"]
    S6["Print final actionable summary"]
    S7["Exit"]
    S8["Call bin/bootstrap"]
    S9{"Xcode CLT ready after bootstrap?"}
    S10["Exit: finish installer, rerun ./bin/setup"]
    S11["Call bin/install-apps"]
    S12["Call bin/link-dotfiles"]
    S13["Print manifest summary"]
    S14{"Interactive terminal?"}
    S15["Skip auth and restore follow-up"]
    S16["Call bin/auth-setup after Enter"]
    S17["Call bin/file-restore mackup"]
    S18["Find .rayconfig and call bin/file-restore raycast when present"]
    S19{"Encrypted Codex state archive found?"}
    S20["Prompt and call bin/file-restore codex when approved"]
    S21["Defer Codex restore"]
    S22["Install personal AI skills globally for Claude Code, Cursor, and Codex"]
    S23["Print shell reload hint and final actionable summary"]

    S0 --> S1
    S1 -->|"yes"| S2
    S1 -->|"no"| S3
    S3 --> S4
    S4 -->|"yes"| S5 --> S6 --> S7
    S4 -->|"no"| S8
    S8 --> S9
    S9 -->|"no"| S10
    S9 -->|"yes"| S11 --> S12 --> S13 --> S14
    S14 -->|"no"| S15 --> S22
    S14 -->|"yes"| S16 --> S17 --> S18 --> S19
    S19 -->|"yes"| S20 --> S22
    S19 -->|"no"| S21 --> S22
    S22 --> S23
  end

  subgraph Preflight["bin/preflight"]
    direction TB
    P1["Check macOS, Xcode CLT, Homebrew, GitHub SSH"]
    P2["Check repo files and app manifest"]
    P3["Run syntax checks for setup scripts"]
    P4["Preflight passed"]

    P1 --> P2 --> P3 --> P4
  end

  subgraph Bootstrap["bin/bootstrap"]
    direction TB
    B1["Verify admin, Xcode CLT, Homebrew"]
    B2["Configure sudo Touch ID unless skipped"]
    B3["Initialize nvim submodule"]
    B4["Call bin/link-dotfiles"]
    B5["Call bin/ensure-mise-standalone"]
    B6["Call bin/ensure-codex-standalone"]
    B7["Call bin/ensure-cursor-agent-standalone"]
    B8["Prepare xcodes and aria2, then start Xcode install"]
    B9["Start mise install and run brew bundle"]
    B10["Run Android Studio, MAS apps, and VS Code extensions"]
    B11["Call bin/link-dotfiles again after apps exist"]
    B12["Run iOS platform support and Xcode-dependent formulae"]
    B13["Run setup-tmux, shell framework, macOS defaults, Finder favorites"]
    B14["Bootstrap complete"]

    B1 --> B2 --> B3 --> B4 --> B5 --> B6 --> B7 --> B8 --> B9 --> B10 --> B11 --> B12 --> B13 --> B14
  end

  subgraph InstallApps["bin/install-apps"]
    direction TB
    I1["Read apps/manifest.tsv"]
    I2{"Manifest row type"}
    I3["cask or formula: brew install or dry-run"]
    I4["manual: print vendor instructions"]
    I5["App install pass complete"]

    I1 --> I2
    I2 --> I3 --> I5
    I2 --> I4 --> I5
  end

  subgraph MobileDev["bin/install-mobile-dev"]
    direction TB
    MD1["Ensure standalone mise, xcodes, and aria2"]
    MD2["Install and select full Xcode"]
    MD3["Install Android Studio cask"]
    MD4["Install iOS platform support"]
    MD5["Install applesimutils, idb-companion, and sourcekitten"]

    MD1 --> MD2
    MD1 --> MD3
    MD2 --> MD4
    MD2 --> MD5
  end

  subgraph LinkDotfiles["bin/link-dotfiles"]
    direction TB
    L1["Build managed source list"]
    L2["Add app configs only when app bundles exist"]
    L3["Back up replaced targets"]
    L4["Create symlinks into HOME"]

    L1 --> L2 --> L3 --> L4
  end

  subgraph AuthSetup["bin/auth-setup"]
    direction TB
    A1["Authenticate gh when possible"]
    A2["Configure local Git identity"]
    A3["Create or reuse SSH key"]
    A4["Upload key when possible"]
    A5["Verify GitHub SSH"]

    A1 --> A2 --> A3 --> A4 --> A5
  end

  subgraph MackupRestore["bin/file-restore mackup"]
    direction TB
    M1["Use tracked home/.mackup.cfg"]
    M2["Restore allowlisted app settings from Synology or iCloud"]

    M1 --> M2
  end

  subgraph RaycastRestore["bin/file-restore raycast"]
    direction TB
    R1{"Raycast .rayconfig found in Synology or iCloud?"}
    R2["Open newest .rayconfig"]
    R3["Defer Raycast restore"]

    R1 -->|"yes"| R2
    R1 -->|"no"| R3
  end

  subgraph CodexRestore["bin/file-restore codex"]
    direction TB
    C1["Decrypt age archive"]
    C2["Validate allowlisted paths"]
    C3["Back up replaced targets"]
    C4["Restore curated Codex state"]

    C1 --> C2 --> C3 --> C4
  end

  S3 -.-> P1
  S5 -.-> I1
  S8 -.-> B1
  S11 -.-> I1
  S12 -.-> L1
  S16 -.-> A1
  S17 -.-> M1
  S18 -.-> R1
  S20 -.-> C1

  B4 -.-> L1
  B8 -.-> MD1
  B10 -.-> MD3
  B11 -.-> L1
  B12 -.-> MD4"""


def find_mermaid_block(text: str) -> tuple[int, int, str]:
    section_start = text.find(README_SECTION)
    if section_start == -1:
        raise ValueError(f"Could not find README section: {README_SECTION}")

    fence_start = text.find("```mermaid", section_start)
    if fence_start == -1:
        raise ValueError("Could not find Mermaid fence after setup section")

    content_start = text.find("\n", fence_start)
    if content_start == -1:
        raise ValueError("Mermaid fence has no content")
    content_start += 1

    fence_end = text.find("\n```", content_start)
    if fence_end == -1:
        raise ValueError("Could not find closing Mermaid fence")

    return content_start, fence_end, text[content_start:fence_end]


def replace_mermaid(text: str) -> tuple[str, bool]:
    start, end, current = find_mermaid_block(text)
    wanted = CANONICAL_MERMAID.rstrip()
    if current.rstrip() == wanted:
        return text, False
    return text[:start] + wanted + text[end:], True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--readme", default="README.md", help="README path")
    parser.add_argument("--check", action="store_true", help="fail if the README graph differs")
    parser.add_argument("--write", action="store_true", help="update the README graph in place")
    parser.add_argument("--print", action="store_true", help="print the canonical Mermaid graph")
    args = parser.parse_args()

    if args.print:
        print(CANONICAL_MERMAID)
        return 0

    if args.check == args.write:
        parser.error("choose exactly one of --check or --write")

    readme = Path(args.readme)
    text = readme.read_text()
    updated, changed = replace_mermaid(text)

    if args.check:
        if changed:
            print(f"{readme}: setup Mermaid graph is out of sync", file=sys.stderr)
            return 1
        print(f"{readme}: setup Mermaid graph is current")
        return 0

    if changed:
        readme.write_text(updated)
        print(f"{readme}: updated setup Mermaid graph")
    else:
        print(f"{readme}: setup Mermaid graph already current")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
