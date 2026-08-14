#!/usr/bin/env python3
from pathlib import Path
import shutil

PY_DIR = Path("python") / "hw024"
RESULT_DIR = Path("results") / "hw024"
TOOLS_DIR = Path("tools")

FILES = [
    "dpdnano_hw024_dpd.py",
    "plot_hw024_dpd.py",
    "README_HW024.txt",
]


def move_if_present(source, destination):
    if not source.exists():
        return

    destination.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    if destination.exists():
        print(f"JÁ EXISTE : {destination}")
        return

    shutil.move(str(source), str(destination))
    print(f"MOVIDO    : {source} -> {destination}")


def main():
    cwd = Path.cwd()

    if cwd.name.lower() != "src":
        raise SystemExit(
            "Execute dentro da pasta /src."
        )

    PY_DIR.mkdir(parents=True, exist_ok=True)
    RESULT_DIR.mkdir(parents=True, exist_ok=True)
    TOOLS_DIR.mkdir(exist_ok=True)

    for name in FILES:
        move_if_present(
            cwd / name,
            cwd / PY_DIR / name,
        )

    move_if_present(
        cwd / "organize_hw024.py",
        cwd / TOOLS_DIR / "organize_hw024.py",
    )

    print()
    print("HW024 organizado.")
    print("Nenhum arquivo RTL foi alterado.")


if __name__ == "__main__":
    main()
