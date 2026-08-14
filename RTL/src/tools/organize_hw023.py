#!/usr/bin/env python3
from pathlib import Path
import shutil

RTL_DIR = Path("hw023_dpd")
PY_DIR = Path("python") / "hw023"
RESULT_DIR = Path("results") / "hw023"
TOOLS_DIR = Path("tools")

RTL_FILES = [
    "dpdnano_hw023_dpd_top.v",
    "dpd_stress_engine_hw023.v",
    "protocol_controller_hw023_dpd.v",
    "dpdnano_hw023_dpd.cst",
    "dpdnano_hw023_dpd.sdc",
    "README_HW023.txt",
]

PY_FILES = [
    "dpdnano_hw023_dpd.py",
    "plot_hw023_throughput.py",
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

    shutil.move(
        str(source),
        str(destination),
    )

    print(
        f"MOVIDO    : "
        f"{source} -> {destination}"
    )


def main():
    cwd = Path.cwd()

    if cwd.name.lower() != "src":
        raise SystemExit(
            "Execute este script dentro da pasta /src."
        )

    RTL_DIR.mkdir(exist_ok=True)
    PY_DIR.mkdir(parents=True, exist_ok=True)
    RESULT_DIR.mkdir(parents=True, exist_ok=True)
    TOOLS_DIR.mkdir(exist_ok=True)

    for name in RTL_FILES:
        move_if_present(
            cwd / name,
            cwd / RTL_DIR / name,
        )

    for name in PY_FILES:
        move_if_present(
            cwd / name,
            cwd / PY_DIR / name,
        )

    move_if_present(
        cwd / "organize_hw023.py",
        cwd / TOOLS_DIR / "organize_hw023.py",
    )

    print()
    print("HW023 organizado.")
    print("rtl_v3_2 e common não foram alteradas.")


if __name__ == "__main__":
    main()
