#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

long int rrandom (long int high)
{
  long random();
  return( random() % high + 1 );
}

// Return a random real from (0.0 1.0).
double u01 ()
{
  return( ( double )rrandom( 1073741823 ) / 1073741824.0 );
}

int main( int argc, char** argv )
{
  int i, N;
  double sum, x1, x2, y1, y2;
  double buffer;

  srandom(1);
  N = 500000000;
  sum = 0.0;
  buffer = 0.05;

  for (i = 1; i <= N; i++) {
    // Assume sensing radius of 1 in a cell of size 20, in essence.
    x1 = buffer + ((1.0 - 1.0 * buffer) * u01());
    x2 = 1.0000000001;
    y1 = buffer + ((1.0 - 2.0 * buffer) * u01());
    y2 = buffer + ((1.0 - 2.0 * buffer) * u01());
    sum = sum + sqrt((x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1));
  }
  printf("Average length = %f\n", sum/N);

  return 0;   /* ISO C requires main to return int. */
}
