package physics;


public class Randn
{
   // Random number generator; Normal (Gaussian) dist.

   public static double randn( MyLong seed ) 
   {
      // Input
      //   seed    Integer seed  (DO NOT USE A SEED OF ZERO)
      // Output
      //	 randn   Random number, Gaussian distributed
      double randn = Math.sqrt( -2.0*Math.log(1.0 - Rand.rand(seed)) )
                           * Math.cos( 6.283185307 * Rand.rand(seed) );

      return( randn );
   }
}
