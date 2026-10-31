/*
 * NonGraphicalMain.java
 *
 * Created on November 29, 2003, 11:33 PM
 */

package experiments;

import java.awt.*;
import java.io.*;
import java.util.*;

import shared.PC;
import shared.PhysicsInterface;
import shared.ObstacleContainer;
import shared.Obstacle;
import shared.SquareObstacle;
/**
 *
 * @author  Wesley Kerr
 */
public class KTPhysics
{
   private PhysicsInterface physics;

   /** Creates a new instance of NonGraphicalMain */
   public KTPhysics(String className)
   {
      int[] numParticles =
      { 10000, 12000, 15000 };

      int runs = 3;
      int timeSteps = 30000;

      PC.closed = false;
      PC.physicsClass = className;

      int gridCount = 5;
      int[][] grid = new int[gridCount][gridCount];
      int[][] gridNew = new int[gridCount][gridCount];

      double[][] error = new double[numParticles.length][runs];
      boolean cont = true;

      PC.L = 1e-6;
      PC.length = 1;
      PC.ncell_x = 20;
      PC.ncell_y = 20;
      PC.npart = 10000;
      PC.T = 273;

      try
      {
         String file = "C:\\cygwin\\home\\wkerr\\repos\\FAABSIII\\UniformDistribution\\experiments\\";
         BufferedWriter out = new BufferedWriter(new FileWriter(file + "ktphysicsnormalized.txt"));

         for (int i = 0; i < numParticles.length; ++i)
         {
            PC.npart = numParticles[i];

            for (int j = 0; j < runs; ++j)
            {
               System.out.println("NumParticles " + PC.npart + " Run " + j);
               createPhysics();
               for (int p = 0; p < timeSteps; ++p)
               {
                  physics.timeStep();

                  if (p > (timeSteps - 200))
                  {
                     double[][] x = physics.x;
                     for (int k = 0; k < PC.npart; ++k)
                     {
                        int jx = (int)(x[k][0]*gridCount/PC.L);
                        int jy = (int)(x[k][1]*gridCount/PC.L);
                        if (jx > gridCount)
                        {
                           System.out.println("We have a x loose particle " + k);
                           System.out.println("Position <" + x[k][0] + "," + x[k][1] + ">");
                        }
                        if (jy > gridCount)
                        {
                           System.out.println("We have a y loose particle " + k);
                           System.out.println("Position <" + x[k][0] + "," + x[k][1] + ">");
                        }
                        jx = ( jx < gridCount ) ? jx : gridCount - 1;
                        jy = ( jy < gridCount ) ? jy : gridCount - 1;
                        gridNew[jy][jx] += 1;
                     }
                  }
               }

               for (int k = 0; k < gridCount; ++k)
               {
                  for (int s = 0; s < gridCount; ++s)
                  {
                     gridNew[k][s] /= 200.0;
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

   private void createPhysics()
   {
      try
      {
         physics = (PhysicsInterface) Class.forName(PC.physicsClass).newInstance();
         if (PC.obstaclePath != null)
            physics.setFileName(PC.obstaclePath);
      }
      catch (Exception e)
      {
         System.out.println("ERROR - " + e.getMessage());
         e.printStackTrace();
         System.exit(0);
      }
   }

   /**
    * @param args the command line arguments
    */
   public static void main(String[] args)
   {
      new KTPhysics("ktphysics.CouettePhysics");
   }
}
