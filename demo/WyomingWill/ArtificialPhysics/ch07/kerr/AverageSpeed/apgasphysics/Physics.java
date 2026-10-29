package apgasphysics;

import java.util.*;
import java.io.*;

import shared.PC;
import shared.ObstacleContainer;
import shared.Obstacle;
import shared.Point;

import shared.PhysicsInterface;

public class Physics extends PhysicsInterface
{
   public int N = 50;
   //public double G = 1200;
   public double range = 1.5;
   public double FR = 1;
   public double STEP = 1.0;
   
   private double obFx = 0.0;
   private double obFy = 0.0;
   
   private double wallFx = 0.0;
   private double wallFy = 0.0;
   
   private double gFx = 0.0;
   private double gFy = 1.0;
   
   private double particleFx = 0.0;
   private double particleFy = 0.0;
   
   public int dir[];
   
   public double temp[][];

   private double[] makeRand()
   {
      double[] ret = new double[2];
      double theta = 2.0*Math.PI*Math.random();
      double r = Math.sqrt(-2.0*Math.log(Math.random()));
      
      ret[0] = r*Math.cos(theta);
      ret[1] = r*Math.sin(theta);
      
      return ret;
   }
   
   public Physics()
   {
      super();
      
      PC.L = 1000;
      
      N = PC.npart;
      dir = new int[N];
      
      temp = new double[N][2];
      
      double Rad = PC.RAD / 10.0;
      
      for (int i = 0; i < N; ++i)
      {
         double[] t = makeRand();
         x[i][0] = t[0]*(PC.RAD/2) + (PC.L/2.0);
         x[i][1] = t[1]*(PC.RAD/2) + (PC.L/2.0);
         //x[i][0] = (makeRand(r1, r2, 1)*Rad - Rad/2) + (PC.L/2.0);
         //x[i][1] = (makeRand(r1, r2, 2)*Rad - Rad/2) + (PC.L/2.0);
         
         //x[i][0] = Math.random() * PC.L;
         //x[i][1] = Math.random() * PC.L;
         
         //if (x[i][0] < 50)
         //   x[i][0] += 50;
         //if (x[i][0] > PC.L-50)
         //   x[i][0] -= 50;
         //if (x[i][1] < 50)
         //   x[i][1] += 50;
         
         temp[i][0] = 0.0;
         temp[i][1] = 0.0;
         
         v[i][0] = 0.0;
         v[i][1] = 0.0;
         
         // Randomly assign a position
         // 1 - Left
         // 2 - Right
         dir[i] = ((int) (Math.random() * 1000) % 2) + 1;
      }
   }
   
   public void finalizePositions()
   {
      for (int i = 0; i < N; ++i)
      {
         x[i][0] = temp[i][0];
         x[i][1] = temp[i][1];
         //if (x[i][0] < 0 || x[i][0] > PC.L || x[i][1] < 0 || x[i][1] > PC.L*PC.length)
         //{
         //   System.out.println("Problem Particle: " + i);
         //   System.out.println("\tPosition <" + x[i][0] + "," + x[i][1] + ">");
         //   System.out.println("\tVelocity <" + v[i][0] + "," + v[i][1] + ">");
         //}
      }
   }
   
