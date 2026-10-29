package ktphysics;

/*
 * Mover.java
 *
 * Created on October 18, 2003, 1:54 PM
 */

import java.util.*;

import shared.MyLong;
import shared.PC;
import shared.ObstacleContainer;
import shared.Obstacle;
/**
 *
 * @author  Wesley Kerr
 */
public class Mover
{
   /** mover - Function to move particles by free flight
    *         Also handles the collisions with walls.
    * Inputs
    *   x             Positions of the particles
    *   v             Velocities of the particles
    *   mpv           Most probable velocity off the wall
    *   vwallL        Left Wall velocity
    *   vwallR        Right Wall velocity
    *   tau           Time step
    * Outputs
    *   x,v           Updated positions and velocities
    */
   public static void mover(double[][] x, double[][] x_old, double[][] v, 
                            double mpv, double vwallL, double vwallR, double tau,
                            MyLong seed, int[] dir, boolean[] particleDone)
   {
      for (int i = 0; i < PC.npart; ++i)
      {
         x_old[i][0] = x[i][0];
         x_old[i][1] = x[i][1];
      }

      for (int i = 0; i < PC.npart; ++i)
      {
         x[i][0] += v[i][0] *tau;
         x[i][1] += v[i][1] *tau;
      }
      
      double[] xwall = new double[2];
      double[] direction = new double[2];
      
      direction[0] = 1;
      direction[1] = -1;
      xwall[0] = 0.0;
      xwall[1] = PC.L;
      
      double stdev = mpv / Math.sqrt(2.0);

      int flag = -1;
      for (int i = 0; i < PC.npart; ++i)
      {  
         flag = -1;
         if (x[i][1] <= 0)
            flag = 0;
         else if (x[i][1] >= PC.L)
            flag = 1;
         
         if (flag >= 0)
         {
            double xint = 0;
            double yint = 0;
            if (flag == 1)
               yint = PC.L;
            
            if ((x_old[i][0] - x[i][0]) == 0)
            {
               xint = x[i][0];
            }
            else
            {
               double x1 = x_old[i][0];
               double y1 = x_old[i][1];
               double x2 = x[i][0];
               double y2 = x[i][1];
             
               double m = (y1-y2)/(x1-x2);
               double b = y1 - (m*x1);
               
               xint = (-b)/m;
            }

            // Reset velocity components as biased Maxwellian,
            // Exponenetial dist. in x; Gaussian in y and z
            //v[i][0] = Math.sqrt(-Math.log(1.0-PC.rand(seed)))*mpv;
            //v[i][1] = stdev*PC.randn(seed);     

            //if (v[i][1] < 0 && flag == 0)
            //   v[i][1] *= -1;
            //if (v[i][1] > 0 && flag == 1)
            //   v[i][1] *= -1;
            v[i][1] = -1*v[i][1];
            // Reset position after leaving wall
            // Time of flight after leaving wall
            double dtr = tau*(x[i][0]-xint)/(x[i][0]-x_old[i][0]);
            x[i][0] = xint + v[i][0]*dtr;

            dtr = tau*(x[i][1])/(x[i][1]-x_old[i][1]);
            x[i][1] = v[i][1]*dtr;
         }
         
         // Test if particle strikes either wall
         flag = -1;
         if (x[i][0] <= 0)
            flag=0;      // Particle strikes left wall
         else if (x[i][0] >= PC.L)
            flag=1;      // Particle strikes right wall
         
         // If particle strikes a wall, reset its position
         // and velocity.  Record velocity change.
         if (flag >= 0)
         {
            double vyInitial = v[i][1];
            
            // Reset velocity components as biased Maxwellian,
            // Exponenetial dist. in x; Gaussian in y and z
            v[i][0] = direction[flag]*Math.sqrt(-Math.log(1.0-PC.rand(seed)))*mpv;
            v[i][1] = stdev*PC.randn(seed);     
            
            // Time of flight after leaving wall
            double dtr = tau*(x[i][0]-xwall[flag])/(x[i][0]-x_old[i][0]);

            double y = x[i][1];
            double old_y = x_old[i][1];
            double a = old_y + ((y-old_y)*((x[i][0]-xwall[flag])/(x[i][0]-x_old[i][0])));

            // Reset position after leaving wall
            x[i][0] = xwall[flag] + v[i][0]*dtr;
            
            // Calculate wall intersection point for y

            // Time of flight after leaving wall
            dtr = tau*(x[i][1]-a)/(x[i][1]-x_old[i][1]);
            x[i][1] = a + v[i][1]*dtr;
            
         }
         if (x[i][1] < 0)
            x[i][1] = 0;
         if (x[i][1] > PC.L)
            x[i][1] = PC.L;
         if (x[i][0] < 0)
            x[i][0] = 0;
         if (x[i][0] > PC.L)
            x[i][0] = PC.L;
      }
   }       
}
