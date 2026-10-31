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
   public final double boltz = 1.3806e-23;  // Boltzmann's constant (J/K)
   public double mass = 6.63e-26;     // Mass of argon atom (kg)

   private PhysicsInterface physics;

   /** Creates a new instance of NonGraphicalMain */
   public KTPhysics(String className)
   {
      double[] temp = { 25, 273, 350 };

      int runs = 20;
      int timeSteps = 2000;

      PC.closed = true;
      PC.physicsClass = className;

      double[][] avgSpeed = new double[temp.length][runs];
      double[][] error1 = new double[temp.length][runs];
      double[][] error2 = new double[temp.length][runs];

      double[] maxSpeed = new double[temp.length];
      boolean cont = true;

      PC.L = 1e-6;
      PC.length = 1;
      PC.ncell_x = 10;
      PC.ncell_y = 10;
      PC.npart = 500;
      PC.T = 273;

      try
      {
         String file = "C:\\cygwin\\home\\wkerr\\repos\\FAABSIII\\AverageSpeed\\experiments\\";
         BufferedWriter out = new BufferedWriter(new FileWriter(file + "ktphysics.txt"));

         for (int i = 0; i < temp.length; ++i)
         {
            PC.T = temp[i];

            for (int j = 0; j < runs; ++j)
            {
               System.out.println("Temp " + temp[i] + " Run " + j);
               out.write("Temp " + temp[i] + " ");
               out.write("Run " + j + " ");
               createPhysics();
               for (int p = 0; p < timeSteps; ++p)
               {
                  physics.timeStep();
                  double[][] v = physics.v;
                  double avg = 0;
                  for (int k = 0; k < PC.npart; ++k)
                  {
                     double currSpeed = Math.sqrt(Math.pow(v[k][0], 2) +
                                                  Math.pow(v[k][1], 2));
                     avg += currSpeed;
                     if (currSpeed > maxSpeed[i])
                        maxSpeed[i] = currSpeed;
                  }
                  avg = avg / (double) PC.npart;
                  avgSpeed[i][j] += avg;
               }

               avgSpeed[i][j] /= (double) timeSteps;
               double theory1 = 0.25*Math.sqrt(8.0*Math.PI*boltz*temp[i]/mass);
               error1[i][j] = Math.abs(avgSpeed[i][j] - theory1) / maxSpeed[i];
               out.write("AvgSpeed " + avgSpeed[i][j] + " ");
               out.write("Error1 " + error1[i][j] + " ");
               out.write("Theory1 " + theory1 + " ");
               double theory2 = Math.sqrt(2.0*boltz*temp[i]/mass);
               error2[i][j] = Math.abs(avgSpeed[i][j] - theory2) / maxSpeed[i];
               out.write("Error2 " + error2[i][j] + " ");
               out.write("Theory2 " + theory2);
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
