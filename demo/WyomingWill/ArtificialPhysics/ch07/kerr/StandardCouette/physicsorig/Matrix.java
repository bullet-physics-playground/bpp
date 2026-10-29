
package physicsorig;

public class Matrix 
{

   // Default Constructor. Creates a 1 by 1 matrix; sets value to zero. 
   public Matrix () 
   {
      nRow_ = 1; nCol_ = 1;
      data_ = new double [1];  // Allocate memory
      set(0.0);                // Set value of data_[0] to 0.0
   }

   public Matrix(int nR)
   {
      nRow_ = nR; 
      nCol_ = 1;
      data_ = new double [nRow_*nCol_];  // Allocate memory

      set(0.0);                    // Set values of data_[] to 0.0
   }
   
   // Regular Constructor. Creates an nR by nC matrix; sets values to zero.
   // If number of columns is not specified, it is set to 1.
   public Matrix(int nR, int nC) 
   {
      nRow_ = nR; 
      nCol_ = nC;
      data_ = new double [nR*nC];  // Allocate memory

      set(0.0);                    // Set values of data_[] to 0.0
   }

   // Simple "get" functions. Return number of rows or columns.
   public int nRow() { return nRow_; }
   public int nCol() { return nCol_; }


   // Parenthesis operator function.
   // Allows access to values of Matrix via (i,j) pair.
   // Example: a(1,1) = 2*b(2,3); 
   // If column is unspecified, take as 1.
   public double get(int i, int j)
   {
      return data_[ nCol_*(i-1) + (j-1) ];  // Access appropriate value
   }
   
   public double get(int i)
   {
      int j = 1;
      return data_[ nCol_*(i-1) + (j-1) ];  // Access appropriate value
   }
      
   public void set(int i, int j, double value)
   {
      data_[ nCol_*(i-1) + (j-1) ] = value;
   }

   public void set(int i, double value)
   {
      int j = 1;
      data_[ nCol_*(i-1) + (j-1) ] = value;
   }
   
   public void inc(int i, int j, double value)
   {
      data_[ nCol_*(i-1) + (j-1) ] += value;
   }
   
   public void inc(int i, double value)
   {
      int j = 1;
      data_[ nCol_*(i-1) + (j-1) ] += value;
   }
      
   public void set(double value) 
   {
     int i;
     int iData = nRow_*nCol_;

     for( i=0; i<iData; i++ )
       data_[i] = value;
   }
   
   public void copy(Matrix x)
   {
      for (int i = 1; i <= x.nCol_; ++i)
      {
         for (int j = 1; j <= x.nRow_; ++j)
         {
            set(i, j, x.get(i, j));
         }
      }
   }

   private int nRow_, nCol_;  // Number of rows, columns
   private double[] data_;     // Pointer used to allocate memory for data.

} // Class Matrix



