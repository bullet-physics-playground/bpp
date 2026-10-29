
package physicsorig;

public class colider
{

   public static int colider2( Matrix v, Matrix crmax, double tau, MyLong seed,
                              Matrix selxtra, double coeff, SortList sD ) 
   {
      // colide - Function to process collisions in cells
      // Inputs
      //    v         Velocities of the particles
      //    crmax     Estimated maximum relative speed in a cell
      //    tau       Time step
      //    seed      Current random number seed
      //    selxtra   Extra selections carried over from last timestep
      //    coeff     Coefficient in computing number of selected pairs
      //    sD        Object containing sorting lists
      // Outputs
      //    v         Updated velocities of the particles
      //    crmax     Updated maximum relative speed
      //    selxtra   Extra selections carried over to next timestep
      //    col       Total number of collisions processed    (Return value)

      int ncell = sD.ncell;
      int col = 0;          // Count number of collisions

      final double pi = 3.141592654;

      //* Loop over cells, processing collisions in each cell
      int jcell;
      for( jcell=1; jcell<=ncell; jcell++ ) 
      {
         //* Skip cells with only one particle
         int number = sD.cell_n[jcell];
         if( number < 2 ) continue;  // Skip to the next cell

         //* Determine number of candidate collision pairs
         //  to be selected in this cell
         double select = coeff*number*number*crmax.get(jcell) + selxtra.get(jcell);
         int nsel = (int)(select);      // Number of pairs to be selected
         selxtra.set(jcell, select-nsel);  // Carry over any left-over fraction

         double crm = crmax.get(jcell);     // Current maximum relative speed

         //* Loop over total number of candidate collision pairs
         int isel;
         for( isel=1; isel<=nsel; isel++ ) 
         {
            //* Pick two particles at random out of this cell
            int k = (int)(rand.rand2(seed)*number);
            int kk = ((int)(k+rand.rand2(seed)*(number-1))+1) % number;
            //int k = (int)(Math.random()*number);
            //int kk = ((int)(k+Math.random()*(number-1))+1) % number;

            int ip1 = sD.Xref[ k+sD.index[jcell] ];      // First particle
            int ip2 = sD.Xref[ kk+sD.index[jcell] ];     // Second particle

            //* Calculate pair's relative speed
            double cr = Math.sqrt( Math.pow(v.get(ip1,1)-v.get(ip2,1),2) +
                                   Math.pow(v.get(ip1,2)-v.get(ip2,2),2) +   // Relative speed
                                   Math.pow(v.get(ip1,3)-v.get(ip2,3),2) );

            if( cr > crm )         // If relative speed larger than crm,
               crm = cr;            // then reset crm to larger value

            //* Accept or reject candidate pair according to relative speed
            if( cr/crmax.get(jcell) > rand.rand2(seed) ) 
            //if( cr/crmax.get(jcell) > Math.random() ) 
            {
               //* If pair accepted, select post-collision velocities
               col++;                     // Collision counter

               Matrix vcm = new Matrix(3);
               Matrix vrel = new Matrix(3);

               int m;
               for( m=1; m<=3; m++ )
                  vcm.set(m, 0.5*(v.get(ip1,m) + v.get(ip2,m)));  // Center of mass velocity

               double cos_th = 1.0 - 2.0*rand.rand2(seed);      // Cosine and sine of
               //double cos_th = 1.0 - 2.0*Math.random();      // Cosine and sine of
               double sin_th = Math.sqrt(1.0 - cos_th*cos_th); // collision angle theta
               double phi = 2.0*pi*rand.rand2(seed);            // Collision angle phi
               //double phi = 2.0*pi*Math.random();            // Collision angle phi

               vrel.set(1, cr*cos_th);             // Compute post-collision
               vrel.set(2, cr*sin_th*Math.cos(phi));    // relative velocity
               vrel.set(3, cr*sin_th*Math.sin(phi));

               for(  k=1; k<=3; k++ ) 
               {
                  v.set(ip1,k, vcm.get(k) + 0.5*vrel.get(k));  // Update post-collision
                  v.set(ip2,k, vcm.get(k) - 0.5*vrel.get(k));  // velocities
               }
            } // Loop over pairs

            crmax.set(jcell, crm);     // Update max relative speed
         }

      }   // Loop over cells

      return( col );
   }

}