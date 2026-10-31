package env;

/*
 * Environment.java
 *
 * Created on July 27, 2004, 10:18 AM
 */
import java.util.Random;
import java.util.List;
import java.util.LinkedList;
import java.util.Iterator;
import java.util.Arrays;

import obstacle.ObstacleContainer;

import util.Logger;
import robot.Robot;
import sensor.Message;
/**
 *
 * @author  Wesley Kerr
 */
public class Environment {

    public static int robotDiameter = 6;

    private String robotType = "robot.KTRobot";

    private int time = 0;

    private Random rand;

    private int width;
    private int height;

    private double[][] r;
    private double[][] v;      // only stored for experimental information
    private double[] bearing;  // Bearings are stored as Degrees instead of radians

    private Robot[] robots;
    private List[] messages;
    private boolean[][] ignoring;

    private int[] moveOrder;

    private List collisions;
    private List robotCollisions;

    private Coverage c;
    private Energy   energy;
    private Momentum momentum;
    private Trails   trails;

    private static Environment env;

    private Environment() {
    }

    public static Environment inst() {
        if (env == null) {
            env = new Environment();
        }
        return env;
    }

    public void init(Parameters p) {
        r = new double[p.n][2];
        v = new double[p.n][2];

        bearing   = new double[p.n];
        robots    = new Robot[p.n];
        messages  = new List[p.n];
        moveOrder = new int[p.n];

        for (int i = 0; i < p.n; ++i) {
            messages[i] = new LinkedList();
        }

        ignoring = new boolean[p.n][p.n];
        reset(p);
    }

    public void reset(Parameters p) {
        time = 0;

        clearMessages();
        width = p.width;
        height = p.height;

        if (p.seed == -1) {
            long seed = System.currentTimeMillis();
            rand = new Random(seed);
        } else {
            rand = new Random(p.seed);
        }

        ObstacleContainer.inst().clear();
        try {
            if (p.obstaclePath != null) {
                ObstacleContainer.inst().loadObstacles(p.obstaclePath);
            }
        } catch (Exception e) {
            System.out.println("ERROR loading obstacles " + e.getMessage());
            e.printStackTrace();
            // ignore error
        }

        c        = new Coverage(p);
        energy   = new Energy();
        momentum = new Momentum();
        trails   = new Trails(p);

        robotType = p.robotType;

        try {
            createRobots(p.robotType, p.sepRadius);
        } catch (Exception e) {
            System.out.println("Unable to create Robots - " + e.getMessage());
            e.printStackTrace();
            System.exit(-1);
        }
    }

    private void createRobots(String robotType, float sepRadius) throws Exception {

        // n is the number of robots per side of a perfect square with all the robots.
        int n = (int) Math.ceil(Math.sqrt(robots.length));

        int count = 0;
        for (int i = 0; i < n; ++i) {
            for (int j = 0; j < n && count < robots.length; ++j) {
                robots[count] = (Robot) Class.forName(robotType).newInstance();
                robots[count].setId(count);

                r[count][0] = j*sepRadius + 10;
                r[count][1] = i*sepRadius + 10;
                v[count][0] = 0;
                v[count][1] = 0;
                bearing[count] = rand.nextFloat()*360.0f;
                c.updateCoverage(r[count][0], r[count][1]);

                ++count;
            }
        }

        /*// create two populations of robots roughly equal size;
        int half = (int) Math.ceil(robots.length / 2.0);

        // number of robots per side of a perfect square
        int n = (int) Math.ceil(Math.sqrt(half));

        int count = 0;
        for (int i = 0; i < n; ++i) {
            for (int j = 0; j < n && count <= half; ++j) {
                robots[count] = (Robot) Class.forName(robotType).newInstance();
                robots[count].setId(count);

                r[count][0] = j*sepRadius + 100;
                r[count][1] = i*sepRadius + 50;
                v[count][0] = 0;
                v[count][1] = 0;
                bearing[count] = rand.nextFloat()*360.0f;
                c.updateCoverage(r[count][0], r[count][1]);

                ++count;
            }
        }

        for (int i = 0; i < n; ++i) {
            for (int j = 0; j < n && count < robots.length; ++j) {
                robots[count] = (Robot) Class.forName(robotType).newInstance();
                robots[count].setId(count);

                r[count][0] = j*sepRadius + 250;
                r[count][1] = i*sepRadius + 50;
                v[count][0] = 0;
                v[count][1] = 0;
                bearing[count] = rand.nextFloat()*360.0f;
                c.updateCoverage(r[count][0], r[count][1]);

                ++count;
            }
        }*/

    }

    public double pctRobotsDone() {
        double count = countRobotsDone();
        return count / (double) robots.length;
    }

    public int countRobotsDone() {
        int count = 0;
        for (int i = 0; i < robots.length; ++i) {
            if (robots[i].isDone() || robots[i].isCloseToGoal()) {
                ++count;
            }
        }
        return count;
    }

