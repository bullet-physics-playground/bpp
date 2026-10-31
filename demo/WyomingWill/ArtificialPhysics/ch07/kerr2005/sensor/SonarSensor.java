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

import math.Intersection;
import util.Logger;
/**
 *
 * @author  Wesley Kerr
 */
public class SonarSensor {

    public static float r = 3.0f;
    public static float max = 60.0f;

    private int robotId;
    private Logger log;

    private float[] thetas;
    private float[] distances;

    private float separation;

    /** Creates a new instance of RobotSensor */
    public SonarSensor(int id, int numSonar) {
        robotId = id;
        log = Logger.inst();

        thetas = new float[numSonar];
        distances = new float[numSonar];

        separation = 360.0f / (float) numSonar;
    }

    public float findSensorReading(float angle) {
        if (angle < 0) {
            angle += 360;
        }

        return fireSonar(angle);
    }

    public void findSensorReadings() {

        for (int i = 0; i < thetas.length; ++i) {
            sonar(i, separation*i);
        }
    }

    private void sonar(int sonarId, float angle) {
        thetas[sonarId] = angle;
        distances[sonarId] = max;

        double[][] positions = Environment.inst().getPositions();
        double[] bearings = Environment.inst().getBearings();

        double sonarBearing = thetas[sonarId] + bearings[robotId];

        float robotRadius = Environment.robotDiameter / 2.0f;
        float x1 = (float) positions[robotId][0] + (robotRadius*(float)Math.cos(Math.toRadians(sonarBearing)));
        float y1 = (float) positions[robotId][1] + (robotRadius*(float)Math.sin(Math.toRadians(sonarBearing)));
        float x2 = (max)*(float) Math.cos(Math.toRadians(sonarBearing)) + x1;
        float y2 = (max)*(float) Math.sin(Math.toRadians(sonarBearing)) + y1;

        for (int i = 0; i < positions.length; ++i) {
            if (i == robotId) {
                continue;
            }

            float distance = Intersection.circleIntersect(x1, y1, x2, y2, (float) positions[i][0], (float) positions[i][1], r);

            if (distance != max) {
                distance -= robotRadius;
            }

            if (distance < distances[sonarId]) {
                distances[sonarId] = distance;
            }
        }

        x1 = (float) positions[robotId][0];
        y1 = (float) positions[robotId][1];
        x2 = (max)*(float) Math.cos(Math.toRadians(sonarBearing)) + x1;
        y2 = (max)*(float) Math.sin(Math.toRadians(sonarBearing)) + y1;

        float width = Environment.inst().getWidth();
        float height = Environment.inst().getHeight();

        float distance = Intersection.lineIntersect(x1, y1, x2, y2, 0, 0, width, 0);
        if (distance < distances[sonarId])
            distances[sonarId] = distance;

        distance = Intersection.lineIntersect(x1, y1, x2, y2, 0, 0, 0, height);
        if (distance < distances[sonarId])
            distances[sonarId] = distance;

        distance = Intersection.lineIntersect(x1, y1, x2, y2, width, height, width, 0);
        if (distance < distances[sonarId])
            distances[sonarId] = distance;

        distance = Intersection.lineIntersect(x1, y1, x2, y2, width, height, 0, height);
        if (distance < distances[sonarId])
            distances[sonarId] = distance;

        Iterator iter = ObstacleContainer.inst().getObstacles().iterator();
        while (iter.hasNext()) {
            Obstacle o = (Obstacle) iter.next();
            distance = o.intersect(x1, y1, x2, y2);
            if (distance != max) {
                distance -= 3;
            }

            if (distance < 0) {
                Environment.inst().logSonarInformation(robotId, distances[sonarId], thetas[sonarId]);
            }
            if (distance < distances[sonarId]) {
                distances[sonarId] = distance;
            }
        }

        distances[sonarId] = distances[sonarId] < 0 ? 0 : distances[sonarId];
    }

    private float fireSonar(float angle) {
        double maxDistance = max;

        double[][] positions = Environment.inst().getPositions();
        double[] bearings = Environment.inst().getBearings();

        double sonarBearing = angle + bearings[robotId];

        float robotRadius = Environment.robotDiameter / 2.0f;
        float x1 = (float) positions[robotId][0] + (robotRadius*(float)Math.cos(Math.toRadians(sonarBearing)));
        float y1 = (float) positions[robotId][1] + (robotRadius*(float)Math.sin(Math.toRadians(sonarBearing)));
        float x2 = (max)*(float) Math.cos(Math.toRadians(sonarBearing)) + x1;
        float y2 = (max)*(float) Math.sin(Math.toRadians(sonarBearing)) + y1;

        for (int i = 0; i < positions.length; ++i) {
            if (i == robotId) {
                continue;
            }

            float distance = Intersection.circleIntersect(x1, y1, x2, y2, (float) positions[i][0], (float) positions[i][1], r);

            if (distance != max) {
                distance -= robotRadius;
            }

            if (distance < maxDistance) {
                maxDistance = distance;
            }
        }

        x1 = (float) positions[robotId][0];
        y1 = (float) positions[robotId][1];
        x2 = (max)*(float) Math.cos(Math.toRadians(sonarBearing)) + x1;
        y2 = (max)*(float) Math.sin(Math.toRadians(sonarBearing)) + y1;

        float width = Environment.inst().getWidth();
        float height = Environment.inst().getHeight();

        float distance = Intersection.lineIntersect(x1, y1, x2, y2, 0, 0, width, 0);
        if (distance < maxDistance)
            maxDistance = distance;

        distance = Intersection.lineIntersect(x1, y1, x2, y2, 0, 0, 0, height);
        if (distance < maxDistance)
            maxDistance = distance;

        distance = Intersection.lineIntersect(x1, y1, x2, y2, width, height, width, 0);
        if (distance < maxDistance)
            maxDistance = distance;

        distance = Intersection.lineIntersect(x1, y1, x2, y2, width, height, 0, height);
        if (distance < maxDistance)
            maxDistance = distance;

        Iterator iter = ObstacleContainer.inst().getObstacles().iterator();
        while (iter.hasNext()) {
            Obstacle o = (Obstacle) iter.next();
            distance = o.intersect(x1, y1, x2, y2);
            if (distance != max) {
                distance -= 3;
            }

            if (distance < maxDistance) {
                maxDistance = distance;
            }
        }

        maxDistance = maxDistance < 0 ? 0 : maxDistance;
        return (float) maxDistance;
    }

    public float[] getDistances() {
        return distances;
    }

    public float[] getBearings() {
        return thetas;
    }
}
