#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import math
import serial
import time
from pathlib import Path

SOF_REQ=0xA5
SOF_RSP=0x5A

CMD_PING=0x01
CMD_WRITE_IN=0x20
CMD_READ_OUT=0x31
CMD_START_DPD=0x40
CMD_STATUS=0x41
CMD_COEFS=0x43

COEF1_VALUES=[0.68,0.69,0.70,0.71,0.72]
COEF3_VALUES=[0.18,0.19,0.20,0.21,0.22]
NOMINAL_INDEX=2

def checksum(values):
    result=0
    for value in values:
        result ^= value
    return result & 0xFF

def frame(command,address,data):
    body=[
        SOF_REQ,command,
        (address>>8)&0xFF,address&0xFF,
        (data>>24)&0xFF,(data>>16)&0xFF,
        (data>>8)&0xFF,data&0xFF,
    ]
    return bytes(body+[checksum(body)])

def transact(uart,command,address,data):
    uart.reset_input_buffer()
    uart.write(frame(command,address,data))
    uart.flush()

    response=uart.read(9)

    if len(response)!=9:
        raise RuntimeError("Resposta incompleta ou timeout")

    if response[0]!=SOF_RSP:
        raise RuntimeError("SOF inválido")

    if checksum(response[:8])!=response[8]:
        raise RuntimeError("Checksum inválido")

    return (
        response[1],
        (response[2]<<8)|response[3],
        (response[4]<<24)|(response[5]<<16)|
        (response[6]<<8)|response[7],
    )

def signed16(value):
    value &= 0xFFFF
    return value-0x10000 if value&0x8000 else value

def pack_iq(i_value,q_value=0):
    return ((i_value&0xFFFF)<<16)|(q_value&0xFFFF)

def unpack_iq(word):
    return signed16(word>>16),signed16(word)

def wait_done(uart,timeout_s=3.0):
    deadline=time.time()+timeout_s

    while time.time()<deadline:
        _,_,status=transact(
            uart,
            CMD_STATUS,
            0,
            0,
        )

        busy=status&0x01
        error=(status>>2)&0x01
        overflow=(status>>3)&0x01
        coef1_index=(status>>4)&0x07
        coef3_index=(status>>7)&0x07

        if error:
            raise RuntimeError(
                "Controlador DPD sinalizou erro"
            )

        if not busy:
            return overflow,coef1_index,coef3_index

        time.sleep(0.005)

    raise RuntimeError(
        "Timeout esperando processamento DPD"
    )

def select_coefficients(
    uart,
    coef1_index,
    coef3_index,
):
    data=(coef3_index<<4)|coef1_index

    command,address,response=transact(
        uart,
        CMD_COEFS,
        0,
        data,
    )

    if command!=CMD_COEFS or address!=0:
        raise RuntimeError(
            "Falha ao selecionar coeficientes"
        )

    return response

def run_curve(
    uart,
    family,
    curve_index,
    coef1_index,
    coef3_index,
    coef1_value,
    coef3_value,
    vectors,
):
    select_coefficients(
        uart,
        coef1_index,
        coef3_index,
    )

    for index,input_i in enumerate(vectors):
        response=transact(
            uart,
            CMD_WRITE_IN,
            index,
            pack_iq(input_i),
        )

        if response!=(CMD_WRITE_IN,index,0):
            raise RuntimeError(
                f"Falha na escrita do endereço {index}"
            )

    if transact(
        uart,
        CMD_START_DPD,
        0,
        len(vectors),
    )!=(CMD_START_DPD,0,len(vectors)):
        raise RuntimeError(
            "Falha no START_DPD"
        )

    overflow,active_coef1,active_coef3=wait_done(
        uart
    )

    if (
        active_coef1!=coef1_index
        or active_coef3!=coef3_index
    ):
        raise RuntimeError(
            "Coeficientes ativos divergentes"
        )

    rows=[]

    for index,input_i in enumerate(vectors):
        command,address,word=transact(
            uart,
            CMD_READ_OUT,
            index,
            0,
        )

        if command!=CMD_READ_OUT or address!=index:
            raise RuntimeError(
                f"Leitura inválida no endereço {index}"
            )

        output_i,output_q=unpack_iq(word)

        rows.append({
            "family":family,
            "curve_index":curve_index,
            "coef1_index":coef1_index,
            "coef3_index":coef3_index,
            "coef1":coef1_value,
            "coef3":coef3_value,
            "index":index,
            "input_i":input_i,
            "output_i":output_i,
            "output_q":output_q,
            "overflow":int(overflow),
        })

    return rows

def add_metrics(
    family_rows,
    nominal_rows,
):
    nominal_by_index={
        int(row["index"]):row
        for row in nominal_rows
    }

    differences=[]

    for row in family_rows:
        nominal=nominal_by_index[int(row["index"])]
        delta=float(row["output_i"])-float(
            nominal["output_i"]
        )

        row["delta_output_lsb"]=delta
        differences.append(delta)

    abs_values=[
        abs(value)
        for value in differences
    ]

    return {
        "mean_abs_delta_lsb":(
            sum(abs_values)/len(abs_values)
        ),
        "max_abs_delta_lsb":max(abs_values),
        "mean_signed_delta_lsb":(
            sum(differences)/len(differences)
        ),
    }

parser=argparse.ArgumentParser(
    description=(
        "HW021_dpd - sensibilidade a pequenas "
        "variações de coef1 e coef3"
    )
)

parser.add_argument("--port",required=True)
parser.add_argument(
    "--points",
    type=int,
    default=256,
)
parser.add_argument(
    "--max-amplitude",
    type=int,
    default=28000,
)
parser.add_argument(
    "--output-dir",
    default="../../results/hw021",
)

