#!/bin/sh
# Fetch the moons' and asteroids' positions from JPL Horizons into
# horizons/<id>.txt: monthly from 2026-01-01 to 2031-01-01, ICRF, AU and
# AU/day, TDB; the moons from their planet's centre, the asteroids from the
# solar system's barycentre. Then run make-data.py, which uses them.
#
#   cd demo/WyomingWill/SolarSystem && sh fetch-horizons.sh && python3 make-data.py
#
# (Takes a minute: one request a second, 27 of them.)
cd "$(dirname "$0")" || exit 1
mkdir -p horizons
get() {   # get ID CENTER
  curl -s -G "https://ssd.jpl.nasa.gov/api/horizons.api" \
    --data-urlencode "format=text" \
    --data-urlencode "COMMAND='$1'" \
    --data-urlencode "OBJ_DATA='NO'" \
    --data-urlencode "MAKE_EPHEM='YES'" \
    --data-urlencode "EPHEM_TYPE='VECTORS'" \
    --data-urlencode "CENTER='$2'" \
    --data-urlencode "START_TIME='2026-01-01'" \
    --data-urlencode "STOP_TIME='2031-01-01'" \
    --data-urlencode "STEP_SIZE='1 MONTHS'" \
    --data-urlencode "VEC_TABLE='2'" \
    --data-urlencode "OUT_UNITS='AU-D'" \
    --data-urlencode "REF_PLANE='FRAME'" \
    --data-urlencode "REF_SYSTEM='ICRF'" \
    --data-urlencode "CSV_FORMAT='YES'" \
    --data-urlencode "VEC_LABELS='NO'" > "horizons/$3.txt"
  if grep -q '\$\$SOE' "horizons/$3.txt"; then echo "  $3 ok"; else echo "  $3 FAILED: see horizons/$3.txt"; fi
  sleep 1
}
echo "moons:"
for m in 401 402; do get $m 500@499 $m; done
for m in 501 502 503 504; do get $m 500@599 $m; done
for m in 601 602 603 604 605 606 608; do get $m 500@699 $m; done
for m in 701 702 703 704 705; do get $m 500@799 $m; done
get 801 500@899 801
get 901 500@999 901
echo "asteroids:"
get "1;" 500@0 2000001
get "2;" 500@0 2000002
get "3;" 500@0 2000003
get "4;" 500@0 2000004
get "10;" 500@0 2000010
