#!/bin/sh
# make-pdfs.sh -- typeset every .md file in the hall as a .pdf beside it.
# Run it whenever a .md file changes (needs: pip install markdown playwright).
set -e
cd "$(dirname "$0")"
pdf() { python3 tools/md2pdf.py "$@"; }
pdf README.md                          --sub "A Victorian hall of machines that compute"
pdf MACHINES.md                        --sub "Every machine considered, ranked by interest"
pdf exhibits/DominoAdder/README.md     --sub "East bay 2: dominoes that add two bits"
pdf exhibits/DominoAdder/FINDINGS.md   --sub "East bay 2: the Domino Half Adder"
pdf exhibits/Differential/README.md    --sub "East bay 1: bevel gears that add and subtract"
pdf exhibits/Differential/FINDINGS.md  --sub "East bay 1: the Differential"
pdf exhibits/Pascaline/README.md       --sub "West bay 2: Pascal's adding machine (1642)"
pdf exhibits/Pascaline/FINDINGS.md     --sub "West bay 2: the Pascaline"
