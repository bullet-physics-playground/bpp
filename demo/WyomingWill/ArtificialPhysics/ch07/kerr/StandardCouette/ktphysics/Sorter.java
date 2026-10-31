package ktphysics;

/*
 * Sorter.java
 *
 * Created on October 16, 2003, 11:01 PM
 */

import shared.PC;
/**
 *
 * @author  Wesley Kerr
 */
public class Sorter
{

   /** Creates a new instance of Sorter */
   public Sorter()
   {
   }

   public static void sorter(double[][] x, double L, SortList sD)
   {
      // sorter - Function to sort particles into cells
      // Inputs
      //  x       Position of particles
      //  L       System size
      //  sD      Object containing lists used in sorting
      // Output
      //  sD      Object containing lists used in sorting

      // Find the cell address for each particle
      int ncell_x = sD.ncell_x;
      int ncell_y = sD.ncell_y;
      int npart = sD.npart;
      int[][] cellIndex = new int[npart][2];

      for (int i = 0; i < npart; ++i)
      {
         int jx = (int)(x[i][0]*ncell_x/L);
         int jy = (int)(x[i][1]*ncell_y/(PC.length*L));
         cellIndex[i][0] = ( jx < ncell_x ) ? jx : ncell_x - 1;
         if (jy < 0)
            cellIndex[i][1] = 0;
         else
            cellIndex[i][1] = ( jy < ncell_y ) ? jy : ncell_y - 1;
      }

      // Count the number of particles in each cell
      for (int i = 0; i < ncell_y; ++i)
         for (int j = 0; j < ncell_x; ++j)
            sD.cell_n[i][j] = 0;

      for (int i = 0; i < npart; ++i)
      {
         int xIndex = cellIndex[i][0];
         int yIndex = cellIndex[i][1];
         if (xIndex < 0)
            System.out.println("ERROR: X");
         if (yIndex < 0)
            System.out.println("ERROR: Y");
         sD.cell_n[yIndex][xIndex] += 1;
      }

      // Build index list as cumulative sum of the
      // number of particles in each cell
      int m=0;
      for (int i = 0; i < ncell_y; ++i)
      {
         for (int j = 0; j < ncell_x; ++j)
         {
            sD.index[i*ncell_x + j] = m;
            m += sD.cell_n[i][j];
         }
      }

      // Build cross-reference list
      int[] temp =  new int[ncell_y*ncell_x];
      for (int i = 0; i < ncell_y*ncell_x; ++i)
      {
         temp[i] = 0;
      }

      for (int i = 0; i < npart; ++i)
      {
         int jx = cellIndex[i][0];
         int jy = cellIndex[i][1];

         int k = sD.index[jy*ncell_x + jx] + temp[jy*ncell_x + jx];
         sD.Xref[k] = i;
         temp[jy*ncell_x + jx] += 1;
      }
   }
}