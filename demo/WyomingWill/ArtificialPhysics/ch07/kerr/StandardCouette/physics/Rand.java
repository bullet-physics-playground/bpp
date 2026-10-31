package physics;

public class Rand
{
   // Random number generator; Uniform dist. in [0,1)
   public static double rand( MyLong seed )
   {
      // Input
      //   seed    Integer seed (DO NOT USE A SEED OF ZERO)
      // Output
      //   rand    Random number uniformly distributed in [0,1)
      final long a = 16807;
      final long m = 2147483647;
      long temp = a * seed.seed;
      seed.seed = temp % m;
      double rand = (double) seed.seed / (double) m;

      return( rand );
   }
}

