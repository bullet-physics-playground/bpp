
package physicsorig;

public class SortList
{

   public int ncell;
   public int npart;
   public int[] cell_n;
   public int[] index;
   public int[] Xref;

   // Default Constructor.
   public SortList()
   {
      initLists(1,1);
   }

   // Regular Constructor.
   public SortList(int ncell_in, int npart_in)
   {
      initLists(ncell_in,npart_in);
   }

   private void initLists(int ncell_in, int npart_in)
   {
      ncell = ncell_in;
      npart = npart_in;
      cell_n = new int [ncell+1];  // Allocate memory
      index = new int [ncell+1];
      Xref = new int [npart+1];
      int i;
      for( i=1; i<=ncell; i++ )
      {
         cell_n[i] = 0;
         index[i] = 0;
      }
      for( i=1; i<=npart; i++ )
         Xref[i] = 0;
   }
} // Class SortList



