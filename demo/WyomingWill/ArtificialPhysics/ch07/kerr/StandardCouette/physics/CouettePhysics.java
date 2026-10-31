/*
 * CouettePhysics.java
 *
 * Created on October 18, 2003, 7:46 PM
 */
package physics;

import java.io.*;
/**
 *
 * @author  Wesley Kerr
 */
public class CouettePhysics
{
   public final double boltz = 1.3806e-23;  // Boltzmann's constant (J/K)
   public double mass = 6.63e-26;     // Mass of argon atom (kg)
   public double diam = 3.66e-10;     // Effective diameter of argon atom (m)
   public double T = 273;             // Temperature (K)
   public double density = 2.685e25;  // Number density of argon at STP (m^-3)
   public double L = 1e-6;            // System size is one micron
   public double Volume = L*L;       // Volume of the system

   public int npart;

   private double eff_num;
   private double mfp;
   private double mpv;
   public double vwall_m;
   public double vwall;

   public double[][] x;
   public double[][] x_old;
   public double[][] v;

   private int ncell_x;
   private int ncell_y;
   public double tau;

   private double[][] vrmax;
   private double[][] selxtra;

   private double coeff;
   private int colSum = 0;                 // Count total collisions
   int[] strikeSum = new int[2];

   private SortList sortData;
   public MyLong seed;

   /** Creates a new instance of CouettePhysics */
   public CouettePhysics()
   {
      npart = PhysicsConstants.npart;
      // Initialize constants (particle mass, diameter, etc.)
      eff_num = density*L*L/npart;
      System.out.println("Each particle represents " + eff_num + " atoms ");

      mfp = Volume/(Math.sqrt(2.0)*Math.PI*diam*npart*eff_num);
      System.out.println("System width is " + L/mfp + " mean free paths");

      mpv = Math.sqrt(2.0*boltz*T/mass);  // Most probable initial velocity
      vwall_m = PhysicsConstants.vwall_m;  // Wall velocity as Mach number
      vwall = vwall_m * Math.sqrt(5.0/3.0 * boltz * T / mass);

      System.out.println("Wall velocities are " + -1.0*vwall + " and " + vwall + " m/s ");

      // Assign random positions and velocities to particles
      x = new double[npart][2];
      x_old = new double[npart][2];
      v = new double[npart][2];

      seed = new MyLong();
      seed.seed = 1;

      for (int i = 0; i < npart; ++i)
      {
         // Assign random positions in the square 0-L in x and 0-L in y
         // Assign random positions in the square 0-L in x and 0-L in y
         x[i][0] = L*Rand.rand(seed);
         x[i][1] = L*Rand.rand(seed);

         // Initial velocities are Maxwell-Boltzmann distributed
         v[i][0] = Math.sqrt(boltz*T/mass) * Randn.randn(seed);
         v[i][1] = Math.sqrt(boltz*T/mass) * Randn.randn(seed);

         // Add velocity gradient to the y-component
         v[i][1] = v[i][1] + vwall * 2* (x[i][0]/L);
      }

      // Initialize variables used for evaluating collisions
      ncell_x = 20;               // Number of cells
      ncell_y = 200;
      tau = 0.2*(L/ncell_x)/mpv;

      vrmax = new double[ncell_y][ncell_x];
      for (int i = 0; i < ncell_y; ++i)
         for (int j = 0; j < ncell_x; ++j)
            vrmax[i][j] = 3*mpv;      // Estimated max rel. speed

      selxtra = new double[ncell_y][ncell_x];
      for (int i = 0; i < ncell_y; ++i)
         for (int j = 0; j < ncell_x; ++j)
            selxtra[i][j] = 0;        // Used by routine "colider"

      coeff = 0.5*eff_num*Math.PI*diam*diam*tau/(L*L/ncell_x);

      // Declare object for lists used in sorting
      sortData = new SortList(ncell_x, ncell_y, npart);

      strikeSum[0] = 0;
      strikeSum[1] = 0;
      colSum = 0;

   }

   public void timeStep()
   {
      // Loop for the desired number of time steps
      int[] strikes = new int[2];

      for (int i = 0; i < 2; ++i)
         strikes[i] = 0;            // Count strikes at each wall

      // Move all the particles
      double[] delv = new double[2];
      delv[0] = delv[1] = 0;

      Mover.mover(x, x_old, v, npart, L, mpv, vwall, tau, strikes, delv, seed);
      strikeSum[0] += strikes[0];
      strikeSum[1] += strikes[1];

      // Sort the particles into cells
      Sorter.sorter(x, L, sortData);

      // Evaluate collisions among the particles
      //int col = Colider.colider(x, x_old, v, vrmax, tau, selxtra, coeff);
      int col = Colider.colider(v, vrmax, tau, selxtra, coeff, sortData, seed);
      colSum += col;           //  Increment collision count

      // Periodically display the current progress
      System.out.println("Strikes L " + strikeSum[0] + " R " + strikeSum[1]);
      System.out.println("Collisions " + colSum);
   }
}