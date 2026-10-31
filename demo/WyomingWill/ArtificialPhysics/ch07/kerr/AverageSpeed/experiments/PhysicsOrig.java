/*
 * NonGraphicalMain.java
 *
 * Created on November 29, 2003, 11:33 PM
 */

package experiments;

import java.awt.*;
import java.io.*;
import java.util.*;

import physicsorig.dmscne;
import physicsorig.Matrix;
/**
 *
 * @author  Wesley Kerr
 */
public class PhysicsOrig
{
   public final double boltz = 1.3806e-23;  // Boltzmann's constant (J/K)
   public double mass = 6.63e-26;     // Mass of argon atom (kg)

   /** Creates a new instance of NonGraphicalMain */
   public PhysicsOrig()
   {
      double[] temp = { 273 };

      int runs = 10;
      int timeSteps = 2000;

      double[][] avgSpeed = new double[temp.length][runs];
      double[][] error = new double[temp.length][runs];
      boolean cont = true;

      try
      {
         String file = "C:\\cygwin\\home\\wkerr\\repos\\FAABSIII\\AverageSpeed\\experiments\\";
         BufferedWriter out = new BufferedWriter(new FileWriter(file + "physicsorig.txt"));

         for (int i = 0; i < temp.length; ++i)
         {
            for (int j = 0; j < runs; ++j)
            {
               System.out.println("Temp " + temp[i] + " Run " + j);
               out.write("Temp " + temp[i] + " ");
               out.write("Run " + j + " ");
               dmscne physics = new dmscne();
               for (int p = 0; p < timeSteps; ++p)
               {
                  physics.timeStep();
                  Matrix v = physics.v;
                  double avg = 0;
                  for (int k = 1; k <= physics.npart; ++k)
                  {
                     avg += Math.sqrt(Math.pow(v.get(k, 1), 2) +
                                      Math.pow(v.get(k, 2), 2) +
                                      Math.pow(v.get(k, 3), 2));
                  }
                  avg = avg / (double) physics.npart;
                  avgSpeed[i][j] += avg;
               }

               avgSpeed[i][j] /= (double) timeSteps;
               double theory = (2.0*Math.sqrt(2.0) / Math.sqrt(Math.PI))*
                               Math.sqrt(boltz*temp[i]/mass);
               error[i][j] = Math.pow(avgSpeed[i][j] - theory, 2);
               out.write("AvgSpeed " + avgSpeed[i][j] + " ");
               out.write("Error " + error[i][j] + " ");
               out.write("Theory " + theory);
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
      new PhysicsOrig();
   }
}
