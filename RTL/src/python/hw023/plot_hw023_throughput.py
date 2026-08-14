#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys

subprocess.run(
    [
        sys.executable,
        "plot_hw023_all.py",
    ],
    check=True,
)
