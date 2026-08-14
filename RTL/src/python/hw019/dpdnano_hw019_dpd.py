#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from pathlib import Path


def read_hw018_csv(path: Path) -> list[dict[str, float]]:
    rows: list[dict[str, float]] = []

    with path.open(
        "r",
        encoding="utf-8",
    ) as csv_file:
        reader = csv.DictReader(csv_file)

        required = {
            "index",
            "input_i",
            "output_i",
            "gain_linear",
            "compression_db",
        }

        if not required.issubset(reader.fieldnames or []):
            missing = required.difference(
                reader.fieldnames or []
            )
            raise RuntimeError(
                "Colunas ausentes no CSV do HW018: "
                + ", ".join(sorted(missing))
            )

        for row in reader:
            rows.append({
                "index": float(row["index"]),
                "input_i": float(row["input_i"]),
                "output_i": float(row["output_i"]),
                "gain_linear": float(row["gain_linear"]),
                "compression_db": float(row["compression_db"]),
            })

    if len(rows) < 3:
        raise RuntimeError(
            "O CSV precisa conter pelo menos três pontos."
        )

    return rows


def derivative_central(
    x_prev: float,
    y_prev: float,
    x_next: float,
    y_next: float,
) -> float:
    delta_x = x_next - x_prev

    if delta_x == 0:
        raise RuntimeError(
            "Dois pontos possuem a mesma entrada."
        )

    return (y_next - y_prev) / delta_x


parser = argparse.ArgumentParser(
    description=(
        "HW019_dpd - calcula o ganho incremental "
        "a partir do CSV do HW018."
    )
)

parser.add_argument(
    "--input-csv",
    default="../../results/hw018/hw018_dpd_compression_p1db.csv",
)

parser.add_argument(
    "--output-dir",
    default="../../results/hw019",
)

args = parser.parse_args()

input_path = Path(args.input_csv)
output_dir = Path(args.output_dir)

if not input_path.exists():
    raise SystemExit(
        f"CSV do HW018 não encontrado: {input_path.resolve()}"
    )

output_dir.mkdir(
    parents=True,
    exist_ok=True,
)

source_rows = read_hw018_csv(input_path)

result_rows: list[dict[str, float]] = []

for index, row in enumerate(source_rows):
    if index == 0:
        delta_x = (
            source_rows[1]["input_i"]
            - source_rows[0]["input_i"]
        )

        incremental_gain = (
            source_rows[1]["output_i"]
            - source_rows[0]["output_i"]
        ) / delta_x

    elif index == len(source_rows) - 1:
        delta_x = (
            source_rows[-1]["input_i"]
            - source_rows[-2]["input_i"]
        )

        incremental_gain = (
            source_rows[-1]["output_i"]
            - source_rows[-2]["output_i"]
        ) / delta_x

    else:
        incremental_gain = derivative_central(
            source_rows[index - 1]["input_i"],
            source_rows[index - 1]["output_i"],
            source_rows[index + 1]["input_i"],
            source_rows[index + 1]["output_i"],
        )

    result_rows.append({
        "index": int(row["index"]),
        "input_i": row["input_i"],
        "output_i": row["output_i"],
        "static_gain": row["gain_linear"],
        "compression_db": row["compression_db"],
        "incremental_gain": incremental_gain,
    })

zero_crossing_input = None
peak_output_input = None
peak_output_value = None

for previous, current in zip(
    result_rows,
    result_rows[1:],
):
    previous_gain = previous["incremental_gain"]
    current_gain = current["incremental_gain"]

    if (
        zero_crossing_input is None
        and previous_gain > 0
        and current_gain <= 0
    ):
        zero_crossing_input = current["input_i"]

peak_row = max(
    result_rows,
    key=lambda row: row["output_i"],
)

peak_output_input = peak_row["input_i"]
peak_output_value = peak_row["output_i"]

minimum_incremental_gain = min(
    row["incremental_gain"]
    for row in result_rows
)

maximum_incremental_gain = max(
    row["incremental_gain"]
    for row in result_rows
)

negative_gain_points = sum(
    1
    for row in result_rows
    if row["incremental_gain"] < 0
)

csv_path = output_dir / "hw019_dpd_incremental_gain.csv"

with csv_path.open(
    "w",
    newline="",
    encoding="utf-8",
) as csv_file:
    writer = csv.DictWriter(
        csv_file,
        fieldnames=list(result_rows[0].keys()),
    )
    writer.writeheader()
    writer.writerows(result_rows)

passed = (
    zero_crossing_input is not None
    and negative_gain_points > 0
    and abs(
        zero_crossing_input
        - peak_output_input
    ) <= 300
)

print(
    "DPDnano-Lite HW019_dpd - Ganho Incremental"
)
print()
print(
    f"CSV de origem             : {input_path.resolve()}"
)
print(
    f"CSV de saída              : {csv_path.resolve()}"
)
print()
print("==============================================")
print("HW019_dpd - RESUMO")
print("==============================================")
print(
    f"Ganho incremental máximo  : "
    f"{maximum_incremental_gain:.6f}"
)
print(
    f"Ganho incremental mínimo  : "
    f"{minimum_incremental_gain:.6f}"
)
print(
    f"Cruzamento por zero       : {zero_crossing_input}"
)
print(
    f"Entrada no pico de saída  : {peak_output_input}"
)
print(
    f"Valor máximo de saída     : {peak_output_value}"
)
print(
    f"Pontos com ganho negativo : {negative_gain_points}"
)
print("==============================================")

if passed:
    print(
        "RESULTADO: PASS - ganho incremental "
        "e ponto de máximo caracterizados"
    )
else:
    print(
        "RESULTADO: FAIL - cruzamento por zero "
        "inconsistente com o pico de saída"
    )
    raise SystemExit(1)
