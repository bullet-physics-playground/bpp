#!/bin/bash
# Why are 8 threads no faster than 4 (handover/THREADS.md, 10 November)? The 11-walker room (runs/room-speed.sh's
# group 11) with bpp held to chosen CPUs by taskset: four cores sharing one L3 cache (on a Ryzen 3700X, one of its two
# groups of four cores), four split two and two across the caches, eight across both, and four cores with their
# second hardware threads (SMT). If keeping to one cache is what matters, "4, one cache" beats "4, split", and
# "8, one cache + SMT" may beat "8, both caches". The CPU layout is read from lscpu, so it fits any machine.
#
#   cd demo/WyomingWill/WalkerRoom
#   BPP=../../../release/bpp runs/core-groups.sh
#
# About 2 minutes a row; each row twice (body marks on and off, as room-speed.sh). SPLIT_ONLY=1: only the rows
# across two caches.
set -u
cd "$(dirname "$0")/.."
BPP=${BPP:-bpp}
command -v "$BPP" > /dev/null || { echo "bpp not found: set BPP to the bpp program"; exit 1; }
command -v taskset > /dev/null || { echo "taskset not found (util-linux)"; exit 1; }
BPP_ABS=$(cd "$(dirname "$(command -v "$BPP")")" && pwd)/$(basename "$BPP")
# the layout: for each L3 cache, its cores' first CPUs, and their second (SMT) CPUs -- from /sys (each CPU's L3,
# cache/index3/shared_cpu_list, and its core's threads, topology/thread_siblings_list), as lscpu can report one L3
# for a Ryzen's two (it did, 11 November); lscpu if /sys has no L3
layout() {
  local d c l3 sib
  for d in /sys/devices/system/cpu/cpu[0-9]*; do
    c=${d##*cpu}
    l3=$(cat "$d/cache/index3/shared_cpu_list" 2> /dev/null) || return 1
    sib=$(cat "$d/topology/thread_siblings_list")
    echo "$c;$sib;$l3"
  done | sort -t";" -k1,1n
}
LAYOUT=$(layout) || LAYOUT=$(lscpu -p=CPU,CORE,CACHE | grep -v '^#' | awk -F, '{ n = split($3, c, ":"); print $1 ";" $2 ";" c[n] }')
eval "$(echo "$LAYOUT" | awk -F';' '
  { cpu = $1; core = $2; l3 = $3   # (core: its threads, "0,8"; l3: the CPUs sharing it, "0-3,8-11")
    if (!(core in first)) { first[core] = cpu; cores[l3] = cores[l3] " " cpu; if (!(l3 in seen)) { seen[l3] = 1; order[++k] = l3 } }
    else if (!(core in second)) { second[core] = cpu; sib[l3] = sib[l3] " " cpu } }
  END { for (i = 1; i <= k; i++) { printf "C%d=\"%s\"; S%d=\"%s\"\n", i, cores[order[i]], i, sib[order[i]] }
        printf "NGROUPS=%d\n", k }')"
take() { echo $1 | tr " " "\n" | head -"$2" | paste -sd, -; }   # (the first n of a list, as taskset's list)
echo "CPU layout: $NGROUPS L3 cache group(s)"
for i in $(seq 1 "$NGROUPS"); do c=C$i; s=S$i; echo "  group $i: cores' CPUs ${!c}; their second threads: ${!s:-none}"; done
ROWS=()
if [ -z "${SPLIT_ONLY:-}" ]; then
  ROWS+=("4, no taskset||4" "8, no taskset||8")
  ROWS+=("4, one cache|$(take "$C1" 4)|4")
  [ -n "$S1" ] && ROWS+=("4, two cores + their SMT, one cache|$(take "$C1" 2),$(take "$S1" 2)|4")
  [ -n "$S1" ] && ROWS+=("8, four cores + their SMT, one cache|$(take "$C1" 4),$(take "$S1" 4)|8")
fi
if [ "$NGROUPS" -ge 2 ]; then
  ROWS+=("4, split 2 + 2 across two caches|$(take "$C1" 2),$(take "$C2" 2)|4")
  ROWS+=("8, both caches|$(take "$C1" 4),$(take "$C2" 4)|8")
else
  echo "(one L3 cache here: the split rows are left out)"
fi
W=$(mktemp)
trap 'rm -f "$W"' EXIT
printf '| CPUs | taskset | Walkers | Bracing | Timing | Direction | Marks | Threads | Speed |\n| --- | --- | --- | --- | --- | --- | --- | --- | --- |\n'
for row in "${ROWS[@]}"; do
  IFS='|' read -r name cpus n <<< "$row"
  if [ -n "$cpus" ]; then printf '#!/bin/sh\nexec taskset -c %s "%s" "$@"\n' "$cpus" "$BPP_ABS" > "$W"; else printf '#!/bin/sh\nexec "%s" "$@"\n' "$BPP_ABS" > "$W"; fi
  chmod +x "$W"
  BPP="$W" GROUPS_LIST=11 THREADS_LIST="$n" runs/room-speed.sh | tail -n +3 | sed "s/^|/| $name | ${cpus:-all} |/"
done
