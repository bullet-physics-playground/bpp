
package physicsorig;

public class mover
{
   public static void mover2( Matrix x, Matrix v, int npart, double L,
                              double mpv, double vwall, double tau,
                              Matrix strikes, Matrix delv, MyLong seed )
   {
      // mover - Function to move particles by free flight
      //         Also handles collisions with walls
      // Inputs
      //    x        Positions of the particles
      //    v        Velocities of the particles
      //    npart    Number of particles in the system
      //    L        System length
      //    mpv      Most probable velocity off the wall
      //    vwall    Wall velocities
      //    tau      Time step
      //    seed     Random number seed
      // Outputs
      //    x,v      Updated positions and velocities
      //    strikes  Number of particles striking each wall
      //    delv     Change of y-velocity at each wall
      //    seed     Random number seed
      //* Move all particles pretending walls are absent

      Matrix x_old = new Matrix(npart);
      x_old.copy(x);            // Remember original position

      int i;
      for( i=1; i<= npart; i++ )
         x.set(i, x_old.get(i) + v.get(i,1)*tau);

      //* Check each particle to see if it strikes a wall
      strikes.set(0.0);
      delv.set(0.0);

      Matrix xwall = new Matrix(2);
      Matrix vw = new Matrix(2);
      Matrix direction = new Matrix(2);

      xwall.set(1, 0.0);
      xwall.set(2, L);   // Positions of walls

      vw.set(1, 0); //-vwall);
      vw.set(2, vwall);  // Velocities of walls

      double stdev = mpv/Math.sqrt(2.);

      // Direction of particle leaving wall
      direction.set(1, 1.0);
      direction.set(2, -1.0);

      for( i=1; i<=npart; i++ )
      {
         //* Test if particle strikes either wall
         int flag = 0;
         if( x.get(i) <= 0 )
            flag=1;       // Particle strikes left wall
         else if( x.get(i) >= L )
            flag=2;       // Particle strikes right wall

         //* If particle strikes a wall, reset its position
         //  and velocity. Record velocity change.
         if( flag > 0 )	{
            strikes.inc(flag, 1.0);
            double vyInitial = v.get(i,2);

            //* Reset velocity components as biased Maxwellian,
            //  Exponential dist. in x; Gaussian in y and z
            v.set(i,1, direction.get(flag)*Math.sqrt(-Math.log(1.-rand.rand2(seed))) * mpv);
            v.set(i,2, stdev*randn.randn2(seed) + vw.get(flag)); // Add wall velocity
            v.set(i,3, stdev*randn.randn2(seed));
            //v.set(i,1, direction.get(flag)*Math.sqrt(-Math.log(1.-Math.random())) * mpv);
            //v.set(i,2, stdev*randn.randn2(seed) + vw.get(flag)); // Add wall velocity
            //v.set(i,3, stdev*randn.randn2(seed));

            // Time of flight after leaving wall
            double dtr = tau*(x.get(i)-xwall.get(flag))/(x.get(i)-x_old.get(i));

            //* Reset position after leaving wall
            x.set(i, xwall.get(flag) + v.get(i,1)*dtr);

            //* Record velocity change for force measurement
            delv.inc(flag, (v.get(i,2) - vyInitial));

         }

      }

   }
}