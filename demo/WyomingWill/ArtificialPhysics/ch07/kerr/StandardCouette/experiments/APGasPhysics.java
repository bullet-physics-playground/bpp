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
      double[] goalForce = 
      { 1.0, 2.0, 3.0 };
      
      int runs = 10;
      int timeSteps = 100;

      double[][][] avgSpeed = new double[goalForce.length][runs][timeSteps];
      double[][][] error = new double[goalForce.length][runs][timeSteps];
      double instAvgSpeed;
      
      double[][] theory = new double[goalForce.length][timeSteps];
      
      PC.npart = 500;
      PC.length = 200;
      
      try
      {
         for (int i = 0; i < goalForce.length; ++i)
         {
            PC.goalForce = goalForce[i];
            for (int j = 0; j < runs; ++j)
            {
               Physics physics = new Physics();
               for (int k = 0; k < timeSteps; ++k)
               {
                  theory[i][k] = k*goalForce[i];
                  instAvgSpeed = 0;
                  
                  physics.timeStep();
                  
                  double[][] x = physics.x;
                  double[][] v = physics.v;
                  for (int s = 0; s < PC.npart; ++s)
                  {
                     instAvgSpeed += v[s][1];
                  }
                  
                  avgSpeed[i][j][k] += instAvgSpeed / (double)PC.npart;
                  error[i][j][k] = Math.abs(1.0 - (avgSpeed[i][j][k] / theory[i][k]));
               }
            }
         }
         
         String file = "C:\\cygwin\\home\\wkerr\\repos\\FAABSIII\\StandardCouette\\experiments\\";
         BufferedWriter out = new BufferedWriter(new FileWriter(file + "apgasphysics.txt"));
         for (int i = 0; i < goalForce.length; ++i)
         {
            for (int j = 0; j < runs; ++j)
            {
               for (int k = 0; k < timeSteps; ++k)
               {
                  out.write("GoalForce " + goalForce[i] + " ");
                  out.write("Run " + j + " ");
                  out.write("TimeStep " + k + " ");
                  out.write("AvgSpeed " + avgSpeed[i][j][k] + " ");
                  out.write("Theoretical " + theory[i][k] + " ");
                  out.write("Error " + error[i][j][k] + " ");
                  out.write("\n");
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
   
   /**
    * @param args the command line arguments
    */
   public static void main(String[] args)
   {
      new APGasPhysics();
   }
}
