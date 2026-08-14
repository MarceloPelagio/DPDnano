#!/usr/bin/env python3
from __future__ import annotations
import shutil
from pathlib import Path

TEST_RTL = Path("hw017_dpd")
TEST_PY = Path("python") / "hw017"
TEST_RESULTS = Path("results") / "hw017"
TOOLS = Path("tools")

RTL_FILES = [
    "dpdnano_hw017_dpd_top.v",
    "dpd_controller_hw017_dpd.v",
    "dpdnano_hw017_dpd.cst",
    "dpdnano_hw017_dpd.sdc",
    "README_HW017.txt",
]
PY_FILES = [
    "dpdnano_hw017_dpd.py",
    "plot_hw017_dpd.py",
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

    TEST_RTL.mkdir(exist_ok=True)
    TEST_PY.mkdir(parents=True, exist_ok=True)
    TEST_RESULTS.mkdir(parents=True, exist_ok=True)
    Path("common").mkdir(exist_ok=True)
    TOOLS.mkdir(exist_ok=True)

    for n in range(18, 25):
        Path(f"hw{n:03d}_dpd").mkdir(exist_ok=True)
        (Path("python") / f"hw{n:03d}").mkdir(parents=True, exist_ok=True)
        (Path("results") / f"hw{n:03d}").mkdir(parents=True, exist_ok=True)

    for name in RTL_FILES:
        move_if_present(cwd / name, cwd / TEST_RTL / name)
    for name in PY_FILES:
        move_if_present(cwd / name, cwd / TEST_PY / name)

    move_if_present(cwd / "organize_hw017.py", cwd / TOOLS / "organize_hw017.py")

    print("\nORGANIZAÇÃO HW017 CONCLUÍDA")
    print("rtl_v3_2: PRESERVADA; nenhuma leitura, cópia ou alteração realizada.")
    print("Arquivos comuns existentes em /src não foram movidos para não quebrar o Gowin.")

if __name__ == "__main__":
    main()
