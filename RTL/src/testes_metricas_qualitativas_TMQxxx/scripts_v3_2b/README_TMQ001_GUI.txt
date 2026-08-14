TMQ001 GUI / Waveform Execution
================================

This folder is dedicated to interactive ModelSim usage, separated from
the batch automation scripts in scripts_v3_2.

Recommended PowerShell usage:

1. Open ModelSim with compile + DUT loaded:

   cd C:\ProjetosGithub\TCC_CHIP_DIGITAL\TCC_FINAL\scripts_v3_2b
   vsim -do .\compile_tmq001_dynamic_range_gui.do

2. Run the full testbench with waves and transcript visible:

   cd C:\ProjetosGithub\TCC_CHIP_DIGITAL\TCC_FINAL\scripts_v3_2b
   vsim -do .\run_tmq001_dynamic_range_gui.do

What you will see:

- Transcript window active
- Wave window active
- Recursive wave capture with add wave -r /*
- Full TMQ001 execution
- ModelSim window remains open after simulation

Generated artifacts:

- ../tb_v3_2/tmq001_dynamic_range_samples.csv
- ../tb_v3_2/tmq001_dynamic_range_summary.txt
- ../tb_v3_2/results/TMQ001/tmq001_dynamic_range_stats.csv
- ../tb_v3_2/results/TMQ001/TMQ001_final_report.md

Important:

- The GUI script is for inspection and waveform viewing.
- The GUI run script recompiles the correct test before opening it, so it
  is safe even if the local work library already contains another test.
- The batch script in scripts_v3_2 remains the recommended path for
  fully automated report generation.
