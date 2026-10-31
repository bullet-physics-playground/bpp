/*
 * CouettePhysics.java
 *
 * Created on October 18, 2003, 7:46 PM
 */
package ktphysics;

import java.io.*;
import java.util.*;

import shared.MyLong;
import shared.ObstacleContainer;
import shared.Obstacle;
import shared.SquareObstacle;
import shared.Point;
import shared.PC;

import shared.PhysicsInterface;

/**
 *
 * @author  Wesley Kerr
 */
public class CouettePhysics extends PhysicsInterface
{
   public final double boltz = 1.3806e-23;  // Boltzmann's constant (J/K)
   public double mass = 6.63e-26;     // Mass of argon atom (kg)
   public double diam = 3.66e-10;     // Effective diameter of argon atom (m)
   //public double T = 273;             // Temperature (K)
   public double density = 2.685e25;  // Number density of argon at STP (m^-3)
   //public double L = 1e-6;            // System size is one micron
   //public double Volume = L*L;        // Volume of the system 2D

   public int npart;

   private double eff_num;
   private double mfp;

   public double mpv;
   public double vwallL_m;
   public double vwallR_m;
   public double vwallL;
   public double vwallR;

   public double[][] x_old;

   public int[] dir;

   public double tau;

   private double[][] vrmax;
   private double[][] selxtra;

   private double coeff;

   private SortList sortData;
   public MyLong seed;

   public Obstacle obstacle;

   /** Creates a new instance of CouettePhysics */
   public CouettePhysics()
   {
      super();

      PC.L = 1e-6;

      npart = PC.npart;
      // Initialize constants (particle mass, diameter, etc.)
      eff_num = density*PC.L*PC.L/npart;
      //System.out.println("Each particle represents " + eff_num + " atoms ");

      double Volume = PC.L*PC.L;
      mfp = Volume/(Math.sqrt(2.0)*Math.PI*diam*npart*eff_num);
      System.out.println("System width is " + PC.L/mfp + " mean free paths");

      mpv = Math.sqrt(2.0*boltz*PC.T/mass);  // Most probable initial velocity
      //System.out.println("vwallL_m " + PC.vwallL_m + " vwallR_m " + PC.vwallR_m);
      vwallL_m = 0;                // Wall velocity as Mach number
      vwallR_m = 0;
      vwallL = vwallL_m * Math.sqrt(5.0/3.0 * boltz * PC.T / mass);
      vwallR = vwallR_m * Math.sqrt(5.0/3.0 * boltz * PC.T / mass);

      // Assign random positions and velocities to particles
      x_old = new double[npart][2];
      dir = new int[npart];

      seed = new MyLong();
      GregorianCalendar g = new GregorianCalendar();
      seed.seed = g.getTime().getTime();
      //System.out.println("RANDOM SEED: " + seed.seed);

      for (int i = 0; i < npart; ++i)
      {
         // Assign random positions in the square 0-L in x and 0-L in y
         x[i][0] = PC.L*PC.rand(seed);
         x[i][1] = PC.L*PC.rand(seed);

         // Initial velocities are Maxwell-Boltzmann distributed
         v[i][0] = Math.sqrt(boltz*PC.T/mass) * PC.randn(seed);
         v[i][1] = Math.sqrt(boltz*PC.T/mass) * PC.randn(seed);

      }

      // Initialize variables used for evaluating collisions
      tau = 0.2*(PC.L/PC.ncell_x)/mpv;

      vrmax = new double[PC.ncell_y][PC.ncell_x];
      for (int i = 0; i < PC.ncell_y; ++i)
         for (int j = 0; j < PC.ncell_x; ++j)
            vrmax[i][j] = 3*mpv;      // Estimated max rel. speed

      selxtra = new double[PC.ncell_y][PC.ncell_x];
      for (int i = 0; i < PC.ncell_y; ++i)
         for (int j = 0; j < PC.ncell_x; ++j)
            selxtra[i][j] = 0;        // Used by routine "colider"

      coeff = 0.5*eff_num*Math.PI*diam*diam*tau/(PC.L*PC.L/(double)PC.ncell_x);

      // Declare object for lists used in sorting
      sortData = new SortList(PC.ncell_x, PC.ncell_y, npart);

   }

   public void timeStep()
   {
      //outsideParticles("Before Mover");
      Mover.mover(x, x_old, v, mpv, vwallL, vwallR, tau, seed, dir, particleDone);
      //outsideParticles("After Mover");
      Sorter.sorter(x, PC.L, sortData);
      //outsideParticles("After Sorter");
      Colider.colider(v, vrmax, tau, selxtra, coeff, sortData, seed);
      //outsideParticles("After Colider");
   }
}
