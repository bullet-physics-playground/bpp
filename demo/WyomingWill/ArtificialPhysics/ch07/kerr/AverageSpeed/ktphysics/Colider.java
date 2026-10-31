package ktphysics;

/*
 * Colider.java
 *
 * Created on October 18, 2003, 11:33 AM
 */

import shared.MyLong;
import shared.PC;
/**
 *
 * @author  Wesley Kerr
 */
public class Colider
{

   /** Creates a new instance of Colider */
   public Colider()
   {
   }

   /**
    * colide - Function to process collisions in cells
    * Inputs
    *   v        Velocities of the particles
    *   crmax    Estimated maximum relative speed in a cell
    *   tau      Time step
    *   seed     Current random number seed
    *   selxtra  Extra selections carried over from last timestep
    *   coeff    coefficient in computing number of selected pairs
    *   sD       Object containing sortings lists
    * Outputs
    *   v        updated velocities of particles
    *   crmax    Updated maximum relative speed
    *   selxtra  Extra selections carried over to next timestep
    *   col      Total number of collisions processed (Return value)
    */
   public static void colider(double[][] v, double[][] crmax, double tau,
                             double[][] selxtra, double coeff,
                             SortList sD, MyLong seed)
   {
      int ncell_x = sD.ncell_x;
      int ncell_y = sD.ncell_y;

      // Loop over cells, processing collisions in each cell
      //for (int i = 0; i < ncell_y - 1; ++i)
      for (int i = 0; i < ncell_y; ++i)
      {
         for (int j = 0; j < ncell_x; ++j)
         {
            // Skip cells with only one particle
            int number = sD.cell_n[i][j];
            if (number < 2)
               continue;

            // Determine number of candidate collision pairs
            // to be selected in this cell
            double select = coeff*number*number*crmax[i][j] + selxtra[i][j];
            int nsel = (int) select;          // Number of pairs to be selected
            selxtra[i][j] = select - nsel;    // Carry over any left-over fraction
            double crm = crmax[i][j];         // Current maximum relative speed

            // Loop over total number of candidate collision pairs
            int isel;
            for (isel = 0; isel < nsel; ++isel)
            {
               // Pick two particles at random out of this cell
               int k = (int) (PC.rand(seed) * number);
               int kk = ((int) (k+PC.rand(seed)* (number-1))+1) % number;

               int ip1 = sD.Xref[ k + sD.index[i*ncell_x + j] ];   // First particle
               int ip2 = sD.Xref[ kk + sD.index[i*ncell_x + j] ];  // Second particle

               // Calculate pair's relative speed
               double cr = Math.sqrt( Math.pow(v[ip1][0] - v[ip2][0], 2) +
                                      Math.pow(v[ip1][1] - v[ip2][1], 2) );

               if (cr > crm)             // If relative speed larger than crm,
                  crm = cr;             // then reset crm to larger value

               // Accept or reject candidate pair according to relative speed
               if (cr / crmax[i][j] > PC.rand(seed))
               {
                  PC.colSum += 1;
                  if (PC.collectingData)
                  {
                     PC.collisionCount++;
                     PC.colCellCount[i][j]++;
                  }

                  if (PC.collectingData)
                     PC.write(PC.out, v[ip1][0] + "," + v[ip1][1] + "," +
                                      v[ip2][0] + "," + v[ip2][1] + ",");

                  // If Pair accepted, select post-collision velocities
                  double[] vcm = new double[2];
                  double[] vrel = new double[2];
                  // Center of mass velocity
                  vcm[0] = 0.5*(v[ip1][0] + v[ip2][0]);
                  vcm[1] = 0.5*(v[ip1][1] + v[ip2][1]);

                  double cos_th = 1.0 - 2.0*PC.rand(seed);      // Cosine and sine of
                  double sin_th = Math.sqrt(1.0 - cos_th*cos_th); // collision angle theta

                  vrel[0] = cr*cos_th;                            // Compute post-condition
                  vrel[1] = cr*sin_th;                            // relative velocity

                  for (int m = 0; m < 2; ++m)
                  {
                     v[ip1][m] = vcm[m] + 0.5*vrel[m];            // Update post-condition
                     v[ip2][m] = vcm[m] - 0.5*vrel[m];            // velocities
                  }

                  if (PC.collectingData)
                     PC.write(PC.out, v[ip1][0] + "," + v[ip1][1] + "," +
                                      v[ip2][0] + "," + v[ip2][1] + ",");

                  /*if (v[ip1][1] < 0 && v[ip2][1] < 0 && PC.DOWN)
                  {
                     v[ip1][1] *= -1;
                     v[ip2][1] *= -1;
                  }
                  if (v[ip1][1] > 0 && v[ip2][1] > 0 && PC.UP)
                  {
                     if (PC.collectingData)
                        PC.write(PC.changed, ip1 + "\n" + ip2 + "\n");

                     v[ip1][1] *= -1;
                     v[ip2][1] *= -1;
                  }*/

                  if ((v[ip1][1] < 0 || v[ip2][1] < 0) && PC.DOWN)
                  {
                     PC.collisionChanged++;
                     PC.colCellChangedCount[i][j]++;
                  }
                  else if ((v[ip1][1] > 0 || v[ip2][1] > 0) && PC.UP)
                  {
                     PC.collisionChanged++;
                     PC.colCellChangedCount[i][j]++;
                  }

                  if (v[ip1][1] < 0 && PC.DOWN)
                     v[ip1][1] *= -1;
                  if (v[ip2][1] < 0 && PC.DOWN)
                     v[ip2][1] *= -1;

                  if (v[ip1][1] > 0 && PC.UP)
                     v[ip1][1] *= -1;
                  if (v[ip2][1] > 0 && PC.UP)
                     v[ip2][1] *= -1;

                  if (PC.collectingData)
                     PC.write(PC.out, v[ip1][0] + "," + v[ip1][1] + "," +
                                      v[ip2][0] + "," + v[ip2][1] + ",");
               }
               crmax[i][j] = crm;
            }
         }
      }
   }
}
