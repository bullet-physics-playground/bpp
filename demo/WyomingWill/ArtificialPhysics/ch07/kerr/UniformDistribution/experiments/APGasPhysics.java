/*
 * NonGraphicalMain.java
 *
 * Created on November 29, 2003, 11:33 PM
 */

package experiments;

import java.awt.*;
import java.io.*;
import java.util.*;

import apgasphysics.Physics;
import shared.PC;
import shared.PhysicsInterface;
import shared.ObstacleContainer;
import shared.Obstacle;
import shared.SquareObstacle;
/**
 *
 * @author  Wesley Kerr
 */
public class APGasPhysics
{
   public int ncell_x = 20;
   public double L = 1e-6;

   /** Creates a new instance of NonGraphicalMain */
   public APGasPhysics()
   {
      int[] numParticles =
      { 120, 170, 230 };

      int runs = 10;
      int timeSteps = 50000;

      int gridCount = 5;
      int[][] gridNew = new int[gridCount][gridCount];

      double[][] error = new double[numParticles.length][runs];

      PC.npart = 500;
      PC.length = 1;
      PC.ncell_x = 20;
      PC.ncell_y = 20;

      try
      {
         String file = "C:\\cygwin\\home\\wkerr\\repos\\FAABSIII\\UniformDistribution\\experiments\\";
         BufferedWriter out = new BufferedWriter(new FileWriter(file + "apgasphysicsnormalized.txt"));
         for (int i = 0; i < numParticles.length; ++i)
         {
            PC.npart = numParticles[i];
            for (int j = 0; j < runs; ++j)
            {
               System.out.println("NumParticles " + PC.npart + " Run " + j);
               Physics physics = new Physics();
               for (int p = 0; p < timeSteps; ++p)
               {
                  for (int k = 0; k < gridCount; ++k)
                  {
                     for (int s = 0; s < gridCount; ++s)
                     {
                        gridNew[k][s] = 0;
                     }
                  }

                  physics.timeStep();

                  double[][] x = physics.x;
                  for (int k = 0; k < PC.npart; ++k)
                  {
                     int jx = (int)(x[k][0]*gridCount/PC.L);
                     int jy = (int)(x[k][1]*gridCount/PC.L);
                     jx = ( jx < gridCount ) ? jx : gridCount - 1;
                     jy = ( jy < gridCount ) ? jy : gridCount - 1;
                     gridNew[jy][jx] += 1;
                  }

               }

               for (int k = 0; k < gridCount; ++k)
               {
                  for (int s = 0; s < gridCount; ++s)
                  {
                     out.write("NumParticles " + PC.npart + " ");
                     out.write("Run " + j + " ");
                     out.write("Gridy " + k + " Gridx " + s + " Value " + gridNew[k][s] + " ");
                     out.write("Theoretical " + (PC.npart / (gridCount*gridCount)) + " ");
                     double errors = gridNew[k][s] - (PC.npart / (gridCount*gridCount));
                     if (errors > 0)
                     {
                        out.write("Error " + errors + "\n");
                        error[i][j] += errors;
                     }
                     else
                     {
                        out.write("Error 0\n");
                     }
                  }
               }

               int maxError = PC.npart - (PC.npart / (gridCount*gridCount));
               out.write("NumParticles " + PC.npart + " ");
               out.write("Run " + j + " ");
               out.write("Error " + error[i][j]/(double)maxError + " ");
               out.write("Theory " + PC.npart / (gridCount*gridCount));
               out.write("\n");
            }
         }

         out.close();
      }
      catch (Exception exp)
      {
         System.out.println("ERROR: " + exp.getMessage());
         exp.printStackTrace();
      }
   }

   /**
    * @param args the command line arguments
    */
   public static void main(String[] args)
   {
      new APGasPhysics();
   }
}
