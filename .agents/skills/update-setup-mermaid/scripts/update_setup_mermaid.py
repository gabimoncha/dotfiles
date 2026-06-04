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
    S5["Call bin/install-apps --dry-run"]
    S6["Print setup summary"]
    S7["Exit"]
    S8["Call bin/bootstrap"]
    S9{"Xcode CLT ready after bootstrap?"}
    S10["Exit: finish installer, rerun ./bin/setup"]
    S11["Call bin/install-apps"]
    S12["Call bin/link-dotfiles"]
    S13["Print setup summary"]
    S14{"Interactive terminal?"}
    S15["Skip auth and restore follow-up"]
    S16["Call bin/auth-setup after Enter"]
    S17["Call bin/mackup-restore"]
    S18["Find .rayconfig and call bin/raycast-restore when present"]
    S19["Print shell reload hint"]

    S0 --> S1
    S1 -->|"yes"| S2
    S1 -->|"no"| S3
    S3 --> S4
    S4 -->|"yes"| S5 --> S6 --> S7
    S4 -->|"no"| S8
    S8 --> S9
    S9 -->|"no"| S10
    S9 -->|"yes"| S11 --> S12 --> S13 --> S14
    S14 -->|"no"| S15 --> S19
    S14 -->|"yes"| S16 --> S17 --> S18 --> S19
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
    B1["Verify admin, Xcode CLT, Homebrew, mise"]
    B2["Configure sudo Touch ID unless skipped"]
    B3["Initialize nvim submodule"]
    B4["Call bin/link-dotfiles"]
    B5["Start mise install in background"]
    B6["Install Brewfile, mas apps, VS Code extensions"]
    B7["Call bin/link-dotfiles again after apps exist"]
    B8["Wait for mise and run bin/check-mise-tools"]
    B9["Report mobile-dev setup as deferred"]
    B10["Run setup-tmux, shell framework, macOS defaults, Finder favorites"]
    B11["Bootstrap complete"]

    B1 --> B2 --> B3 --> B4 --> B5 --> B6 --> B7 --> B8 --> B9 --> B10 --> B11
  end

  subgraph InstallApps["bin/install-apps"]
    direction TB
    I1["Read apps/manifest.tsv"]
    I2{"Manifest row type"}
    I3["cask or formula: brew install or dry-run"]
    I4["mise: mise install or dry-run"]
    I5["manual: print vendor instructions"]
    I6["App install pass complete"]

    I1 --> I2
    I2 --> I3 --> I6
    I2 --> I4 --> I6
    I2 --> I5 --> I6
  end

  subgraph MobileDev["bin/install-mobile-dev"]
    direction TB
    MD1["Ensure Homebrew, mise, and xcodes"]
    MD2["Install Android Studio cask"]
    MD3["Install and configure full Xcode"]
    MD4["Install idb-companion and sourcekitten"]

    MD1 --> MD2 --> MD3 --> MD4
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
    A1["Configure local Git identity"]
    A2["Create or reuse SSH key"]
    A3["Authenticate gh and upload key when possible"]
    A4["Verify GitHub SSH"]

    A1 --> A2 --> A3 --> A4
  end

  subgraph MackupRestore["bin/mackup-restore"]
    direction TB
    M1["Use tracked home/.mackup.cfg"]
    M2["Restore allowlisted app settings from iCloud"]

    M1 --> M2
  end

  subgraph RaycastRestore["bin/raycast-restore"]
    direction TB
    R1{"Raycast .rayconfig found in iCloud?"}
    R2["Open newest .rayconfig"]
    R3["Defer Raycast restore"]

    R1 -->|"yes"| R2
    R1 -->|"no"| R3
  end

  S3 -.-> P1
  S5 -.-> I1
  S8 -.-> B1
  S11 -.-> I1
  S12 -.-> L1
  S13 -.->|optional later| MD1
  S16 -.-> A1
  S17 -.-> M1
  S18 -.-> R1

  B4 -.-> L1
  B7 -.-> L1"""


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
