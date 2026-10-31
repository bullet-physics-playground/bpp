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
public class Physics2a
{
   public boolean one = true;

   public int ncell_x = 20;
   public double L = 1e-6;

   /** Creates a new instance of NonGraphicalMain */
   public Physics2a()
   {
      double[] wallSpeeds =
      { 0.65 }; //, 1.25, 1.792, 10.0 };
      //{ 0.65, 1.25, 1.792, 2.5, 4.0 };

      int runs = 1;
      int timeSteps = 2000;

      double[][][] avgSpeed = new double[wallSpeeds.length][runs][ncell_x];
      double[][][] error = new double[wallSpeeds.length][runs][ncell_x];
      double[] count = new double[ncell_x];
      double[] instAvgSpeed = new double[ncell_x];

      double[][] theory = new double[wallSpeeds.length][ncell_x];

      physics.PhysicsConstants.npart = 2000;

      try
      {
         for (int i = 0; i < wallSpeeds.length; ++i)
         {
            if (one)
               fillTheoryOne(wallSpeeds[i], theory[i]);
            else
               fillTheoryTwo(wallSpeeds[i], theory[i]);
         }

         for (int i = 0; i < wallSpeeds.length; ++i)
         {
            physics.PhysicsConstants.vwall_m = wallSpeeds[i];

            for (int j = 0; j < runs; ++j)
            {
               physics.CouettePhysics physics = new physics.CouettePhysics();
               for (int k = 0; k < timeSteps; ++k)
               {
                  for (int s = 0; s < PC.ncell_x; ++s)
                     instAvgSpeed[s] = count[s] = 0;

                  physics.timeStep();

                  double[][] x = physics.x;
                  double[][] v = physics.v;
                  for (int s = 0; s < PC.npart; ++s)
                  {
                     int jx = (int)(x[s][0]*ncell_x/L);
                     jx = ( jx < ncell_x ) ? jx : ncell_x - 1;
                     //System.out.println("Velocity of " + s + " is <" + v[s][1] + ">");
                     instAvgSpeed[jx] += v[s][1];
                     count[jx] += 1;
                  }

                  for (int s = 0; s < PC.ncell_x; ++ s)
                     avgSpeed[i][j][s] += instAvgSpeed[s] / count[s];
               }
               //System.out.println("Wall L " + PC.strikeSum[0] + " R " + PC.strikeSum[1]);
               //System.out.println("Collsion Count " + PC.colSum);

               for (int k = 0; k < PC.ncell_x; ++k)
               {
                  avgSpeed[i][j][k] /= (double) timeSteps;
                  error[i][j][k] = Math.pow(theory[i][k] - avgSpeed[i][j][k], 2);
               }
            }
         }

         String file = "C:\\cygwin\\home\\wkerr\\repos\\FAABSIII\\StandardCouette\\experiments\\";
         BufferedWriter out = new BufferedWriter(new FileWriter(file + "physics2a.txt"));
         for (int i = 0; i < wallSpeeds.length; ++i)
         {
            for (int j = 0; j < runs; ++j)
            {
               out.write("WallSpeed " + wallSpeeds[i] + " ");
               out.write("Run " + j + " ");
               for (int k = 0; k < PC.ncell_x; ++k)
               {
                  out.write("Cell " + k + " ");
                  out.write("AvgSpeed " + avgSpeed[i][j][k] + " ");
                  out.write("Theoretical " + theory[i][k] + " ");
                  out.write("Squared Error " + error[i][j][k] + " ");
               }
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

   private void fillTheoryOne(double wallSpeed, double[] theory)
   {
      double width = (L / ncell_x);
      double middle = (L / ncell_x) / 2.0;

      physics.PhysicsConstants.vwall_m = wallSpeed;
      for (int j = 0; j < ncell_x; ++j)
      {
         physics.CouettePhysics physics = new physics.CouettePhysics();
         double x = ((((double)j)*width)+middle);
         double vwall = physics.vwall;

         theory[j] = vwall * (x / PC.L);
      }
   }

   private void fillTheoryTwo(double wallSpeed, double[] theory)
   {
      double width = (L / ncell_x);
      double middle = (L / ncell_x) / 2.0;

      physics.PhysicsConstants.vwall_m = wallSpeed;
      for (int j = 0; j < ncell_x; ++j)
      {
         physics.CouettePhysics physics = new physics.CouettePhysics();
         double x = ((((double)j)*width)+middle);
         double vwall = physics.vwall;

         double newL = L / 2.0;
         double newX = x - newL;
         if (x < newL)
         {
            newX = Math.abs(newX);
            theory[j] = -vwall * (newX / newL);
         }
         else
         {
            theory[j] = vwall * (newX / newL);
         }
      }
   }

   /**
    * @param args the command line arguments
    */
   public static void main(String[] args)
   {
      new Physics2a();
   }
}
