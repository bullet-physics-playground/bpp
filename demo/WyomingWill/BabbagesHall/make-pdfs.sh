#!/bin/sh
# make-pdfs.sh -- typeset every .md file in the hall as a .pdf beside it.
# Run it whenever a .md file changes (needs: pip install markdown playwright).
set -e
cd "$(dirname "$0")"
pdf() { python3 tools/md2pdf.py "$@"; }
pdf README.md                          --sub "A Victorian hall of machines that compute"
pdf MACHINES.md                        --sub "Every machine considered, ranked by interest"
pdf HANDOFF.md                         --sub "For a new chat: how to work, build, test, and what's next"
pdf exhibits/DominoAdder/README.md     --sub "East bay 2: dominoes that add two bits"
pdf exhibits/DominoAdder/FINDINGS.md   --sub "East bay 2: the Domino Half Adder"
pdf exhibits/Differential/README.md    --sub "West bay 1: bevel gears that add and subtract"
pdf exhibits/Differential/FINDINGS.md  --sub "West bay 1: the Differential"
pdf exhibits/Pascaline/README.md       --sub "West bay 2: Pascal's adding machine (1642)"
pdf exhibits/Pascaline/FINDINGS.md     --sub "West bay 2: the Pascaline"
pdf exhibits/LehmerSieve/README.md     --sub "East bay 1: wheels that sieve for factors"
pdf exhibits/LehmerSieve/FINDINGS.md   --sub "East bay 1: Lehmer's number sieve"
pdf exhibits/DigiComp2/README.md       --sub "West bay 3: balls that compute in binary"
pdf exhibits/DigiComp2/FINDINGS.md     --sub "West bay 3: the Digi-Comp II"
