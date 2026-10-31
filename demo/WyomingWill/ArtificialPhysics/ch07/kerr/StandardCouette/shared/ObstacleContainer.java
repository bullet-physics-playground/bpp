/*
 * ObstacleContainer.java
 *
 * Created on January 5, 2004, 11:13 AM
 */

package shared;

import java.util.Vector;
import java.util.StringTokenizer;
import java.io.*;
/**
 *
 * @author  Wesley Kerr
 */
public class ObstacleContainer
{
   private Vector obstacles;
   private static ObstacleContainer oc = null;

   /** Creates a new instance of ObstacleContainer */
   private ObstacleContainer()
   {
      obstacles = new Vector();
   }

   public static ObstacleContainer instance()
   {
      if (oc == null)
         oc = new ObstacleContainer();

      return oc;
   }

   public Vector getObstacles()
   {
      return obstacles;
   }

   public void addObstacle(double x1, double y1, double x2, double y2)
   {
      SquareObstacle o = new SquareObstacle(x1, y1, x2, y2);
      o.area();
      o.behind();
      obstacles.addElement(o);
   }

   public void clearObstacles()
   {
      obstacles.clear();
   }

   public void load(String fileName)
   {
      obstacles = new Vector();
      double x1, x2, x3;
      double y1, y2, y3;
      try
      {
         BufferedReader in = new BufferedReader(new FileReader(fileName));
         while (in.ready())
         {
            StringTokenizer str = new StringTokenizer(in.readLine(), " ");
            int type = new Integer(str.nextToken()).intValue();
            x1 = new Double(str.nextToken()).doubleValue();
            y1 = new Double(str.nextToken()).doubleValue();
            x2 = new Double(str.nextToken()).doubleValue();
            y2 = new Double(str.nextToken()).doubleValue();
            obstacles.addElement(new SquareObstacle(x1, y1, x2, y2));
         }
      }
      catch (Exception e)
      {
         System.out.println("Error Loading Obstacle File");
         System.exit(0);
      }
   }

   public int countObstacleTotal()
   {
      int count = 0;
      Vector obstacles = ObstacleContainer.instance().getObstacles();
      for (int i = 0; i < obstacles.size(); ++i)
      {
         Obstacle o = (Obstacle) obstacles.elementAt(i);
         Vector points = o.cells();
         count += points.size();
      }
      return count;
   }
}