    public boolean continueGoing() {
        for (int i = 0; i < robots.length; ++i) {
            if (!robots[i].isDone() && !robots[i].isCloseToGoal()) {
                return true;
            }
        }
        return false;
    }

    public void timeStep() {

        //System.out.println("Time: " + time);
        for (int i = 0; i < robots.length; ++i) {
            Arrays.fill(ignoring[i], false);
            moveOrder[i] = i;
        }

        robotCollisions = new LinkedList();
        collisions = new LinkedList();

        for (int i = 0; i < 100; ++i) {
            int i1 = rand.nextInt(robots.length);
            int i2 = rand.nextInt(robots.length);

            int temp = moveOrder[i1];
            moveOrder[i1] = moveOrder[i2];
            moveOrder[i2] = temp;
        }

        for (int i = 0; i < robots.length; ++i) {
            moveRobot(moveOrder[i]);
        }

        ++time;

        energy.finishTimeStep();
        momentum.finishTimeStep();

        clearMessages();
        checkRobots();

        //trails.print(r);
    }

    private void moveRobot(int i) {
        robots[i].move();
        bearing[i] += robots[i].getTurn();

        maintainBearing(i);

        double d = (double) robots[i].getDistance();
        double deltax = (d*Math.cos(Math.toRadians(bearing[i])));
        double deltay = (d*Math.sin(Math.toRadians(bearing[i])));

        r[i][0] += deltax;
        r[i][1] += deltay;

        v[i][0] = deltax;
        v[i][0] = deltay;

        containInWorld(i);

        c.updateCoverage(r[i][0], r[i][1]);
        energy.addEnergy(Math.sqrt(deltax*deltax + deltay*deltay));
        momentum.addMomentum(deltax, deltay);

        logRobotInformation(i, 6);
    }

    private void containInWorld(int i) {
        if (r[i][0] < 0) {
            logOutOfBoundsError(i);
            r[i][0] = 3.0f;
        } else if (r[i][0] > width) {
            logOutOfBoundsError(i);
            r[i][0] = width - 3.0f;
        }

        if (r[i][1] < 0) {
            logOutOfBoundsError(i);
            r[i][1] = 3.0f;
        } else if (r[i][1] > height) {
            logOutOfBoundsError(i);
            r[i][1] = height - 3.0f;
        }
    }

    private void maintainBearing(int i) {
        while (bearing[i] > 360) {
            bearing[i] -= 360;
        }

        while (bearing[i] < -360) {
            bearing[i] += 360;
        }
    }

    private void clearMessages() {
        for (int i = 0; i < messages.length; ++i) {
            messages[i].clear();
        }
    }

    private void checkRobots() {
        if (!Logger.inst().isDebugLevelOn(0)) {
            return;
        }

        for (int i = 0; i < robots.length; ++i) {

            containInWorld(i);

            for (int j = i+1; j < robots.length; ++j) {
                float distance = (float) Math.sqrt(Math.pow(r[i][0] - r[j][0], 2) +
                Math.pow(r[i][1] - r[j][1], 2));
                if (distance < robotDiameter) {
                    StringBuffer buf = new StringBuffer();
                    buf.append("TimeStep " + time + " ");
                    buf.append("ErrorRobotCollision ");
                    buf.append("Robot1 " + i + " x1 " + r[i][0] + " y1 " + r[i][1] + " ");
                    buf.append("Robot2 " + j + " x2 " + r[i][0] + " y2 " + r[i][1] + " ");
                    Logger.inst().log(0, buf.toString());
                }
            }
        }
    }

    private void logRobotInformation(int i, int level) {
        if (Logger.inst().isDebugLevelOn(level)) {
            return;
        }

        StringBuffer buf = new StringBuffer();
        buf.append("TimeStep " + time + " ");
        buf.append("Robot " + i + " ");
        buf.append("x " + r[i][0] + " y " + r[i][1] + " ");
        buf.append("vx " + v[i][0] + " vy " + v[i][1] + " ");
        buf.append("radians " + bearing[i] + " ");
        buf.append("degrees " + Math.toDegrees(bearing[i]) + " ");
        Logger.inst().log(level, buf.toString());
    }

    private void logOutOfBoundsError(int i) {
        StringBuffer buf = new StringBuffer();
        buf.append("TimeStep " + time + " ");
        buf.append("ErrorOutOfBounds ");
        buf.append("Robot " + i + " ");
        buf.append("x " + r[i][0] + " y " + r[i][1] + " ");
        buf.append("bearing " + bearing[i] + " ");
        Logger.inst().log(0, buf.toString());
    }

    public int getWidth() {
        return width;
    }

    public int getHeight() {
        return height;
    }

    public int getTime() {
        return time;
    }

    public int getNumRobots() {
        return robots.length;
    }

    public String getRobotType() {
        return robotType;
    }

    public double[][] getPositions() {
        return r;
    }

    public double[][] getVelocities() {
        return v;
    }

    public double[] getBearings() {
        return bearing;
    }

