// ch07/KerrTrace.java -- ours, not Kerr's: one run of his 2005 corridor
// sweep (ch07/kerr2005/, with ch07/kerr2005_seed.diff applied) from a seed,
// printing the world's state every EVERY steps for ch07/kerr2005.lua to be
// compared with (checks/ch07.lua): per robot its position and bearing
// (Double.toString, which reads back exactly), then the covered cells.
//
//   java -Dkerr.seed=1 -cp OUT KerrTrace CONTROLLER N COURSE SEED STEPS EVERY
//
// COURSE is a course file under data/ (course_P_k.txt), or "none".
import env.Environment;
import env.Coverage;
import env.Parameters;
import robot.KTRobot;

public class KerrTrace {
  public static void main(String[] a) throws Exception {
    String controller = a[0]; int n = Integer.parseInt(a[1]);
    long seed = Long.parseLong(a[3]); int steps = Integer.parseInt(a[4]), every = Integer.parseInt(a[5]);
    String data = KerrTrace.class.getClassLoader().getResource("data/").getPath();
    Parameters p = new Parameters();
    p.robotType = "robot." + controller; p.n = n; p.sepRadius = 40;
    p.width = 1000; p.height = 5000; p.ncell_x = 50; p.ncell_y = 250;
    p.obstaclePath = a[2].equals("none") ? null : data + a[2];
    p.seed = seed;
    if (controller.equals("KTRobot")) KTRobot.wall = 0.4f;
    Environment e = Environment.inst();
    e.init(p);
    for (int t = 1; t <= steps; ++t) {
      e.timeStep();
      boolean going = e.continueGoing();
      if (t % every == 0 || !going) {
        double[][] r = e.getPositions(); double[] b = e.getBearings();
        System.out.println("t " + t);
        for (int i = 0; i < n; ++i) System.out.println(i + " " + r[i][0] + " " + r[i][1] + " " + b[i]);
        Coverage c = e.getCoverage();
        System.out.println("covered " + c.getCoverageCount() + " " + c.getBehindCoverageCount());
      }
      if (!going) break;
    }
  }
}
