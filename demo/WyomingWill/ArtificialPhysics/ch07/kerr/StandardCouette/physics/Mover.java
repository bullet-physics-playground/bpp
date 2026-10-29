package physics;

/*
 * Mover.java
 *
 * Created on October 18, 2003, 1:54 PM
 */

/**
 *
 * @author  Wesley Kerr
 */
public class Mover
{
   
   /** Creates a new instance of Mover */
   public Mover()
   {
   }
   
   private static double randn()
   {
      double randn = Math.sqrt(-2.0*Math.log(1.0 - Math.random())) * 
                     Math.cos(6.283185307 * Math.random());
      return randn;
   }
   
   public static void mover(double[][] x, double[][] x_old, double[][] v, int npart, double L,
                            double mpv, double vwall, double tau,
                            int[] strikes, double[] delv, MyLong seed)
   {
      // mover - Function to move particles by free flight
      //         Also handles the collisions with walls.
      // Inputs
      //   x             Positions of the particles
      //   v             Velocities of the particles
      //   npart         Number of particles in the system
      //   L             System length
      //   mpv           Most probable velocity off the wall
      //   vwall         Wall velocities
      //   tau           Time step
      // Outputs
      //   x,v           Updated positions and velocities
      //   strikes       Number of particles striking each wall
      //   delv          Change of y-velocity at each wall
      
      // Move all particles pretending walls are absent
      //double[][] x_old = new double[npart][2];

      for (int i = 0; i < npart; ++i)
      {
         x_old[i][0] = x[i][0];
         x_old[i][1] = x[i][1];
      }

      for (int i = 0; i < npart; ++i)
      {
         x[i][0] += v[i][0] *tau;
         x[i][1] += v[i][1] *tau;
      }
      
      // Check each particle to see if it strikes a wall
      strikes[0] = 0;
      strikes[1] = 0;
      
      delv[0] = 0;
      delv[1] = 0;

      double[] xwall = new double[2];
      double[] vw = new double[2];
      double[] direction = new double[2];
      
      xwall[0] = 0.0;
      xwall[1] = L;
      vw[0] = 0; //-vwall;
      vw[1] = vwall;
      direction[0] = 1;
      direction[1] = -1;
      
      double stdev = mpv / Math.sqrt(2.0);
      // Direction of particle leaving wall
      
      for (int i = 0; i < npart; ++i)
      {
         // Test if particle strikes either wall
         int flag = -1;
         if (x[i][0] <= 0)
            flag=0;      // Particle strikes left wall
         else if (x[i][0] >= L)
            flag=1;      // Particle strikes right wall
         
         // If particle strikes a wall, reset its position
         // and velocity.  Record velocity change.
         if (flag >= 0)
         {
            //System.out.println("Particle " + i + " has struck a wall");
            //System.out.println("\tOriginal Position <" + x_old[i][0] + "," + x_old[i][1] + ">");
            //System.out.println("\tOld Position <" + x[i][0] + "," + x[i][1] + ">");
            strikes[flag] += 1;
            double vyInitial = v[i][1];
            
            // Reset velocity components as biased Maxwellian,
            // Exponenetial dist. in x; Gaussian in y and z
            v[i][0] = direction[flag]*Math.sqrt(-Math.log(1.0-Rand.rand(seed)))*mpv;
            v[i][1] = stdev*Randn.randn(seed) + vw[flag];     // Add wall velocity

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
            
            // Record velocity change for force measurement
            delv[flag] += v[i][1] - vyInitial;

            //System.out.println("\tNew Position <" + x[i][0] + "," + x[i][1] + ">");
         }

         // Test if particle has pasted out of the control area
         //if (x[i][1] >= 10.0*L)
         //   x[i][1] = x[i][1] - 10.0*L;
         //else if (x[i][1] <= 0)
         //   x[i][1] = x[i][1] + 10.0*L;
      }
   }       
}
