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
public class NewPhysics
{
   private boolean one = true;
   
   private PhysicsInterface physics;
   
   /** Creates a new instance of NonGraphicalMain */
   public NewPhysics(String className)
   {
      double[] wallSpeeds = { 0.65, 1.2, 1.792 };
      
      int runs = 10;
      int timeSteps = 2000;
      
      PC.closed = false;
      PC.physicsClass = className;
      
      PC.L = 1e-6;
      PC.length = 10;
      PC.ncell_x = 7;
      PC.ncell_y = 70;
      PC.npart = 500;
      PC.T = 273;
      
      PC.direction0 = -1;
      PC.direction1 = 1;

      PC.UP = false;
      PC.DOWN = false;

      double[][][] avgSpeed = new double[wallSpeeds.length][runs][PC.ncell_x];
      double[][][] error = new double[wallSpeeds.length][runs][PC.ncell_x];
      double[] count = new double[PC.ncell_x];
      double[] instAvgSpeed = new double[PC.ncell_x];
      double[] maxVelocity = new double[wallSpeeds.length];
      
      double[][] theory = new double[wallSpeeds.length][PC.ncell_x];
      double[][] maxError = new double[wallSpeeds.length][PC.ncell_x];
      
      try
      {

         for (int i = 0; i < wallSpeeds.length; ++i)
         {
            if (one)
               fillTheoryOne(wallSpeeds[i], theory[i], maxError[i]);
            else
               fillTheoryTwo(wallSpeeds[i], theory[i]);
            createPhysics();
            maxVelocity[i] = physics.getRightWall();
         }
         
         for (int i = 0; i < wallSpeeds.length; ++i)
         {
            if (one)
               PC.vwallL_m = 0;
            else
               PC.vwallL_m = wallSpeeds[i];
            PC.vwallR_m = wallSpeeds[i];
            
            for (int j = 0; j < runs; ++j)
            {
               System.out.println("WallSpeed " + wallSpeeds[i] + " Run " + j);
               createPhysics();
               for (int k = 0; k < timeSteps; ++k)
               {
                  for (int s = 0; s < PC.ncell_x; ++s)
                     instAvgSpeed[s] = count[s] = 0;
                  
                  physics.timeStep();
                  
                  double[][] x = physics.x;
                  double[][] v = physics.v;
                  for (int s = 0; s < PC.npart; ++s)
                  {
                     int jx = (int)(x[s][0]*PC.ncell_x/PC.L);
                     jx = ( jx < PC.ncell_x ) ? jx : PC.ncell_x - 1;
                     instAvgSpeed[jx] += v[s][1];
                     count[jx] += 1;
                  }
                  
                  for (int s = 0; s < PC.ncell_x; ++ s)
                     avgSpeed[i][j][s] += (instAvgSpeed[s] / count[s]); /// maxVelocity[i];
               }
               
               System.out.println("NumCollisions " + PC.colSum);
               for (int k = 0; k < PC.ncell_x; ++k)
               {
                  avgSpeed[i][j][k] /= (double) timeSteps;
                  error[i][j][k] = Math.abs(theory[i][k] - avgSpeed[i][j][k]) / maxError[i][k];
               }
            }
         }
         
         String file = "C:\\cygwin\\home\\wkerr\\repos\\FAABSIII\\StandardCouette\\experiments\\";
         BufferedWriter out = new BufferedWriter(new FileWriter(file + "newphysics.txt"));
         for (int i = 0; i < wallSpeeds.length; ++i)
         {
            for (int j = 0; j < runs; ++j)
            {
               for (int k = 0; k < PC.ncell_x; ++k)
               {
                  out.write("WallSpeed " + wallSpeeds[i] + " ");
                  out.write("Run " + j + " ");
                  out.write("Cell " + k + " ");
                  out.write("AvgSpeed " + avgSpeed[i][j][k] + " ");
                  out.write("Theoretical " + theory[i][k] + " ");
                  out.write("SquaredError " + error[i][j][k] + " ");
                  out.write("\n");
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
   
   private void fillTheoryOne(double wallSpeed, double[] theory, double[] maxError)
   {
      double width = (PC.L / PC.ncell_x);
      double middle = (PC.L / PC.ncell_x) / 2.0;
         
      System.out.println("ncell_x " + PC.ncell_x);
      PC.vwallL_m = 0;
      PC.vwallR_m = wallSpeed;
      for (int j = 0; j < PC.ncell_x; ++j)
      {
         createPhysics();
         double x = ((((double)j)*width)+middle);
         double vwall = physics.getRightWall();
               
         theory[j] = (x / PC.L)*vwall;
         if (Math.abs(theory[j]) > Math.abs(theory[j] - physics.getRightWall()))
            maxError[j] = Math.abs(theory[j]);
         else
            maxError[j] = Math.abs(theory[j] - physics.getRightWall());
         System.out.println("Max Error " + j + " " + maxError[j]);
      }
   }
   
   private void fillTheoryTwo(double wallSpeed, double[] theory)
   {
      double width = (PC.L / PC.ncell_x);
      double middle = (PC.L / PC.ncell_x) / 2.0;
         
      PC.vwallL_m = wallSpeed;
      PC.vwallR_m = wallSpeed;
      for (int j = 0; j < PC.ncell_x; ++j)
      {
         createPhysics();
         double x = ((((double)j)*width)+middle);
         double vwallL = physics.getLeftWall();
         double vwallR = physics.getRightWall();
         
         double newL = PC.L / 2.0;
         double newX = x - newL;
         if (x < newL)
         {
            newX = Math.abs(newX);
            theory[j] = (newX / newL);
         }
         else
         {
            theory[j] = -(newX / newL);
         }
      }
   }
   
   /**
    * @param args the command line arguments
    */
   public static void main(String[] args)
   {
      new NewPhysics("ktphysics.CouettePhysics");
   }
}
