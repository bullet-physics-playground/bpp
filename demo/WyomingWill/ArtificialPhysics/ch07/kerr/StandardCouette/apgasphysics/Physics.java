package apgasphysics;

import java.util.*;

import shared.PC;
import shared.ObstacleContainer;
import shared.Obstacle;
import shared.Point;

import shared.PhysicsInterface;

public class Physics extends PhysicsInterface
{
   static double RAD = 50.0;      // One radius
   
   public int N = 50;
   //public double G = 1200;
   public double range = 1.5;
   public double FMAX = 1.5;
   public double FR = 1;
   public double STEP = 1.0;
   public double power = 2.2;
   
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
   
   public Physics()
   {
      super();
      
      PC.L = 1000;
      
      N = PC.npart;
      dir = new int[N];
      
      temp = new double[N][2];
      
      for (int i = 0; i < N; ++i)
      {
         x[i][0] = Math.random() * PC.L;
         x[i][1] = Math.random() * PC.L;
         
         if (x[i][0] < 50)
            x[i][0] += 50;
         if (x[i][0] > PC.L-50)
            x[i][0] -= 50;
         if (x[i][1] < 50)
            x[i][1] += 50;
         
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
               if (r < 1.7*RAD)
               {
                  // Determine spherical coordinates theta and phi
                  theta = Math.atan(deltay/deltax);
                  if (deltax < 0)
                     theta = theta + Math.PI;
                  
                  netF = force(r);
                  
                  if (r > 1.5*RAD)
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
         
         // Add goal force
         if (x[i][1] < (PC.L*PC.length)+100)
            Fy += PC.goalForce;
         else
            Fy -= PC.goalForce;

         deltavx = Fx * STEP; // Compute velocity change
         deltavy = Fy * STEP;
         
         //System.out.println("delta <" + deltavx + "," + deltavy + ">");
         v[i][0] = v[i][0] + deltavx;  // Velocity is updated
         v[i][1] = v[i][1] + deltavy;
         
         v[i][0] = v[i][0] > PC.MAX ? PC.MAX : v[i][0];
         //v[i][1] = v[i][1] > PC.MAX ? PC.MAX : v[i][1];
         
         v[i][0] = v[i][0] < -PC.MAX ? -PC.MAX : v[i][0];
         //v[i][1] = v[i][1] < -PC.MAX ? -PC.MAX : v[i][1];
         
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
      
      if (rLeft < 1.7*RAD)
      {
         theta = Math.PI;
         double f = -(PC.G2 / Math.pow(rLeft, power));
         if (f > FMAX)
            f=FMAX;
         wallFx += f*Math.cos(theta);
      }
      if (rRight < 1.7*RAD)
      {
         theta = 0;
         double f = -(PC.G2 / Math.pow(rRight, power));
         if (f > FMAX)
            f=FMAX;
         wallFx += f*Math.cos(theta);
      }
      if (rTop < 1.7*RAD)
      {
         theta = 3 * Math.PI / 2;
         double f = -(PC.G2 / Math.pow(rTop, power));
         if (f > FMAX)
            f=FMAX;
         wallFy += f*Math.sin(theta);
      }
      if (rBottom < 1.7*RAD)
      {
         theta = Math.PI / 2;
         double f = -(PC.G2 / Math.pow(rBottom, power));
         if (f > FMAX)
            f=FMAX;
         wallFy += f*Math.sin(theta);
      }
   }
   
   private double force(double r)
   {
      double f=0.0;
      if (r!=0)
         f=PC.G/Math.pow(r,power);
      if (f>FMAX)
         f=FMAX;
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





