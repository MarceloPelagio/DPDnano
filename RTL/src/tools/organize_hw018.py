#!/usr/bin/env python3
from pathlib import Path
import shutil

TEST = "hw018"
RTL_DIR = Path("hw018_dpd")
PY_DIR = Path("python") / TEST
RESULT_DIR = Path("results") / TEST
TOOLS_DIR = Path("tools")

RTL_FILES = [
    "dpdnano_hw018_dpd_top.v",
    "dpd_controller_hw018_dpd.v",
    "dpdnano_hw018_dpd.cst",
    "dpdnano_hw018_dpd.sdc",
    "README_HW018.txt",
]

PY_FILES = [
    "dpdnano_hw018_dpd.py",
    "plot_hw018_dpd.py",
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
        raise SystemExit("Execute este script dentro da pasta /src.")

    RTL_DIR.mkdir(exist_ok=True)
    PY_DIR.mkdir(parents=True, exist_ok=True)
    RESULT_DIR.mkdir(parents=True, exist_ok=True)
    TOOLS_DIR.mkdir(exist_ok=True)

    for name in RTL_FILES:
        move_if_present(cwd / name, cwd / RTL_DIR / name)

    for name in PY_FILES:
        move_if_present(cwd / name, cwd / PY_DIR / name)

    move_if_present(cwd / "organize_hw018.py", cwd / TOOLS_DIR / "organize_hw018.py")

    print()
    print("HW018 organizado.")
    print(f"RTL       : {RTL_DIR}")
    print(f"Python    : {PY_DIR}")
    print(f"Resultados: {RESULT_DIR}")
    print("rtl_v3_2  : não alterada")
    print("common/   : reutilizada, sem movimentações")

if __name__ == "__main__":
    main()
