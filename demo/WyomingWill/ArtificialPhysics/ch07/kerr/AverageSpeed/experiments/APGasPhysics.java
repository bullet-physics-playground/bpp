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
      double[] g =
      { 200, 400, 900 };

      int runs = 10;
      int timeSteps = 100;

      double[][] avgSpeed = new double[g.length][runs];
      double instAvgSpeed;

      double[] theory1 = new double[g.length];
      double[] theory2 = new double[g.length];

      double[] maxSpeed = new double[g.length];
      PC.npart = 50;
      PC.length = 1;

      try
      {
         String file = "C:\\cygwin\\home\\wkerr\\repos\\FAABSIII\\AverageSpeed\\experiments\\";
         PC.out = new BufferedWriter(new FileWriter(file+"output.txt"));

         for (int i = 0; i < g.length; ++i)
         {
            PC.G = g[i];
            PC.G2 = g[i];

            double a = (2.0*Math.sqrt(PC.G*PC.FMAX) - (PC.G/ (1.5*PC.RAD)));
            theory1[i] = Math.sqrt((PC.npart-1)*a);

            double b = 4.0 / (Math.sqrt(2.0)*Math.sqrt(3.0)*Math.sqrt(Math.PI));
            double c = Math.sqrt(PC.npart-1)*Math.sqrt(2.0*Math.sqrt(PC.G)*Math.sqrt(PC.FMAX) - (PC.G / (1.5*PC.RAD)));
            theory2[i] = b*c;

            maxSpeed[i] = 0;
            for (int j = 0; j < runs; ++j)
            {
               Physics physics = new Physics();
               for (int k = 0; k < timeSteps; ++k)
               {
                  instAvgSpeed = 0;

                  physics.timeStep();

                  double[][] x = physics.x;
                  double[][] v = physics.v;
                  for (int s = 0; s < PC.npart; ++s)
                  {
                     double currSpeed = Math.sqrt(Math.pow(v[s][0], 2) +
                                                  Math.pow(v[s][1], 2));
                     instAvgSpeed += currSpeed;
                     if (currSpeed > maxSpeed[i])
                        maxSpeed[i] = currSpeed;

                     //PC.out.write("Grav " + PC.G + " ");
                     //PC.out.write("Run " + j + " ");
                     //PC.out.write("TimeStep " + k + " ");
                     //PC.out.write("Particle " + s + " ");
                     //PC.out.write("x " + x[s][0] + " ");
                     //PC.out.write("y " + x[s][1] + " ");
                     //PC.out.write("vx " + v[s][0] + " ");
                     //PC.out.write("vy " + v[s][1] + " ");
                     //PC.out.write("speed " + currSpeed + " ");
                     //PC.out.write("\n");

                  }

                  avgSpeed[i][j] += instAvgSpeed / (double)PC.npart;
               }

               double[][] x = physics.x;
               int count = 0;
               for (int s = 0; s < PC.npart; ++s)
               {
                  if (x[s][0] <= PC.L && x[s][0] >= 0 &&
                      x[s][1] <= PC.L*PC.length && x[s][1] >= 0)
                     ++count;
               }
               System.out.println("Count: " + count);
               avgSpeed[i][j] /= (double) timeSteps;
            }
            System.out.println("Max Speed for g = " + g[i] + " " + maxSpeed);
         }

         BufferedWriter out = new BufferedWriter(new FileWriter(file + "apgasphysics.txt"));
         for (int i = 0; i < g.length; ++i)
         {
            for (int j = 0; j < runs; ++j)
            {
               out.write("GravForce " + g[i] + " ");
               out.write("Run " + j + " ");
               out.write("AvgSpeed " + avgSpeed[i][j] + " ");
               out.write("Theory1 " + theory1[i] + " ");
               out.write("Error1 " + (Math.abs(avgSpeed[i][j] - theory1[i]))/maxSpeed[i] + " ");
               out.write("Theory2 " + theory2[i] + " ");
               out.write("Error2 " + (Math.abs(avgSpeed[i][j] - theory2[i]))/maxSpeed[i] + " ");
               out.write("\n");
            }
         }
         out.close();
         PC.out.close();
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
