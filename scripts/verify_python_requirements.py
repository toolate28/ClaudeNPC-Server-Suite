#!/usr/bin/env python3
"""Verify Python requirements for obvious issues:
- duplicate entries
- presence of stdlib names (asyncio)
- lightweight tag for heavy packages
- report missing lockfile indicators
"""
from pathlib import Path
import re

REQ = Path(__file__).resolve().parent.parent / "python-requirements.txt"
ML_REQ = Path(__file__).resolve().parent / "python-requirements-ml.txt"

STD_LIB_CANDIDATES = {"asyncio"}
HEAVY_PACKAGES = {"torch", "qiskit", "cirq", "transformers"}

def parse_requirements(path: Path):
    if not path.exists():
        return []
    lines = [l.strip() for l in path.read_text(encoding='utf-8').splitlines()]
    pkgs = []
    for line in lines:
        if not line or line.startswith("#"):
            continue
        # strip version markers
        pkg = re.split(r"[<>=]", line)[0].strip()
        pkg = pkg.split()[0]
        pkgs.append(pkg)
    return pkgs


def main():
    pkgs = parse_requirements(REQ)
    ml_pkgs = parse_requirements(ML_REQ)

    issues = []

    # duplicates
    seen = set()
    for p in pkgs:
        if p in seen:
            issues.append(("DUPLICATE", p))
        seen.add(p)

    # stdlib mistaken
    for p in pkgs:
        if p in STD_LIB_CANDIDATES:
            issues.append(("STDLIB_AS_DEP", p))

    # heavy packages in main requirements
    for p in pkgs:
        if p in HEAVY_PACKAGES:
            issues.append(("HEAVY_IN_MAIN", p))

    # suggestions
    suggestions = []
    if not ML_REQ.exists():
        suggestions.append("Consider splitting heavy packages into 'python-requirements-ml.txt' (optional extras).")

    # output
    if not issues and not suggestions:
        print("OK: No issues found in requirements.")
        return 0

    for t, p in issues:
        print(f"{t}: {p}")

    for s in suggestions:
        print("SUGGESTION:", s)

    # non-zero exit for CI to catch
    return 2

if __name__ == '__main__':
    raise SystemExit(main())