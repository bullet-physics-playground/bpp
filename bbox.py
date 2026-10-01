import re, numpy as np
def bbox(F, ztol=9):
    txt=open(F).read()
    rat=re.compile(r'<(\s*-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?)\s*,\s*(-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?)\s*,\s*(-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?)\s*>')
    vs=[(float(a),float(b),float(c)) for a,b,c in rat.findall(txt) if abs(float(c))<ztol]
    x=[v[0] for v in vs]; y=[v[1] for v in vs]
    return (min(x),max(x),min(y),max(y),len(vs))
for name,f in [("cross","mesh_9a27766775c96472b978d74087fb88d343fc2010"),
               ("disc","mesh_d2fb24852c5a12c9f1b4f5f799667a445753b483")]:
    print(name, "bbox(xmin,xmax,ymin,ymax,n)=", bbox(f"/home/koppi/bpp/export/11-geneva-drive/{f}.inc"))
