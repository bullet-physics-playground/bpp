import numpy as np, itertools
import rb_ref
def growth(Aa,Bb,Cc,skew,spin,hshift=0.0):
    rb_ref.A,rb_ref.B,rb_ref.C=Aa,Bb,Cc
    m,I,S,c0=rb_ref.setup(skew); c0=c0+np.array([0,hshift,0])   # hshift: move the COM down (+) inside the body
    rhs,_=rb_ref.make_rhs(m,I,S,c0)
    y0=np.r_[0,1,0,0,spin,0]
    # check equilibrium
    f0=rhs(0,y0)
    J=np.zeros((6,6)); h=1e-6
    for k in range(6):
        e=np.zeros(6); e[k]=h; J[:,k]=(rhs(0,y0+e)-rhs(0,y0-e))/(2*h)
    ev=np.linalg.eigvals(J)
    return ev.real.max(), np.abs(f0).max()
print(" A    B    C   skew  hshift | growth +spin  growth -spin")
rows=[]
for Bb,Cc,skew,hs in itertools.product([1.2,1.5,2.0,2.5],[0.8,1.2,1.6,2.0],[3,5,8,12],[0.0,0.3]):
    try:
        gp,_=growth(6.0,Bb,Cc,skew,6,hs); gm,_=growth(6.0,Bb,Cc,skew,-6,hs)
    except Exception as e: continue
    rows.append((Bb,Cc,skew,hs,gp,gm))
# one-way: one direction ~0 (<1e-6), other clearly positive
good=[r for r in rows if (r[4]<1e-6)!=(r[5]<1e-6)]
good.sort(key=lambda r:-max(r[4],r[5]))
for r in good[:15]: print(f" 6.0 {r[0]:4.1f} {r[1]:4.1f} {r[2]:4d}  {r[3]:4.1f}  | {r[4]:10.4f}  {r[5]:10.4f}")
print(len(rows),"shapes;",len(good),"one-way;", sum(1 for r in rows if r[4]>1e-6 and r[5]>1e-6),"two-way;", sum(1 for r in rows if r[4]<1e-6 and r[5]<1e-6),"never reverse at 6 rad/s")
cur=[r for r in rows if r[0]==1.5 and r[1]==1.2 and r[2]==8 and r[3]==0]
print("current design:",cur)
