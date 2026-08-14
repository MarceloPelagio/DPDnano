#!/usr/bin/env python3
from pathlib import Path
import shutil

TEST = "hw019"
PY_DIR = Path("python") / TEST
RESULT_DIR = Path("results") / TEST
TOOLS_DIR = Path("tools")

FILES = [
    "dpdnano_hw019_dpd.py",
    "plot_hw019_dpd.py",
    "README_HW019.txt",
]

def move_if_present(src: Path, dst: Path) -> None:
    if not src.exists():
        return

    dst.parent.mkdir(parents=True, exist_ok=True)

    if dst.exists():
        print(f"JÁ EXISTE : {dst}")
        return

    shutil.move(str(src), str(dst))
    print(f"MOVIDO    : {src} -> {dst}")

def main() -> None:
    cwd = Path.cwd()

    if cwd.name.lower() != "src":
        raise SystemExit(
            "Execute este script dentro da pasta /src."
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
        cwd / "organize_hw019.py",
        cwd / TOOLS_DIR / "organize_hw019.py",
    )

    print()
    print("HW019 organizado.")
    print(f"Python    : {PY_DIR}")
    print(f"Resultados: {RESULT_DIR}")
    print("rtl_v3_2  : não alterada")
    print("common/   : não alterada")
    print("Nenhuma síntese é necessária.")

if __name__ == "__main__":
    main()
