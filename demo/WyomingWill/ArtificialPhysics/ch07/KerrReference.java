// ch07/KerrReference.java -- ours, not Kerr's: runs one of Kerr's 2004 gas
// simulators (ch07/kerr/<experiment>/ktphysics, with ch07/kerr_seed.diff
// applied) for a number of steps from a given seed, and prints the state, so
// that ch07/kerr.lua can be checked against the Java (ch07/kerr_reference.sh
// builds and runs it; the output is ch07/kerr_reference.txt).
//
//   java -Dkerr.seed=SEED -cp OUT experiments.KerrReference \
//        NPART NCELL_X NCELL_Y LENGTH T VWALL_L_MACH VWALL_R_MACH DIR0 DIR1 CLOSED STEPS EVERY
//
// The constants are the ones Kerr's own drivers set in shared.PC before
// creating the physics (experiments/NewPhysics.java, KTPhysics.java). Prints
// "colsum C" and then, for particles 0, EVERY, 2 EVERY, ..., "i x y vx vy"
// with every double in full (Double.toString round-trips).
package experiments;

import shared.PC;
import shared.PhysicsInterface;

public class KerrReference
{
   public static void main(String[] a) throws Exception
   {
      PC.L = 1e-6;
      PC.npart = Integer.parseInt(a[0]);
      PC.ncell_x = Integer.parseInt(a[1]);
      PC.ncell_y = Integer.parseInt(a[2]);
      PC.length = Integer.parseInt(a[3]);
      PC.T = Integer.parseInt(a[4]);
      PC.vwallL_m = Double.parseDouble(a[5]);
      PC.vwallR_m = Double.parseDouble(a[6]);
      PC.direction0 = Integer.parseInt(a[7]);
      PC.direction1 = Integer.parseInt(a[8]);
      PC.closed = Boolean.parseBoolean(a[9]);
      int steps = Integer.parseInt(a[10]);
      int every = Integer.parseInt(a[11]);
      PC.colSum = 0;
      PhysicsInterface p = (PhysicsInterface) Class.forName("ktphysics.CouettePhysics").newInstance();
      for (int k = 0; k < steps; ++k)
         p.timeStep();
      System.out.println("colsum " + PC.colSum);
      for (int i = 0; i < PC.npart; i += every)
         System.out.println(i + " " + p.x[i][0] + " " + p.x[i][1] + " " + p.v[i][0] + " " + p.v[i][1]);
   }
}
