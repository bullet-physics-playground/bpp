
package physicsorig;

public class sampler
{
   public static void sampler2( Matrix x, Matrix v, int npart, double L,
                               SampList sampD ) 
   {
      // sampler - Function to sample density, velocity and temperature
      // Inputs
      //    x       Particle positions
      //    v       Particle velocities
      //    npart   Number of particles
      //    L       System size
      //    sampD   Object with sampling data
      // Outputs
      //    sampD   Structure with sampling data

      //* Compute cell location for each particle
      int ncell = sampD.ncell;
      int[] jx = new int[npart+1];

      int i;
      for( i=1; i<=npart; i++ )	
         jx[i] = (int)Math.ceil(ncell*x.get(i)/L);

      //* Initialize running sums of number, velocity and v^2
      Matrix sum_n = new Matrix(ncell);
      Matrix sum_vx = new Matrix(ncell);
      Matrix sum_vy = new Matrix(ncell);
      Matrix sum_vz = new Matrix(ncell);
      Matrix sum_v2 = new Matrix(ncell);

      sum_n.set(0.0);
      sum_vx.set(0.0);
      sum_vy.set(0.0);
      sum_vz.set(0.0);
      sum_v2.set(0.0);

      //* For each particle, accumulate running sums for its cell
      for( i=1; i<=npart; i++ )	
      {
         int jcell = jx[i];  // Particle i is in cell jcell
         sum_n.inc(jcell, 1.0);
         sum_vx.inc(jcell, v.get(i,1));
         sum_vy.inc(jcell, v.get(i,2));
         sum_vz.inc(jcell, v.get(i,3));

         sum_v2.inc(jcell, v.get(i,1)*v.get(i,1) + 
                           v.get(i,2)*v.get(i,2) + 
                           v.get(i,3)*v.get(i,3));

      }

      //* Use current sums to update sample number, velocity 
      //  and temperature
      for( i=1; i<=ncell; i++ ) 
      {
         sum_vx.set(i, sum_vx.get(i) / sum_n.get(i));
         sum_vy.set(i, sum_vy.get(i) / sum_n.get(i));
         sum_vz.set(i, sum_vz.get(i) / sum_n.get(i));
         sum_v2.set(i, sum_v2.get(i) / sum_n.get(i));

         sampD.ave_n[i] += sum_n.get(i);
         sampD.ave_ux[i] += sum_vx.get(i);
         sampD.ave_uy[i] += sum_vy.get(i);
         sampD.ave_uz[i] += sum_vz.get(i);

         sampD.ave_T[i] += sum_v2.get(i) - (sum_vx.get(i)*sum_vx.get(i) + 
                                            sum_vy.get(i)*sum_vy.get(i) + 
                                            sum_vz.get(i)*sum_vz.get(i));

      }

      sampD.nsamp++;

   }
}