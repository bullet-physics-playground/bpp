/*
 * NonGraphicalMain.java
 *
 * Created on November 29, 2003, 11:33 PM
 */

package experiments;

import java.awt.*;
import java.io.*;
import java.util.*;

import physicsorig.PhysicsConstants;
/**
 *
 * @author  Wesley Kerr
 */
public class OriginalPhysics
{
   public static boolean one = false;

   public static double L = 1e-6;
   public static int ncell_x = 20;

   /** Creates a new instance of NonGraphicalMain */
   public OriginalPhysics()
   {
      double[] wallSpeeds =
      { 0.65, 1.792, 2.5 };

      int runs = 1;
      int timeSteps = 2000;

      double[][][] avgSpeed = new double[wallSpeeds.length][runs][ncell_x];
      double[][][] error = new double[wallSpeeds.length][runs][ncell_x];
      double[] count = new double[ncell_x];
      double[] instAvgSpeed = new double[ncell_x];

      double[][] theory = new double[wallSpeeds.length][ncell_x];

      physicsorig.PhysicsConstants.npart = 2000;

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
            physicsorig.PhysicsConstants.vwall_m = wallSpeeds[i];
            for (int j = 0; j < runs; ++j)
            {
               physicsorig.dmscne physics = new physicsorig.dmscne();
               for (int k = 0; k < timeSteps; ++k)
               {
                  for (int s = 0; s < ncell_x; ++s)
                     instAvgSpeed[s] = count[s] = 0;

                  physics.timeStep();

                  physicsorig.Matrix x = physics.x;
                  physicsorig.Matrix v = physics.v;
                  for (int s = 1; s <= PhysicsConstants.npart; ++s)
                  {
                     int jx = (int)(x.get(s)*ncell_x/L) + 1;
                     jx = ( jx <= ncell_x ) ? jx : ncell_x;
                     instAvgSpeed[jx-1] += v.get(s, 2);
                     count[jx-1] += 1;
                  }

                  for (int s = 0; s < ncell_x; ++ s)
                     avgSpeed[i][j][s] += instAvgSpeed[s] / count[s];
               }

               System.out.println("Collsions " + physics.colSum);
               System.out.println("Wall Striks " + physics.strikeSum.get(1) + " " +
                                                   physics.strikeSum.get(2));
               for (int k = 0; k < ncell_x; ++k)
               {
                  avgSpeed[i][j][k] /= (double) timeSteps;
                  error[i][j][k] = Math.pow(theory[i][k] - avgSpeed[i][j][k], 2);
               }
            }
         }

         String file = "C:\\cygwin\\home\\wkerr\\repos\\FAABSIII\\StandardCouette\\experiments\\";
         BufferedWriter out = new BufferedWriter(new FileWriter(file + "physicsorig.txt"));
         for (int i = 0; i < wallSpeeds.length; ++i)
         {
            for (int j = 0; j < runs; ++j)
            {
               for (int k = 0; k < ncell_x; ++k)
               {
                  out.write("WallSpeed " + wallSpeeds[i] + " ");
                  out.write("Run " + j + " ");
                  out.write("Cell " + k + " ");
                  out.write("AvgSpeed " + avgSpeed[i][j][k] + " ");
                  out.write("Theoretical " + theory[i][k] + " ");
                  out.write("Squared Error " + error[i][j][k] + "\n");
               }
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

      physicsorig.PhysicsConstants.vwall_m = wallSpeed;
      for (int j = 0; j < ncell_x; ++j)
      {
         physicsorig.dmscne physics = new physicsorig.dmscne();
         double x = ((((double)j)*width)+middle);
         double vwall = physics.vwall;

         theory[j] = vwall * (x / L);
      }
   }

   private void fillTheoryTwo(double wallSpeed, double[] theory)
   {
      double width = (L / ncell_x);
      double middle = (L / ncell_x) / 2.0;

      physicsorig.PhysicsConstants.vwall_m = wallSpeed;
      for (int j = 0; j < ncell_x; ++j)
      {
         physicsorig.dmscne physics = new physicsorig.dmscne();
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
      new OriginalPhysics();
   }
}
