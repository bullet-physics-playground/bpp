/*
 * PhysicsInterface.java
 *
 * Created on March 12, 2004, 12:12 PM
 */

package shared;

import java.util.*;
/**
 *
 * @author  Wesley Kerr
 */
public abstract class PhysicsInterface
{
   public double[][] x;
   public double[][] v;

   public boolean[][] coverage;
   protected boolean[] particleDone;

   /** Creates a new instance of PhysicsInterface */
   public PhysicsInterface()
   {
      x = new double[PC.npart][2];
      v = new double[PC.npart][2];
      particleDone = new boolean[PC.npart];

      coverage = new boolean[PC.ncell_y][PC.ncell_x];
      for (int i = 0; i < PC.ncell_y; ++i)
         for (int j = 0; j < PC.ncell_x; ++j)
            coverage[i][j] = false;

   }

   public void setFileName(String fileName)
   {
      ObstacleContainer.instance().load(fileName);

      PC.area = new Hashtable();
      Vector obstacles = ObstacleContainer.instance().getObstacles();
      for (int i = 0; i < obstacles.size(); ++i)
      {
         SquareObstacle o = (SquareObstacle) obstacles.elementAt(i);
         o.area();
      }

      PC.behind = new Hashtable();
      for (int i = 0; i < obstacles.size(); ++i)
      {
         SquareObstacle o = (SquareObstacle) obstacles.elementAt(i);
         o.behind();
      }
   }

   public abstract void timeStep();

   public double getRightWall()
   {
      return 0;
   }

   public double getLeftWall()
   {
      return 0;
   }

   public boolean continueGoing()
   {
      updateDoneStatus();
      for (int i = 0; i < PC.npart; ++i)
      {
         if (!particleDone[i])
            return true;
      }
      return false;
   }

   protected void updateDoneStatus()
   {
      for (int i = 0; i < PC.npart; ++i)
      {
         if (!particleDone[i] && checkParticle(i))
            particleDone[i] = true;
      }
   }

   protected boolean checkParticle(int particle)
   {
      if (x[particle][1] > (PC.L*PC.length))
      {
         x[particle][1] = PC.L*PC.length;
         return true;
      }
      return false;
   }

   public void writePositions()
   {
      if (PC.collectingData)
      {
         for (int i = 0; i < PC.npart; ++i)
            PC.write(PC.data, x[i][0] + "," + x[i][1] + "\n");
      }
   }

   public void updateCoverage()
   {
      /*for (int i = 0; i < PC.npart; ++i)
      {
         int jx = (int)(x[i][0]*PC.ncell_x/PC.L);
         int jy = (int)(x[i][1]*PC.ncell_y/(PC.length*PC.L));
         jx = ( jx < PC.ncell_x ) ? jx : PC.ncell_x - 1;
         jy = ( jy < PC.ncell_y ) ? jy : PC.ncell_y - 1;
         if (!PC.area.containsKey(jx+","+jy))
            coverage[jy][jx] = true;
         else
         {
            //System.out.println("DANGER WILL ROBINSON: " + jx + " " + jy);
            //System.out.println(" Particle: " + i + " Position: <" + x[i][0] + "," + x[i][1]);
         }
      }*/
   }

   public int countCoverage()
   {
      int count = 0;
      for (int i = 0; i < PC.ncell_y; ++i)
      {
         for (int j = 0; j < PC.ncell_x; ++j)
         {
            if (coverage[i][j])
               ++count;
         }
      }
      return count;
   }

   public int countObstacleCoverage()
   {
      int count = 0;
      Enumeration e = PC.behind.elements();
      while (e.hasMoreElements())
      {
         Point value = (Point) e.nextElement();

         if (coverage[(int) value.y][(int) value.x])
            ++count;
      }
      return count;
   }
}
