#!/usr/bin/env python3
from pathlib import Path
import shutil

RTL_DIR=Path("hw020_dpd")
PY_DIR=Path("python")/"hw020"
RESULT_DIR=Path("results")/"hw020"
TOOLS_DIR=Path("tools")

RTL_FILES=[
    "dpdnano_hw020_dpd_top.v",
    "dpd_controller_hw020_dpd.v",
    "protocol_controller_hw020_dpd.v",
    "dpdnano_hw020_dpd.cst",
    "dpdnano_hw020_dpd.sdc",
    "README_HW020.txt",
]
PY_FILES=[
    "dpdnano_hw020_dpd.py",
    "plot_hw020_maps.py",
    "plot_hw020_curves.py",
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
    move(cwd/"organize_hw020.py",cwd/TOOLS_DIR/"organize_hw020.py")

    print("HW020 organizado; rtl_v3_2 e common preservadas.")

if __name__=="__main__":
    main()
