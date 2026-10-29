
package physicsorig;

public class SampList 
{
   public int ncell;
   public int nsamp;
   public double[] ave_n;
   public double[] ave_ux;
   public double[] ave_uy;
   public double[] ave_uz;
   public double[] ave_T;

   // Default Constructor. 
   public SampList() 
   {
      initLists(1);
   }

   // Regular Constructor. 
   public SampList(int ncell_in) 
   {
     initLists(ncell_in);
   }

   // Initialization routine
   private void initLists(int ncell_in) 
   {
      ncell = ncell_in;
      nsamp = 0;
      ave_n = new double [ncell+1];  // Allocate memory
      ave_ux = new double [ncell+1];
      ave_uy = new double [ncell+1];
      ave_uz = new double [ncell+1];
      ave_T = new double [ncell+1];
      int i;
      for( i=1; i<=ncell; i++ ) 
      {
         ave_n[i] = 0;
	 ave_ux[i] = 0;
	 ave_uy[i] = 0;
	 ave_uz[i] = 0;
	 ave_T[i] = 0;
      }
   }
}