args=parser.parse_args()

if not 32<=args.points<=256:
    raise SystemExit(
        "--points deve estar entre 32 e 256"
    )

output_dir=Path(args.output_dir)
output_dir.mkdir(
    parents=True,
    exist_ok=True,
)

vectors=[
    round(
        index*args.max_amplitude/(args.points-1)
    )
    for index in range(args.points)
]

all_rows=[]
summary=[]

with serial.Serial(
    args.port,
    115200,
    timeout=2.0,
    write_timeout=1.0,
) as uart:
    time.sleep(0.1)

    print(
        "DPDnano-Lite HW021_dpd - "
        "Sensibilidade aos Coeficientes"
    )
    print(f"Pontos por curva : {args.points}")
    print("Curvas coef1     : 5")
    print("Curvas coef3     : 5")
    print(f"Amostras totais : {args.points*10}")
    print()

    if transact(
        uart,
        CMD_PING,
        0,
        0,
    )!=(CMD_PING,0,0):
        raise RuntimeError("Falha no PING")

    coef1_curves=[]

    for index,coef1_value in enumerate(
        COEF1_VALUES
    ):
        rows=run_curve(
            uart=uart,
            family="coef1",
            curve_index=index,
            coef1_index=index,
            coef3_index=NOMINAL_INDEX,
            coef1_value=coef1_value,
            coef3_value=COEF3_VALUES[NOMINAL_INDEX],
            vectors=vectors,
        )

        coef1_curves.append(rows)

    coef3_curves=[]

    for index,coef3_value in enumerate(
        COEF3_VALUES
    ):
        rows=run_curve(
            uart=uart,
            family="coef3",
            curve_index=index,
            coef1_index=NOMINAL_INDEX,
            coef3_index=index,
            coef1_value=COEF1_VALUES[NOMINAL_INDEX],
            coef3_value=coef3_value,
            vectors=vectors,
        )

        coef3_curves.append(rows)

coef1_nominal=coef1_curves[NOMINAL_INDEX]
coef3_nominal=coef3_curves[NOMINAL_INDEX]

for family,curves,nominal in (
    ("coef1",coef1_curves,coef1_nominal),
    ("coef3",coef3_curves,coef3_nominal),
):
    previous_max_output=None

    for rows in curves:
        metrics=add_metrics(
            rows,
            nominal,
        )

        maximum_output=max(
            int(row["output_i"])
            for row in rows
        )

        monotonic_between_curves=True

        if previous_max_output is not None:
            monotonic_between_curves=(
                maximum_output>=previous_max_output
            )

        previous_max_output=maximum_output

        first=rows[0]

        summary.append({
            "family":family,
            "curve_index":first["curve_index"],
            "coef1":first["coef1"],
            "coef3":first["coef3"],
            "mean_abs_delta_lsb":metrics[
                "mean_abs_delta_lsb"
            ],
            "max_abs_delta_lsb":metrics[
                "max_abs_delta_lsb"
            ],
            "mean_signed_delta_lsb":metrics[
                "mean_signed_delta_lsb"
            ],
            "maximum_output":maximum_output,
            "overflow":max(
                int(row["overflow"])
                for row in rows
            ),
            "monotonic_between_curves":int(
                monotonic_between_curves
            ),
        })

        all_rows.extend(rows)

curves_csv=(
    output_dir
    /"hw021_dpd_sensitivity_curves.csv"
)

with curves_csv.open(
    "w",
    newline="",
    encoding="utf-8",
) as csv_file:
    writer=csv.DictWriter(
        csv_file,
        fieldnames=list(all_rows[0].keys()),
    )
    writer.writeheader()
    writer.writerows(all_rows)

summary_csv=(
    output_dir
    /"hw021_dpd_sensitivity_summary.csv"
)

with summary_csv.open(
    "w",
    newline="",
    encoding="utf-8",
) as csv_file:
    writer=csv.DictWriter(
        csv_file,
        fieldnames=list(summary[0].keys()),
    )
    writer.writeheader()
    writer.writerows(summary)

overflow_count=sum(
    int(row["overflow"])
    for row in summary
)

monotonic_failures=sum(
    1
    for row in summary
    if not int(row["monotonic_between_curves"])
)

maximum_delta=max(
    float(row["max_abs_delta_lsb"])
    for row in summary
)

print()
print("==============================================")
print("HW021_dpd - RESUMO")
print("==============================================")

for row in summary:
    print(
        f"{row['family']:5s} "
        f"coef1={float(row['coef1']):.2f} "
        f"coef3={float(row['coef3']):.2f} "
        f"Δmédio={float(row['mean_abs_delta_lsb']):8.3f} "
        f"Δmáx={float(row['max_abs_delta_lsb']):8.3f} LSB"
    )

print("----------------------------------------------")
print(f"Curvas avaliadas          : {len(summary)}")
print(f"Ocorrências de overflow   : {overflow_count}")
print(f"Falhas de ordenação       : {monotonic_failures}")
print(f"Maior diferença observada : {maximum_delta:.3f} LSB")
print(f"CSV de curvas             : {curves_csv.resolve()}")
print(f"CSV de resumo             : {summary_csv.resolve()}")
print("==============================================")

passed=(
    overflow_count==0
    and monotonic_failures==0
    and maximum_delta>0
)

if passed:
    print(
        "RESULTADO: PASS - sensibilidade gradual "
        "e previsível validada"
    )
else:
    print(
        "RESULTADO: FAIL - comportamento "
        "inesperado na variação dos coeficientes"
    )
    raise SystemExit(1)
