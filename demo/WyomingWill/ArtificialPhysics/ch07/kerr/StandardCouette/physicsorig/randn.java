
package physicsorig;

public class randn
{
   // Random number generator; Normal (Gaussian) dist.

   public static double randn2( MyLong seed ) 
   {
      // Input
      //   seed    Integer seed  (DO NOT USE A SEED OF ZERO)
      // Output
      //	 randn   Random number, Gaussian distributed
      double randn = Math.sqrt( -2.0*Math.log(1.0 - rand.rand2(seed)) )
                           * Math.cos( 6.283185307 * rand.rand2(seed) );

      //double randn = Math.sqrt( -2.0*Math.log(1.0 - Math.random()) )
      //                     * Math.cos( 6.283185307 * Math.random() );
      return( randn );
   }
}
