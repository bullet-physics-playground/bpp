"""Reference rattleback: rigid half-ellipsoid rolling without slipping on a plane.
Body frame = principal axes, origin at the centre of mass. gamma = world 'up' in
the body frame. Contact point r(gamma) on the ellipsoid with outward normal -gamma.
  dgamma/dt = gamma x omega
  (I + m(|r|^2 1 - r r^T)) domega/dt = -omega x I omega + m r x (rdot x omega + omega x (r x omega)) + m g r x gamma
(no slipping: v = r x omega). Energy is conserved exactly by these equations.
"""
import numpy as np, sys
from scipy.integrate import solve_ivp
A,B,C=6.0,1.5,1.2; RHO=0.0012; g=981.0
def setup(skew_deg):
    m=(2/3)*np.pi*A*B*C*RHO; y0=-3*C/8
    I=np.diag([m*(C*C+B*B)/5-m*y0*y0, m*(A*A+B*B)/5, m*(A*A+C*C)/5-m*y0*y0])
    s=np.radians(skew_deg); R=np.array([[np.cos(s),0,-np.sin(s)],[0,1,0],[np.sin(s),0,np.cos(s)]])
    S=R@np.diag([A*A,C*C,B*B])@R.T          # ellipsoid (x'=A, y=C, z'=B) turned by skew
    c0=np.array([0,-y0,0])                  # ellipsoid centre relative to COM
    return m,I,S,c0
def make_rhs(m,I,S,c0):
    Iinv=None
    def r_of(gm):
        Sg=S@gm; s=np.sqrt(gm@Sg); return c0-Sg/s, Sg, s
    def rhs(t,y):
        gm,w=y[:3],y[3:]
        r,Sg,s=r_of(gm)
        gdot=np.cross(gm,w)
        J=-S/s+np.outer(Sg,Sg)/s**3            # dr/dgamma
        rdot=J@gdot
        K=I+m*((r@r)*np.eye(3)-np.outer(r,r))
        rhs_=-np.cross(w,I@w)+m*np.cross(r,np.cross(rdot,w)+np.cross(w,np.cross(r,w)))+m*g*np.cross(r,gm)
        wdot=np.linalg.solve(K,rhs_)
        return np.r_[gdot,wdot]
    return rhs,r_of
def run(skew,spin,T=30):
    m,I,S,c0=setup(skew); rhs,r_of=make_rhs(m,I,S,c0)
    y0=np.r_[0,1,0, 0.02,spin,0]
    sol=solve_ivp(rhs,[0,T],y0,rtol=1e-10,atol=1e-12,max_step=0.002,dense_output=True)
    tt=np.linspace(0,T,3001); Y=sol.sol(tt); gm=Y[:3]; w=Y[3:]
    gm=gm/np.linalg.norm(gm,axis=0)
    wz=np.sum(w*gm,0)                       # spin about the vertical
    def E(i):
        r=r_of(gm[:,i])[0]; v=np.cross(r,w[:,i])
        return 0.5*m*v@v+0.5*w[:,i]@I@w[:,i]+m*g*(-(r@gm[:,i]))
    return tt,wz,E(0),E(-1),np.degrees(np.arcsin(np.clip(np.abs(gm[2]),0,1))).max(),np.degrees(np.arcsin(np.clip(np.abs(gm[0]),0,1))).max()
if __name__=="__main__":
    for skew in (8,0):
        for spin in (6,-6):
            tt,wz,E0,E1,rock,pitch=run(skew,spin)
            samp=" ".join(f"{wz[np.argmin(abs(tt-T))]:+6.2f}" for T in (0,1,2,4,6,10,15,20,29))
            rev=np.where(np.sign(wz)!=np.sign(wz[0]))[0]
            print(f"skew {skew} spin {spin:+d}: {samp}  first reversal {'%.2f s'%tt[rev[0]] if len(rev) else 'none'}  rock {rock:.1f} pitch {pitch:.1f}  energy drift {E1/E0-1:+.1e}",flush=True)
