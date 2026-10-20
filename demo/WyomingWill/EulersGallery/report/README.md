# Physics fidelity report

`physics-fidelity-report.pdf` describes, for each of the 21 exhibits in
the Gallery, how it is simulated and how it was tested against theory:
the model, a table of checks (theory, the simulation's number, and how well
they agree), the runs used with their console output, and the known
departures and caveats. Section 1 summarises every exhibit; section 2 lists
what the checks found, what was fixed, and what is still open; section 3
gives the methods common to all of them.

Every exhibit was run afresh for it on 15 October 2026, and run again after
the fixes the report describes. Two independent read-throughs checked the
report against the code, the READMEs and fresh runs.

## Files

* `physics-fidelity-report.pdf`: the report.
* `dossiers/<Folder>.md`: one per exhibit, the report's sections 4 and 5
  word for word. Edit these, not the PDF.
* `front.py`: the report's own text: the order of the exhibits, the
  one-line summaries and statuses, the findings and the methods.
* `build.py`: builds the PDF from `front.py` and the dossiers.
* `cmp2.sh`: the hall-identity check: runs an exhibit in the hall and on
  its own and compares everything it prints.
* `gyro-free-test.lua`, `gyro-probe.lua`: the check of Bullet's gyroscopic
  term (20 Oct 2026): its modes on free tumbling bodies against the exact
  motion, and, run around an exhibit, the energy the term makes there
  (the Gömböc, Bille, Slinky and Dzhanibekov dossiers give the numbers).

## Rebuilding

Needs Python 3 with reportlab, and the DejaVu fonts (Ubuntu:
`sudo apt install python3-reportlab fonts-dejavu-core`).

```
cd demo/WyomingWill/EulersGallery/report
python3 build.py              # writes physics-fidelity-report.pdf here
```

When an exhibit changes, re-run its checks (each dossier's "Run used"
gives the commands, with `HOLD_S=0` so the start pause doesn't shift the
frame counts), update its dossier and, if its status or headline changes,
its line in `front.py`, then rebuild.

## Statuses

* **Agrees** (OK): every check agrees with theory to within what the
  model and the step size allow.
* **Agrees, with a caveat** (CAVEAT): it agrees, but something is not
  converged or not explained; section 2.3 lists each one.
* `front.py` also has DOC (the documentation says something the code
  doesn't do) and ISSUE (a problem in the simulation or its checks); none
  is left after the fixes.
