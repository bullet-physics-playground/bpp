#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

double f (x, z, y)
     //double f (x, y, z)
double x, y, z;
{

  double term, temp1, temp2, sqrt(), log();
  
  term = sqrt(y*y - 2*z*y + (1.0-x)*(1.0-x) + z*z);

  temp1 = 3*y*y*y*y - 28*z*y*y*y + 42*z*z*y*y;
  temp1 = temp1 - 36*(1.0-x)*term*y*y - 28*z*z*z*y;

  if ((((1.0-x) == 0) || (y == 0)) && ((-y + z + term) == 0)) {}
  else temp1 = temp1 + 48*(1.0-x)*(1.0-x)*(1.0-x)*log(-y + z + term)*y;

  temp1 = temp1 + 72*(1.0-x)*z*term*y;

  if (((y - z) == 0) && (((1.0-x) + term) == 0)) {}
  else temp1 = temp1 - 12*(y-z)*(y-z)*(y-z)*(y-z)*log((1.0-x) + term);

  if ((((1.0-x) == 0) || (z == 0)) && ((y - z + term) == 0)) {}
  else temp1 = temp1 + 48*(1.0-x)*(1.0-x)*(1.0-x)*z*log(y - z + term);
  
  temp1 = temp1 + 24*(1.0-x)*(1.0-x)*(1.0-x)*term;

  temp1 = temp1 - 36*(1.0-x)*z*z*term;

  return(-temp1/288.0);
}

int main( int argc, char** argv )
{
  double temp, f();

  printf("%f\n", f(0.0,0.0,0.0));
  printf("%f\n", f(0.0,0.0,1.0));
  printf("%f\n", f(0.0,1.0,0.0));
  printf("%f\n", f(0.0,1.0,1.0));
  printf("%f\n", f(1.0,0.0,0.0));
  printf("%f\n", f(1.0,0.0,1.0));
  printf("%f\n", f(1.0,1.0,0.0));
  printf("%f\n", f(1.0,1.0,1.0));

  // No buffer zone - agent can get as close to wall as possible
  printf("solution = %f\n",
	 f(1.0,1.0,1.0) - f(1.0,0.0,1.0) - f(0.0,1.0,1.0) + f(0.0,0.0,1.0) -
	 f(1.0,1.0,0.0) + f(1.0,0.0,0.0) + f(0.0,1.0,0.0) - f(0.0,0.0,0.0));

  // This includes a 5% buffer zone, i.e., response range is 1
  // when cell size = 20. Must renormalize by 1/(b-a) for all 3 integrals
  printf("solution = %f\n",
	 (1.0/0.95)*(1.0/0.90)*(1.0/0.90)*
	 (f(1.00,0.95,0.95) - f(1.00,0.05,0.95) - 
	  f(0.05,0.95,0.95) + f(0.05,0.05,0.95) -
	  f(1.00,0.95,0.05) + f(1.00,0.05,0.05) + 
	  f(0.05,0.95,0.05) - f(0.05,0.05,0.05)));

  return 0;   /* ISO C requires main to return int. */
}
