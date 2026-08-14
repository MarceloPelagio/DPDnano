#!/usr/bin/env python3
from pathlib import Path
import shutil

RTL_DIR=Path("hw021_dpd")
PY_DIR=Path("python")/"hw021"
RESULT_DIR=Path("results")/"hw021"
TOOLS_DIR=Path("tools")

RTL_FILES=[
    "dpdnano_hw021_dpd_top.v",
    "dpd_controller_hw021_dpd.v",
    "protocol_controller_hw021_dpd.v",
    "dpdnano_hw021_dpd.cst",
    "dpdnano_hw021_dpd.sdc",
    "README_HW021.txt",
]

PY_FILES=[
    "dpdnano_hw021_dpd.py",
    "plot_hw021_coef1.py",
    "plot_hw021_coef3.py",
]

def move(src,dst):
    if not src.exists():
        return
    dst.parent.mkdir(parents=True,exist_ok=True)
    if dst.exists():
        print(f"JÁ EXISTE : {dst}")
        return
    shutil.move(str(src),str(dst))
    print(f"MOVIDO    : {src} -> {dst}")

def main():
    cwd=Path.cwd()

    if cwd.name.lower()!="src":
        raise SystemExit("Execute dentro da pasta /src.")

    RTL_DIR.mkdir(exist_ok=True)
    PY_DIR.mkdir(parents=True,exist_ok=True)
    RESULT_DIR.mkdir(parents=True,exist_ok=True)
    TOOLS_DIR.mkdir(exist_ok=True)

    for name in RTL_FILES:
        move(cwd/name,cwd/RTL_DIR/name)

    for name in PY_FILES:
        move(cwd/name,cwd/PY_DIR/name)

    move(cwd/"organize_hw021.py",cwd/TOOLS_DIR/"organize_hw021.py")

    print()
    print("HW021 organizado.")
    print("rtl_v3_2 e common não foram alteradas.")

if __name__=="__main__":
    main()