   public void timeStep()
   {
      double r, theta, phi, netF, vertF;
      double Fx = 0.0;
      double Fy = 0.0;
      double deltavx;
      double deltavy;
      
      
      for (int i = 0; i < x.length; ++i)
      {
         if (x[i][0] >= PC.L || x[i][0] <= 0 ||
             x[i][1] >= PC.L*PC.length || x[i][1] <= 0)
            continue;
         
         v[i][0] *= FR;
         v[i][1] *= FR;
         
         Fx = 0.0;
         Fy = 0.0;
         
         for (int k = 0; k < x.length; ++k)
         {
            if (i != k)
            {
               // Determine distance to particle
               double deltax = x[k][0] - x[i][0];
               double deltay = x[k][1] - x[i][1];
               
               r = Math.sqrt(Math.pow(deltax, 2) + Math.pow(deltay, 2));
               if (r < 1.7*PC.RAD)
               {
                  // Determine spherical coordinates theta and phi
                  theta = Math.atan2(deltay, deltax);
                  if (deltax < 0)
                     theta = theta + Math.PI;
                  
                  netF = force(r);
                  
                  if (r > 1.5*PC.RAD)
                     netF = 0.0;
                  
                  Fx += netF*Math.cos(theta);
                  Fy += netF*Math.sin(theta);
               }
            }
         }
         
         particleFx = Fx;
         particleFy = Fy;
         
         obstacleForce(i);
         Fx += obFx;
         Fy += obFy;
         //System.out.println("ObstacleForce " + i + " <" + obFx + "," + obFy + ">");
         
         wallForce(i);
         Fx += wallFx;
         Fy += wallFy;
         //System.out.println("WallForce " + i + " <" + wallFx + "," + wallFy + ">");
         
         deltavx = Fx * STEP; // Compute velocity change
         deltavy = Fy * STEP;
         
         //System.out.println("delta <" + deltavx + "," + deltavy + ">");
         v[i][0] = v[i][0] + deltavx;  // Velocity is updated
         v[i][1] = v[i][1] + deltavy;
         
         /*if (v[i][0] > 10.0 || v[i][1] > 10.0 || 
             v[i][0] < -10.0 || v[i][1] < -10.0)
         {
            System.out.println("DANGER WILL ROBINSON: Particle " + i + " is flying fast");
            System.out.println("\tObstacleForce <" + obFx + "," + obFy + ">");
            System.out.println("\tWallForce <" + wallFx + "," + wallFy + ">");
            System.out.println("\tGoalForce <" + PC.goalForce + ">");
            System.out.println("\tParticleForce <" + particleFx + "," + particleFy + ">");
            System.out.println("\tInitial Position <" + x[i][0] + "," + x[i][1] + ">");
            System.out.println("\tPosition <" + temp[i][0] + "," + temp[i][1] + ">");
            System.out.println("\tInitialVelocity <" + (v[i][0]-deltavx) + "," + (v[i][1]-deltavy) + ">");
            System.out.println("\tVelocity <" + v[i][0] + "," + v[i][1] + ">");
         }*/
         
         temp[i][0] = x[i][0] + v[i][0]*STEP; // Compute the updated position
         temp[i][1] = x[i][1] + v[i][1]*STEP;
         
         if (temp[i][0] < 0 || temp[i][0] > PC.L ||
             temp[i][1] < 0 || temp[i][1] > PC.L*PC.length)
         {
            System.out.println("DANGER WILL ROBINSON: Particle " + i + " is gone");
            System.out.println("\tObstacleForce <" + obFx + "," + obFy + ">");
            System.out.println("\tWallForce <" + wallFx + "," + wallFy + ">");
            System.out.println("\tGoalForce <" + PC.goalForce + ">");
            System.out.println("\tParticleForce <" + particleFx + "," + particleFy + ">");
            System.out.println("\tInitial Position <" + x[i][0] + "," + x[i][1] + ">");
            System.out.println("\tPosition <" + temp[i][0] + "," + temp[i][1] + ">");
            System.out.println("\tInitialVelocity <" + (v[i][0]-deltavx) + "," + (v[i][1]-deltavy) + ">");
            System.out.println("\tVelocity <" + v[i][0] + "," + v[i][1] + ">");
         }
      }
      finalizePositions();
   }
   
   private void obstacleForce(int p)
   {
      obFx = 0.0;
      obFy = 0.0;
      
      double distance = 0.0;
      double theta = 0.0;
      double ax = 0;
      double ay = 0;
      
      Vector ob = ObstacleContainer.instance().getObstacles();
      for (int i = 0; i < ob.size(); ++i)
      {
         Obstacle o = (Obstacle) ob.elementAt(i);
         Point point = o.force(x[p][0], x[p][1], dir[p]);
         obFx += point.x;
         obFy += point.y;
      }
   }
   
   private void wallForce(int p)
   {
      wallFx = 0.0;
      wallFy = 0.0;
      
      double distance = 0.0;
      double theta = 0.0;
      double ax = 0;
      double ay = 0;
      
      // Calculate r between particle and wall at 0;
      double rLeft = Math.sqrt(Math.pow(x[p][0], 2));
      double rRight = Math.sqrt(Math.pow((x[p][0]-PC.L), 2));
      double rTop = Math.sqrt(Math.pow(x[p][1], 2));
      double rBottom = Math.sqrt(Math.pow((x[p][1]-(PC.length*PC.L)), 2));
      
      if (rLeft < 1.7*PC.RAD)
      {
         theta = Math.PI;
         double f = -(PC.G2 / Math.pow(rLeft, PC.power));
         if (f < -PC.FMAX)
            f=-PC.FMAX;
         wallFx += f*Math.cos(theta);
      }
      if (rRight < 1.7*PC.RAD)
      {
         theta = 0;
         double f = -(PC.G2 / Math.pow(rRight, PC.power));
         if (f < -PC.FMAX)
            f=-PC.FMAX;
         wallFx += f*Math.cos(theta);
      }
      if (rTop < 1.7*PC.RAD)
      {
         theta = 3 * Math.PI / 2;
         double f = -(PC.G2 / Math.pow(rTop, PC.power));
         if (f < -PC.FMAX)
            f=-PC.FMAX;
         wallFy += f*Math.sin(theta);
      }
      if (rBottom < 1.7*PC.RAD)
      {
         theta = Math.PI / 2;
         double f = -(PC.G2 / Math.pow(rBottom, PC.power));
         if (f < -PC.FMAX)
            f=-PC.FMAX;
         wallFy += f*Math.sin(theta);
      }
   }
   
   private double force(double r)
   {
      double f=0.0;
      if (r!=0)
         f=PC.G/Math.pow(r,PC.power);
      else
         f=PC.FMAX;
      if (f>PC.FMAX)
         f=PC.FMAX;
      
      //if (r>RAD)
      //   return(f);
      return(-f);
   }
   
   public void displayCoverage()
   {
      for (int i = 0; i < PC.ncell_y; ++i)
      {
         for (int j = 0; j < PC.ncell_x; ++j)
         {
            if (coverage[i][j])
               System.out.print("X");
            else
               System.out.print("O");
         }
         System.out.println();
      }
   }
}





