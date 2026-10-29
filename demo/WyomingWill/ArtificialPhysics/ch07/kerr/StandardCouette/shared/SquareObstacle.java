/*
 * SquareObstacle.java
 *
 * Created on January 5, 2004, 11:35 AM
 */

package shared;

import java.awt.*;
import java.util.*;
/**
 *
 * @author  Wesley Kerr
 */
public class SquareObstacle implements Obstacle
{
   private double x1;
   private double y1;
   private double x2;
   private double y2;
   
   private int flip;
   
   /** Creates a new instance of SquareObstacle */
   public SquareObstacle(double x1, double y1, double x2, double y2)
   {
      if (x1 > x2)
      {
         this.x1 = x2;
         this.x2 = x1;
      }
      else 
      {
         this.x1 = x1;
         this.x2 = x2;
      }
      
      if (y1 > y2)
      {
         this.y1 = y2;
         this.y2 = y1;
      }
      else
      {
         this.y1 = y1;
         this.y2 = y2;
      }
   }
   
   public void draw(Graphics g, int panelWidth, int panelHeight)
   {
      Color temp = g.getColor();
      g.setColor(Color.white);
      
      int x = (int) (x1 * panelWidth / PC.L);
      int y = (int) (y1 * panelHeight / (PC.L * PC.length));
      int width = (int) ((x2 - x1) * panelWidth / PC.L);
      int height = (int) ((y2 - y1) * panelHeight / (PC.length * PC.L));

      g.fillRect(x, y, width, height);
      
      g.setColor(temp);
   }
   
   public Point force(double x, double y, int dir)
   {
      Point force = checkWall(x,y,dir);
      return force;
   }
   
   private Point checkWall(double x, double y, int dir)
   {
      double distance = 0.0;
      double theta = 0.0;
      double ax = 0;
      double ay = 0;
      
       // Calculate r between obstacle's wall and particle
       if (y < y1)
       {
          if (x < x1)
          {
             ax = x1;
             ay = y1;
             theta = Math.atan((ay-y)/(ax-x));
          }
          else if (x >= x1 && x <= x2)
          {
             ax = x;
             ay = y1;
             if (dir == 1)
                theta = 3 * Math.PI / 4;
             else
                theta = Math.PI / 4;
          }
          else
          {
             ax = x2;
             ay = y1;
             theta = Math.atan((ay-y)/(ax-x)) + Math.PI;
          }
       }
       else if (y >= y1 && y <= y2)
       {
          ay = y;
          if (x <= x1)
          {
             ax = x1;
             theta = 0;
          }
          else
          {
             ax = x2;
             theta = Math.PI;
          }
       }
       else
       {
          if (x < x1)
          {
             ax = x1;
             ay = y2;
             theta = Math.atan((ay-y)/(ax-x));
          }
          else if (x >= x1 && x <= x2)
          {
             ax = x;
             ay = y2;
             if (dir == 1)
                theta = 7 * Math.PI / 4;
             else
                theta = 5 * Math.PI / 4;
          }
          else
          {
             ax = x2;
             ay = y2;
             theta = Math.atan((ay-y)/(ax-x)) + Math.PI;
          }
       }
         
       distance = Math.sqrt(Math.pow((x-ax),2) + Math.pow((y-ay),2));
         
       if (distance > 1.7*PC.RAD)
          return new Point(0,0);
         
       double f = -(PC.G2 / Math.pow(distance, PC.power));
       if (f > PC.FMAX)
          f = PC.FMAX;
         
       Point p = new Point(0,0);
       p.x += f*Math.cos(theta);
       p.y += f*Math.sin(theta);
       return p;
   }
   
   public void collision(double[] x, double[] x_old, double[] v, double mpv,  
                         double tau, MyLong seed)
   {
      if (!(x[0] > x1 && x[0] < x2 &&
            x[1] > y1 && x[1] < y2))
         return;
      
      Point intPoint = getIntersectionPoint(x, x_old);
      
      double stdev = mpv / Math.sqrt(2.0);
      double vxInitial = v[0];
      double vyInitial = v[1];

      v[0] = Math.sqrt(-Math.log(1.0-PC.rand(seed)))*mpv;
      v[1] = stdev*PC.randn(seed);     

      switch (intPoint.wall)
      {
         case 0: // top
            if (v[1] > 0)
               v[1] *= -1;
            break;
         case 1: // bottom
            if (v[1] < 0)
               v[1] *= -1;
            break;
         case 2: // left
            if (v[0] > 0)
               v[0] *= -1;
            break;
         case 3: // right
            if (v[0] < 0)
               v[0] *= -1;
            break;
      }

      double dtrx = tau*(x[0]-intPoint.x)/(x[0]-x_old[0]);
      double dtry = tau*(x[1]-intPoint.y)/(x[1]-x_old[1]);
      
      x[0] = intPoint.x + v[0]*dtrx;
      x[1] = intPoint.y + v[1]*dtry;
      
      if (x[0] > x1 && x[0] < x2 &&
          x[1] > y1 && x[1] < y2)
      {
         System.out.println("ERROR - WE HAVE ARRIVED INSIDE");
         System.out.println("Obstacle <" + x1 + "," + y1 + "> <" + x2 + "," + y2 + ">");
         System.out.println("\t Old Position: <" + x_old[0] + "," + x_old[1] + ">");
         System.out.println("\t New Position: <" + x[0] + "," + x[1] + ">");
      }
   }
   
