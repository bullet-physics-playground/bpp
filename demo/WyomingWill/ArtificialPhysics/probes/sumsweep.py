import re, glob, sys
import os
S=os.environ.get('PROBES','.') + '/sweep'
tag=sys.argv[1]
names={0:'all at once',1:'thirds, top first',2:'thirds, bottom first',3:'thirds, random heights',4:'one at a time'}
for law in ['Lennard-Jones','Newtonian']:
  print('==',law)
  for o in range(5):
    row=[]
    for seed in (1,2,3):
      try: L=open(f'{S}/{tag}_{law}_o{o}_s{seed}.log').read()
      except: row.append('-'); continue
      cell=[]
      for t in (90,150,180):
        m=re.search(rf'CUBE t={t} n=(\d+) crashed=(\d+) edges/pt=([\d.]+).*?square angles=(\d+)%',L)
        sh=re.search(rf'SHAPE t={t} .*?bottom up\): ([\d ]+)',L)
        if m: cell.append(f"{m.group(4)}%" + (f" ({m.group(2)} crashed)" if t==180 and m.group(2)!='0' else '') + (f" lv[{sh.group(1).strip()}]" if t==180 and sh else ''))
      row.append(' / '.join(cell))
    print(f"  {names[o]:24s} | " + ' || '.join(row))
