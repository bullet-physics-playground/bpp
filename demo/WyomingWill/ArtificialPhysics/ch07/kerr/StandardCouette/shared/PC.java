/*
 * PhysicsConstants.java
 *
 * Created on November 3, 2003, 10:41 AM
 */

package shared;

import java.util.*;
import java.io.*;
/**
 *
 * @author  Wesley Kerr
 */
public class PC
{
   public static String physicsClass = "ktphysics.CouettePhysics";
   public static String obstaclePath = null;
   
   public static int sleepTime = 100;
   public static int time = 0;
   public static int coverageStopCount = 0;
   
   public static int T = 273;
   public static int npart = 500;
   public static double vwallL_m = 0.2;
   public static double vwallR_m = 0.2;
   public static int ncell_x = 30;
   public static int ncell_y = 300;
   public static int length = 10;
   public static int direction0 = 1;
   public static int direction1 = 1;
   
   public static double G = 1200;
   public static double G2 = 1200;
   public static double MAX = 10;
   
   public static double L = 1e-6;
   public static double RAD = 50;
   public static double FMAX = 1.5;
   public static double power = 2.2;
   public static double goalForce = 1.0;
   
   public static int collisionCount;
   public static int collisionChanged;
   public static int[][] colCellCount;
   public static int[][] colCellChangedCount;
 
   public static boolean UP = false;
   public static boolean DOWN = false;
   
   public static Hashtable area = new Hashtable();
   public static Hashtable behind = new Hashtable();
   
   public static boolean collectingData = false;
   public static BufferedWriter out;
   public static BufferedWriter data;
   public static BufferedWriter changed;
   
   public static double shiftvalue = 0.0;
   public static boolean shiftdirection = false;
   
   public static boolean closed = false;
   public static boolean stopOnBottom = true;
   
   public static int[] strikeSum = new int[2];
   public static int colSum = 0;
   
   /** Creates a new instance of PhysicsConstants */
   public PC()
   {
   }
   
   public static double fakeLog(int num)
   {
      num += 40;
      return(Math.round((Math.pow(10.0,Math.floor(num/90.0))+
                         Math.pow(10.0,Math.floor(num/90.0)-1)*(num%90)))/1000000.0);
   }

   //  Random number generated; uniformly distributed
   public static double rand( MyLong seed ) 
   {
      final long a = 16807;
      final long m = 2147483647;
      long temp = a * seed.seed;
      seed.seed = temp % m;
      double rand = (double) seed.seed / (double) m;
      
      return( rand );
   }
   
   // Random number generator; Normal (Gaussian) dist.
   public static double randn( MyLong seed ) 
   {
      double randn = Math.sqrt( -2.0*Math.log(1.0 - rand(seed)) )
                           * Math.cos( 6.283185307 * rand(seed) );
      return( randn );
   }

   // Random number generator; Normal (Gaussian) dist.
   public static double randn( MyLong seed , double value , boolean forward ) 
   {
      double randn = Math.sqrt( -2.0*Math.log(1.0 - rand(seed)) )
                           * Math.cos( 6.283185307 * rand(seed) );
      
      if (forward)
         randn += value;
      else
         randn -= value;
      
      return( randn );
   }
   
   public static void write(BufferedWriter output, String line)
   {
      try
      {
         //output.write(line);
      }
      catch (Exception e)
      {
         System.out.println("ERROR - " + e.getMessage());
      }
   }
   
   public static Point lineLineIntersection(Point p1, Point p2, Point p3, Point p4)
   {
      double denom = ((p4.y - p3.y)*(p2.x - p1.x) - (p4.x - p3.x)*(p2.y - p1.y));
      
      if (denom == 0)
         return null;
      
      double ua = ((p4.x - p3.x)*(p1.y - p3.y) - (p4.y - p3.y)*(p1.x - p3.x)) / denom;
      
      Point intersection = new Point();
      
      intersection.x = p1.x + ua*(p2.x - p1.x);
      intersection.y = p1.y + ua*(p2.y - p1.y);
      
      if (intersection.x >= p3.x && intersection.x <= p4.x &&
          intersection.y >= p3.y && intersection.y <= p4.y)
         return intersection;
      else
         return null;
   }   
}
