/*
 * SonarSensor.java
 *
 * Created on July 27, 2004, 1:27 PM
 */

package sensor;

import java.util.List;
import java.util.LinkedList;
import java.util.Iterator;

import env.Environment;
import obstacle.ObstacleContainer;
import obstacle.Obstacle;

import robot.Robot;

import math.Intersection;
import util.Logger;
/**
 *
 * @author  Wesley Kerr
 */
public class IRSensor {

    public static float r = 3.0f;
    public static float max = 60.0f;

    private int robotId;
    private Logger log;

    private float[] thetas;
    private float[] distances;

    private float[] readings;

    /** Creates a new instance of RobotSensor */
    public IRSensor(int id, int numIR) {
        robotId = id;
        log = Logger.inst();

        readings = new float[numIR];
    }

    public void findSensorReadings() {

        float angle = 360.0f / (float) thetas.length;
        for (int i = 0; i < thetas.length; ++i) {
            ir(i, angle*i);
        }

        filterSensor();
    }

    private void ir(int sonarId, float angle) {
        double[][] positions = Environment.inst().getPositions();
        double[] bearings = Environment.inst().getBearings();

        double sonarBearing = angle + bearings[robotId];

        float x1 = (float) positions[robotId][0];
        float y1 = (float) positions[robotId][1];
        float x2 = max*(float) Math.cos(Math.toRadians(sonarBearing)) + x1;
        float y2 = max*(float) Math.sin(Math.toRadians(sonarBearing)) + y1;

        for (int i = 0; i < positions.length; ++i) {
            if (i == robotId) {
                continue;
            }

            float distance = Intersection.circleIntersect(x1, y1, x2, y2, (float) positions[i][0], (float) positions[i][1], r);

            if (distance < readings[sonarId]) {
                readings[sonarId] = distance;
            }
        }

        float width = Environment.inst().getWidth();
        float height = Environment.inst().getHeight();

        float distance = Intersection.lineIntersect(x1, y1, x2, y2, 0, 0, width, 0);
        if (distance < readings[sonarId])
            readings[sonarId] = distance;

        distance = Intersection.lineIntersect(x1, y1, x2, y2, 0, 0, 0, height);
        if (distance < readings[sonarId])
            readings[sonarId] = distance;

        distance = Intersection.lineIntersect(x1, y1, x2, y2, width, height, width, 0);
        if (distance < readings[sonarId])
            readings[sonarId] = distance;

        distance = Intersection.lineIntersect(x1, y1, x2, y2, width, height, 0, height);
        if (distance < readings[sonarId])
            readings[sonarId] = distance;

        List obstacles = ObstacleContainer.inst().getObstacles();
        Iterator iter = obstacles.iterator();
        while (iter.hasNext()) {
            Obstacle o = (Obstacle) iter.next();
            distance = o.intersect(x1, y1, x2, y2);
            if (distance < readings[sonarId]) {
                readings[sonarId] = distance;
            }
        }

        readings[sonarId] -= (Environment.robotDiameter / 2);
    }

    private void filterSensor() {
        averageSensorData();
        differentiateSensorData();
    }

    private void averageSensorData() {
        float curr;
        float that = readings[readings.length-1];
        float first = readings[0];

        for (int i = 0; i < readings.length-1; ++i) {
            curr = readings[i];
            readings[i] = that + curr + readings[(i+1)%readings.length];
            that = curr;
        }
        readings[readings.length-1] = that + readings[readings.length-1] + first;
    }

    private void differentiateSensorData() {
        float[] deriv = new float[readings.length];
        for (int i = 0; i < readings.length; ++i) {
            int prev = ((i-1)+readings.length)%readings.length;
            deriv[i] = readings[i] - readings[prev];
        }
    }

    public float[] getDistances() {
        return distances;
    }

    public float[] getBearings() {
        return thetas;
    }
}
