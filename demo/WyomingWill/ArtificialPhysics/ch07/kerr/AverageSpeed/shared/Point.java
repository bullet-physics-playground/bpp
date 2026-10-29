/*
 * Position.java
 *
 * Created on January 5, 2004, 1:27 PM
 */

package shared;

/**
 *
 * @author  Wesley Kerr
 */
public class Point
{
   public double x;
   public double y;
   public int wall;
   
   public int dir;
   
   public double velx;
   public double vely;
   
   public Point()
   {
      this.x = 0;
      this.y = 0;
   }
   
   /** Creates a new instance of Position */
   public Point(double x, double y)
   {
      this.x = x;
      this.y = y;
   }
   
   public Point(double x, double y, double velx, double vely)
   {
      this.x = x;
      this.y = y;
      this.velx = velx;
      this.vely = vely;
   }
   
   public Point(double x, double y, int dir)
   {
      this.x = x;
      this.y = y;
      this.dir = dir;
   }
   
   public String toString()
   {
      return ("<" + x + "," + y + ">");
   }
}
