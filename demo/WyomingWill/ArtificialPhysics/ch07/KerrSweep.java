// ch07/KerrSweep.java -- ours, not Kerr's: his 2005 corridor sweep
// (ch07/kerr2005/, with ch07/kerr2005_seed.diff applied) as his drivers
// experiments/IROS.java (obstacle sweep, 25 robots) and Thesis_2.java
// (robot sweep, 20% obstacles) run it, without their graphics, printing his
// log lines. His seeds: 100, 101, ... over the courses and runs in order
// (course c, run r: 100 + c RUNS0 + r, with RUNS0 = 10, his runs per
// course); RUNS <= 10 runs the first RUNS of them.
//
//   java -Dkerr.seed=1 -cp OUT KerrSweep CONTROLLER N PCT START END RUNS
//
// PCT 0 is the corridor without obstacles; otherwise data/course_PCT_c.txt.
import env.Environment;
import env.Coverage;
import env.Parameters;
import robot.KTRobot;

public class KerrSweep {
  public static void main(String[] a) throws Exception {
    String controller = a[0]; int n = Integer.parseInt(a[1]); int pct = Integer.parseInt(a[2]);
    int start = Integer.parseInt(a[3]), end = Integer.parseInt(a[4]), runs = Integer.parseInt(a[5]);
    String data = KerrSweep.class.getClassLoader().getResource("data/").getPath();
    Parameters p = new Parameters();
    p.robotType = "robot." + controller; p.n = n; p.sepRadius = 40;
    p.width = 1000; p.height = 5000; p.ncell_x = 50; p.ncell_y = 250;
    for (int c = start; c < end; ++c) {
      p.obstaclePath = pct == 0 ? null : data + "course_" + pct + "_" + c + ".txt";
      for (int r = 0; r < runs; ++r) {
        p.seed = 100 + c * 10 + r;
        if (controller.equals("KTRobot")) KTRobot.wall = 0.4f;
        Environment.inst().init(p);
        int t; boolean running = true;
        for (t = 0; t < 150000 && running; ++t) {
          Environment.inst().timeStep();
          if (!Environment.inst().continueGoing()) running = false;
        }
        Coverage cv = Environment.inst().getCoverage();
        System.out.println(controller + " Speed 0.4 N " + n + " Pct " + pct + " Course " + c + " Run " + r
          + " Behind " + (cv.getBehindCount() == 0 ? "0" : String.valueOf(cv.getBehindPct() * 100.0))
          + " Total " + cv.getCoveredPct() * 100 + " Time " + t);
      }
    }
  }
}
