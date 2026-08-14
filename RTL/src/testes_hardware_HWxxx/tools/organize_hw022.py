#!/usr/bin/env python3
from pathlib import Path
import shutil
RTL=Path('hw022_dpd'); PY=Path('python')/'hw022'; RES=Path('results')/'hw022'; TOOLS=Path('tools')
rtl_files=['dpdnano_hw022_dpd_top.v','dpd_temporal_engine_hw022.v','protocol_controller_hw022_dpd.v','dpdnano_hw022_dpd.cst','dpdnano_hw022_dpd.sdc','README_HW022.txt']
py_files=['dpdnano_hw022_dpd.py','plot_hw022_latency.py','plot_hw022_timeline.py']
def mv(src,dst):
    if src.exists() and not dst.exists(): dst.parent.mkdir(parents=True,exist_ok=True); shutil.move(str(src),str(dst)); print(f'{src} -> {dst}')
def main():
    if Path.cwd().name.lower()!='src': raise SystemExit('Execute dentro de /src')
    RTL.mkdir(exist_ok=True); PY.mkdir(parents=True,exist_ok=True); RES.mkdir(parents=True,exist_ok=True); TOOLS.mkdir(exist_ok=True)
    for n in rtl_files: mv(Path(n),RTL/n)
    for n in py_files: mv(Path(n),PY/n)
    mv(Path('organize_hw022.py'),TOOLS/'organize_hw022.py')
    print('HW022 organizado; rtl_v3_2 e common preservadas.')
if __name__=='__main__': main()
