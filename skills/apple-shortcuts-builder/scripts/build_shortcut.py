#!/usr/bin/env python3
"""Build and optionally sign an Apple Shortcuts .shortcut file from JSON."""

from __future__ import annotations

import argparse
import json
import plistlib
import shutil
import subprocess
import sys
import uuid
from pathlib import Path
from typing import Any


DEFAULT_ICON = {
    "WFWorkflowIconGlyphNumber": 59511,
    "WFWorkflowIconStartColor": 463140863,
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", required=True, type=Path, help="Shortcut config JSON")
    parser.add_argument("--unsigned-output", required=True, type=Path, help="Unsigned .shortcut path")
    parser.add_argument("--signed-output", type=Path, help="Signed .shortcut path")
    parser.add_argument("--mode", default="anyone", choices=["anyone", "people-who-know-me"])
    return parser.parse_args()


def load_config(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        config = json.load(handle)
    if not isinstance(config, dict):
        raise ValueError("Config root must be an object")
    if "name" not in config:
        raise ValueError("Config must include a shortcut name")
    if "actions" not in config and "raw_actions" not in config:
        raise ValueError("Config must include actions or raw_actions")
    return config


def action_uuid() -> str:
    return str(uuid.uuid4()).upper()


def normalize_action(action: Any) -> dict[str, Any]:
    if isinstance(action, str):
        action = {"id": action}
    if not isinstance(action, dict):
        raise ValueError(f"Action must be an object or string: {action!r}")

    if "WFWorkflowActionIdentifier" in action:
        raw = dict(action)
        params = dict(raw.get("WFWorkflowActionParameters") or {})
        params.setdefault("UUID", action_uuid())
        raw["WFWorkflowActionParameters"] = params
        return raw

    action_id = action.get("id") or action.get("identifier")
    if not action_id:
        raise ValueError(f"Action missing id: {action!r}")

    params = dict(action.get("params") or {})
    params.setdefault("UUID", action.get("uuid") or action_uuid())
    return {
        "WFWorkflowActionIdentifier": action_id,
        "WFWorkflowActionParameters": params,
    }


def build_shortcut(config: dict[str, Any]) -> dict[str, Any]:
    actions_source = config.get("raw_actions", config.get("actions", []))
    actions = [normalize_action(action) for action in actions_source]

    icon = dict(DEFAULT_ICON)
    icon.update(config.get("icon") or {})

    return {
        "WFWorkflowActions": actions,
        "WFWorkflowClientRelease": str(config.get("client_release", "2.0")),
        "WFWorkflowClientVersion": str(config.get("client_version", "2700.0.4")),
        "WFWorkflowHasOutputFallback": bool(config.get("has_output_fallback", False)),
        "WFWorkflowIcon": icon,
        "WFWorkflowImportQuestions": config.get("import_questions", []),
        "WFWorkflowInputContentItemClasses": config.get("input_content_item_classes", []),
        "WFWorkflowMinimumClientVersion": int(config.get("minimum_client_version", 900)),
        "WFWorkflowMinimumClientVersionString": str(config.get("minimum_client_version_string", "900")),
        "WFWorkflowName": str(config["name"]),
        "WFWorkflowOutputContentItemClasses": config.get("output_content_item_classes", []),
        "WFWorkflowTypes": config.get("workflow_types", []),
    }


def write_unsigned(shortcut: dict[str, Any], output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("wb") as handle:
        plistlib.dump(shortcut, handle, fmt=plistlib.FMT_XML, sort_keys=False)


def sign_shortcut(unsigned: Path, signed: Path, mode: str) -> None:
    shortcuts = shutil.which("shortcuts")
    if not shortcuts:
        raise RuntimeError("macOS shortcuts CLI not found in PATH")

    signed.parent.mkdir(parents=True, exist_ok=True)
    proc = subprocess.run(
        [
            shortcuts,
            "sign",
            "--mode",
            mode,
            "--input",
            str(unsigned),
            "--output",
            str(signed),
        ],
        text=True,
        capture_output=True,
        check=False,
    )

    if proc.stderr:
        print(proc.stderr, file=sys.stderr, end="")
    if proc.stdout:
        print(proc.stdout, end="")
    if proc.returncode != 0:
        raise RuntimeError(f"shortcuts sign failed with exit code {proc.returncode}")
    if not signed.exists() or signed.stat().st_size == 0:
        raise RuntimeError("shortcuts sign did not create a nonempty signed file")


def main() -> int:
    args = parse_args()
    config = load_config(args.config)
    shortcut = build_shortcut(config)
    write_unsigned(shortcut, args.unsigned_output)
    print(f"unsigned: {args.unsigned_output}")

    if args.signed_output:
        sign_shortcut(args.unsigned_output, args.signed_output, args.mode)
        print(f"signed: {args.signed_output}")

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)