   private double distance(double px1, double py1, double px2, double py2)
   {
      return Math.sqrt(Math.pow(px2 - px1, 2) + Math.pow(py2 - py1, 2));
   }
   
   private Point getIntersectionPoint(double[] x, double[] x_old)
   {
      Point p1 = new Point(x_old[0], x_old[1]);
      Point p2 = new Point(x[0], x[1]);
      
      Point p3;
      Point p4;
      
      Point intTop;
      Point intBottom;
      Point intLeft;
      Point intRight;
      
      // Check Intersection top
      p3 = new Point(x1, y1);
      p4 = new Point(x2, y1);
      intTop = PC.lineLineIntersection(p1, p2, p3, p4);
      
      // Check Intersection bottom
      p3 = new Point(x1, y2);
      p4 = new Point(x2, y2);
      intBottom = PC.lineLineIntersection(p1, p2, p3, p4);

      // Check Intersection left
      p3 = new Point(x1, y1);
      p4 = new Point(x1, y2);
      intLeft = PC.lineLineIntersection(p1, p2, p3, p4);
      
      // Check intersection right
      p3 = new Point(x2, y1);
      p4 = new Point(x2, y2);
      intRight = PC.lineLineIntersection(p1, p2, p3, p4);
      
      Point intPoint = new Point();
      double distance = 0;
      double d = 10000;
      if (intTop != null)
      {
         distance = distance(p1.x, p1.y, intTop.x, intTop.y);
         if (distance < d)
         {
            d = distance;
            intPoint = intTop;
            intPoint.wall = 0;
         }
      }
      if (intBottom != null)
      {
         distance = distance(p1.x, p1.y, intBottom.x, intBottom.y);
         if (distance < d)
         {
            d = distance;
            intPoint = intBottom;
            intPoint.wall = 1;
         }
      }
      if (intLeft != null)
      {
         distance = distance(p1.x, p1.y, intLeft.x, intLeft.y);
         if (distance < d)
         {
            d = distance;
            intPoint = intLeft;
            intPoint.wall = 2;
         }
      }
      if (intRight != null)
      {
         distance = distance(p1.x, p1.y, intRight.x, intRight.y);
         if (distance < d)
         {
            d = distance;
            intPoint = intRight;
            intPoint.wall = 3;
         }
      }

      return intPoint;
   }
   
   public void checkCollision(double[] x, double[] x_old)
   {
      if (!(x[0] > x1 && x[0] < x2 &&
            x[1] > y1 && x[1] < y2))
         return;
      
      //System.out.println("Checking Collision because we are still inside");
      
      Point intPoint = getIntersectionPoint(x, x_old);
      //System.out.println("Intersection chosen: " + intPoint);
      
      x[0] = intPoint.x;
      x[1] = intPoint.y;
      
      if (x[0] > x1 && x[0] < x2 &&
          x[1] > y1 && x[1] < y2)
      {
         System.out.println("STILL INSIDE");
         System.out.println("Obstacle <" + x1 + "," + y1 + "> <" + x2 + "," + y2 + ">");
         System.out.println("\t Old Position: <" + x_old[0] + "," + x_old[1] + ">");
         System.out.println("\t New Position: <" + x[0] + "," + x[1] + ">");
      }
   }
   
   public boolean past(double y)
   {
      if (y > y2)
         return true;
      return false;
   }
   
   public Vector cells()
   {
      Vector ret = new Vector();
      
      int maxx = (int) ((x2*PC.ncell_x)/PC.L);
      int minx = (int) ((x1*PC.ncell_x)/PC.L);
      
      int maxy = (int) ((y2*PC.ncell_y)/(PC.L*PC.length));
      
      for (int i = minx; i <= maxx; ++i)
      {
         Point p = new Point(i, maxy);
         ret.addElement(p);
      }
      return ret;
   }
   
   public void area()
   {
      int maxx = ((int) ((x2*PC.ncell_x)/PC.L));
      int minx = ((int) ((x1*PC.ncell_x)/PC.L));
      
      int miny = ((int) ((y1*PC.ncell_y)/(PC.L*PC.length)));
      int maxy = ((int) ((y2*PC.ncell_y)/(PC.L*PC.length)));
      
      for (int i = minx; i < maxx; ++i)
      {
         for (int j = miny; j < maxy; ++j)
         {
            String location = i + "," + j;
            if (!PC.area.containsKey(location))
            {
               Point p = new Point(i, j);
               PC.area.put(location, p);
            }
         }
      }
   }
   
   public void behind()
   {
      int maxx = (int) ((x2*PC.ncell_x)/PC.L);
      int minx = (int) ((x1*PC.ncell_x)/PC.L);
      
      int maxy = (int) ((y2*PC.ncell_y)/(PC.L*PC.length));

      for (int i = minx; i < maxx; ++i)
      {
         String location = i + "," + maxy;
         if (!PC.area.containsKey(location) && !PC.behind.containsKey(location))
         {
            Point p = new Point(i, maxy);
            PC.behind.put(location, p);
         }
      }
   }   
}
