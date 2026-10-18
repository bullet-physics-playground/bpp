import numpy as np
from eq import equilibria
rows=[(2,25,-0.00051277,(49.799,49.799,80.402)),(3,8,-0.0061413,(30.273,30.273,46.543,72.912)),
      (4,5,-0.015354,(19.716,19.716,29.875,44.519,66.173)),(5,4,-0.029972,(13.494,13.494,20.336,29.781,43.215,59.680)),
      (7,3,-0.042695,(7.1815,7.1815,10.7864,15.6392,22.1409,30.9129,43.0793,43.0788))]
for n,k,zt,ang in rows:
    a=list(ang)[::-1][:n]           # alpha_1..alpha_n
    th=0;r=1;P=[]
    for ai in a:
        th+=np.radians(ai); r*=np.cos(np.radians(ai)); P.append((r*np.sin(th),r*np.cos(th)))
    zc_eq8=(1+k*sum(z for _,z in P))/(1+n*k)
    zc_eq8_k2=(1+2*sum(z for _,z in P))/(1+2*n)
    res=[]
    for apo in (False,True):
        V=[(0,0,1.0)]
        for x,z in P:
            R=x/np.cos(np.pi/k) if apo else x
            for j in range(k): V.append((R*np.cos(2*np.pi*j/k),R*np.sin(2*np.pi*j/k),z))
        V=np.array(V); st,un,_=equilibria(V,V.mean(0)); res.append((len(st),len(un)))
    print(f"(n,k)=({n},{k}) v={1+n*k}: table z_C {zt:+.6f} | eq.(8) with k={k}: {zc_eq8:+.6f} | with k=2: {zc_eq8_k2:+.6f} | equilibria vertices-on-spiral {res[0]}, edge-midpoints-on-spiral {res[1]}")
