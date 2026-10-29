package ktphysics;

/*
 * SortList.java
 *
 * Created on October 16, 2003, 10:56 PM
 */

/**
 *
 * @author  Wesley Kerr
 */
public class SortList
{
   public int ncell_x;
   public int ncell_y;
   public int npart;
   public int[][] cell_n;
   public int[] index;
   public int[] Xref;
   
   /** Creates a new instance of SortList */
   public SortList()
   {
      initLists(1,1,1);
   }
   
   public SortList(int ncell_inx, int ncell_iny, int npart_in)
   {
      initLists(ncell_inx, ncell_iny, npart_in);
   }
   
   private void initLists(int ncell_inx, int ncell_iny, int npart_in)
   {
      ncell_x = ncell_inx;
      ncell_y = ncell_iny;
      npart = npart_in;
      cell_n = new int[ncell_y][ncell_x];
      index = new int[ncell_y*ncell_x];
      Xref = new int[npart];
      
      for (int i = 0; i < ncell_y; ++i)
      {
         for (int j = 0; j < ncell_x; ++j)
         {
            cell_n[i][j] = 0;
            index[i*ncell_x + j] = 0;
         }
      }
      
      for (int i = 0; i < npart; ++i)
         Xref[i] = 0;
   }
}
