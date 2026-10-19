"""convert the gallery's p37 (variety-reconstruction/shell_6_6.npy) to w37 parameters (mm, base at z=0)"""
import numpy as np
p=np.array([0.48898821241033874, 0.46790273352159495, 0.3621156954277158, 0.22625983680394274, 0.17189453833121324, 0.13186858348180042, 0.2904855537432778, -0.05105104485041603, -0.21176638257544322, -0.290998812982591, -0.29720073630509536, -0.2989810273228082])
def gallery_x(Hmm=90.0):
    R=p[:6][::-1]; Z=p[6:][::-1]; z0=Z[0]; H=1.0-z0
    s=Hmm/H
    return np.r_[R*s, (Z[1:]-z0)*s, H*s]
if __name__=="__main__":
    print(gallery_x().round(3).tolist())
