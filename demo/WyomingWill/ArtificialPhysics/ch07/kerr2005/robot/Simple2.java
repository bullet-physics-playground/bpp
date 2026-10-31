/*
 * Simple.java
 *
 * Created on January 12, 2005, 1:14 PM
 */

package robot;

import java.util.Random;
import java.util.ArrayList;
import java.util.Iterator;

import sensor.RodSensor;
import sensor.SonarSensor;
import sensor.GoalSensor;
/**
 *
 * @author  wkerr
 */
public class Simple2 extends Robot {

    private Random rand;

    private int   previous;
    private float distance;
    private float turn;
    private float divisor;

    private SonarSensor ss;
    private RodSensor   rs;
    private GoalSensor  gs;

    /** Creates a new instance of Simple */
    public Simple2() {
        super();

        distance = VMAX;
        turn = 0;
        previous = 0;

        divisor = 360.0f / 24.0f;
    }

    public void setId(int id) {
        this.id = id;

        rs = new RodSensor(id);
        ss = new SonarSensor(id, 24);
        gs = new GoalSensor(id);

        rand = new Random(System.currentTimeMillis() + id);
    }

    public float getDistance() {
        return distance;
    }

    public float getSpeed() {
        return distance;
    }

    public float getTurn() {
        return turn;
    }

    public void move() {

        rs.findVisibleRobots();
        float[] robotBearings = rs.getBearings();
        float[] robotDistances = rs.getDistances();

        ss.findSensorReadings();
        float[] bearings = ss.getBearings();
        float[] distances = ss.getDistances();

        float goal = gs.getGoalBearing();

        if (gs.nearGoal() && !startTimer) {
            startTimer = true;
            timer = 0;
        } else if (gs.nearGoal() && startTimer) {
            timer++;
        } else if (!gs.nearGoal() && startTimer) {
            startTimer = false;
        }

        if (timer >= 10 && gs.nearGoal()) {
            done = true;
            turn = 0;
            distance = 0;
            return;
        }

        while (goal < 0) {
            goal += 360.0f;
        }

        int choice = runAlgorithm(robotDistances, robotBearings, distances, goal);

        float newAngle = goal - (45.0f * (float)choice);
        while (newAngle < 0) {
            newAngle += 360;
        }

        turn = newAngle;
        distance = determineSafeDistance(ss, turn);
    }

    protected int runAlgorithm(float[] robotDistances, float[] robotBearings,
                               float[] distances, float goal) {
        ArrayList l = new ArrayList();
        double left = 1.0;
        double min  = 0;

        boolean[] options = getOptions(distances, goal);
        boolean[] blockedByRobots = areRobotsBlocking(robotDistances, robotBearings, goal);

        int previous = (int) Math.round(goal / 45.0f);
        previous = previous == 8 ? 0 : previous;
        if (options[previous]) {
            PctStorage pcs = new PctStorage(previous, 0, 0.8);
            l.add(pcs);
            min = 0.8;
            left -= 0.8;
        }

        double split = left / 3.0;
        if (!options[3] && options[2] && !blockedByRobots[3]) {
            PctStorage pcs = new PctStorage(2, min, min+split);
            l.add(pcs);
            min += split;
            left -= split;
        }

        if (!options[5] && options[6] && !blockedByRobots[5]) {
            PctStorage pcs = new PctStorage(6, min, min+split);
            l.add(pcs);
            min += split;
            left -= split;
        }

        split = left / 2.0;
        if (options[0]) {
            PctStorage pcs = new PctStorage(0, min, min+split);
            l.add(pcs);
            min += split;
            left -= split;
        }

        double count = countOptions(options);
        split = left / count;
        for (int j = 0; j < options.length; ++j) {
            if (options[j]) {
                PctStorage pcs = new PctStorage(j, min, min+split);
                l.add(pcs);
                min += split;
                left -= split;
            }
        }

        return chooseOption(l);
    }

    protected double countOptions(boolean[] options) {
        double count = 0;
        for (int i = 0; i < options.length; ++i) {
            if (options[i])
                ++count;
        }
        return count;
    }

    protected boolean[] areRobotsBlocking(float[] distances, float[] bearings, float goal) {
        boolean[] blockedByRobot = new boolean[8];

        if (distances == null)
            return blockedByRobot;

        float safeZone = 3*VMAX;
        for (int i = 0; i < distances.length; ++i) {
            if (distances[i] > safeZone) {
                continue;
            }

            while (bearings[i] < 0) {
                bearings[i] += 360;
            }
            int index = (int) Math.round((bearings[i]-goal) / 45.0f);
            index = (index == 8) ? 0 : index;
            if (index < 0) {
                index += 8;
            }
            blockedByRobot[index] = true;
        }
        return blockedByRobot;
    }

    protected boolean[] getOptions(float[] distances, float goal) {

        float safeZone = 3*VMAX;
        boolean[] options = new boolean[8];
        float angle = goal;
        for (int i = 0; i < 8; ++i) {
            int index = (int) Math.round(angle / divisor);
            index = (index == 24) ? 0 : index;
            if (distances[index] > safeZone) {
                options[i] = true;
            }

            angle -= 45.0f;
            if (angle < 0) {
                angle += 360.0f;
            }
        }
        return options;
    }

    protected int chooseOption(ArrayList l) {
        PctStorage pcs = new PctStorage(0, 0, 1);
        double random = rand.nextDouble();
        Iterator iter = l.iterator();
        while (iter.hasNext()) {
            PctStorage p = (PctStorage) iter.next();
            if (random >= p.min && random < p.max) {
                pcs = p;
            }
        }
        return pcs.index;
    }
}

class PctStorage {
    public int index;
    public double min;
    public double max;

    public PctStorage(int index, double min, double max) {
        this.index = index;
        this.min = min;
        this.max = max;
    }
}