    public Robot getRobot(int id) {
        for (int i = 0; i < robots.length; ++i) {
            if (robots[i].id == id) {
                return robots[i];
            }
        }
        return null;
    }

    public void addMessage(Message m) {
        messages[m.recieverId].add(m);
    }

    public List getMessages(int robotId) {
        return messages[robotId];
    }

    public Coverage getCoverage() {
        return c;
    }

    public Trails getTrails() {
        return trails;
    }

    public void addWallCollision(int robotId, float[] bearings) {
        WallCollisionInfo ci = new WallCollisionInfo(robotId, bearings);
        collisions.add(ci);
    }

    public void addRobotCollision(int id, int coId, float thetaab, float thetaba,
                                  float alpha, float cos_th, float coVx, float coVy,
                                  float vx, float vy, float finalvx, float finalvy,
                                  float finalCoVx, float finalCoVy) {
        RobotCollisionInfo ri = new RobotCollisionInfo();
        ri.id = id;
        ri.coId = coId;
        ri.thetaab = thetaab;
        ri.thetaba = thetaba;
        ri.alpha = alpha;
        ri.cos_th = cos_th;
        ri.coVx = coVx;
        ri.coVy = coVy;
        ri.vx = vx;
        ri.vy = vy;
        ri.finalvx = finalvx;
        ri.finalvy = finalvy;
        ri.finalCoVx = finalCoVx;
        ri.finalCoVy = finalCoVy;
        robotCollisions.add(ri);
    }

    private void logCollisions() {
        Iterator iter = collisions.iterator();
        while (iter.hasNext()) {
            WallCollisionInfo ci = (WallCollisionInfo) iter.next();
            StringBuffer buf = new StringBuffer();
            buf.append("Robot " + ci.robotId + " ");
            buf.append("x " + r[ci.robotId][0] + " y " + r[ci.robotId][1] + " ");
            buf.append("Bearing " + bearing[ci.robotId] + " ");
            buf.append("GoalBearing " + (90 - bearing[ci.robotId]) + " ");

            int wall = 0;
            if (r[ci.robotId][1] < 9.0) {
                wall = 0; // Top wall
            } else if (r[ci.robotId][0] < 9.0) {
                wall = 1; // Left wall
            } else if (r[ci.robotId][0] > getWidth() - 9.0) {
                wall = 2; // Right wall
            } else {
                wall = 3; // Bottom wall
            }

            buf.append("Wall " + wall + " ");
            Logger.inst().log(9, buf.toString() + "Sensor45 " + ci.distances[3] + " ");
            Logger.inst().log(9, buf.toString() + "Sensor30 " + ci.distances[2] + " ");
            Logger.inst().log(9, buf.toString() + "Sensor15 " + ci.distances[1] + " ");
            Logger.inst().log(9, buf.toString() + "Sensor0 " + ci.distances[0] + " ");
            Logger.inst().log(9, buf.toString() + "Sensor345 " + ci.distances[23] + " ");
            Logger.inst().log(9, buf.toString() + "Sensor330 " + ci.distances[22] + " ");
            Logger.inst().log(9, buf.toString() + "Sensor315 " + ci.distances[21] + " ");
        }

        iter = robotCollisions.iterator();
        while (iter.hasNext()) {
            RobotCollisionInfo ri = (RobotCollisionInfo) iter.next();
            StringBuffer buf = new StringBuffer();
            buf.append("t " + time + " ");
            buf.append("R1 " + ri.id + " ");
            buf.append("theta " + ri.thetaab + " ");
            buf.append("vx " + ri.vx + " vy " + ri.vy + " ");
            buf.append("vx' " + ri.finalvx + " vy' " + ri.finalvy + " ");
            Logger.inst().log(11, buf.toString());

            buf = new StringBuffer();
            buf.append("t " + time + " ");
            buf.append("R2 " + ri.coId + " ");
            buf.append("theta " + ri.thetaba + " ");
            buf.append("vx " + ri.coVx + " vy " + ri.coVy + " ");
            buf.append("vx' " + ri.finalCoVx + " vy' " + ri.finalCoVy + " ");

            //buf.append("theta " + ri.thetaba + " alpha " + ri.alpha + " ");
            //buf.append("cos " + ri.cos_th + " ");
            Logger.inst().log(11, buf.toString());
        }
    }

    public void logSonarInformation(int robotId, float distance, float theta) {
        if (!Logger.inst().isDebugLevelOn(12)) {
            return;
        }

        StringBuffer buf = new StringBuffer();
        buf.append("SonarForRobot " + robotId + " ");
        buf.append("r (" + r[robotId][0] + ", " + r[robotId][1] + " ");
        buf.append("d " + distance + " ");
        buf.append("theta " + theta);
        Logger.inst().log(12, buf.toString());
    }

    public void robotIgnoring(int sender, int reciever) {
        ignoring[reciever][sender] = true;
        ignoring[sender][reciever] = true;
    }

    public boolean[] getIgnoring(int robotId) {
        return ignoring[robotId];
    }
}
