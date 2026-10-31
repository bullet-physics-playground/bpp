package robot;

/*
 * APRobot.java
 *
 * Created on July 27, 2004, 10:19 AM
 */

import env.Environment;

import java.awt.Color;

import sensor.GoalSensor;
import sensor.RodSensor;
import sensor.SonarSensor;

import util.Logger;
/**
 *
 * @author  Wesley Kerr
 */
public class LJRobot extends Robot {

    public static final float E = 1.0f;

    public static final float R = 20;
    public float delta_t = 1.0f;
    public float FMAX = 1.5f;

    private float FR = 0.0f;

    public float distance;
    public float turn;

    public Color color;

    /** Creates a new instance of APRobot */
    public LJRobot() {
        super();
        distance = 0;
        turn = 0;
    }

    public void move() {

        turn = 0;

        float vx = 0;
        float vy = 0;

        float[] robotF = findRobotForce();

        float deltavx = robotF[0];
        float deltavy = robotF[1];

        vx = vx + deltavx;
        vy = vy + deltavy;

        float deltax = vx * delta_t;
        float deltay = vy * delta_t;

        distance = (float) Math.sqrt(deltax*deltax + deltay*deltay);
        if (distance > VMAX) {
            distance = VMAX;
        }

        turn = (float) Math.toDegrees(Math.atan2(deltay, deltax));
    }

    private float[] findRobotForce() {
        float[] sum_f = new float[2];

        RodSensor rs = new RodSensor(id);
        rs.findVisibleRobots();
        float[] distances = rs.getDistances();
        float[] thetas    = rs.getBearings();
        int[] ids         = rs.getIds();

        if (distances == null) {
            sum_f[0] = 0;
            sum_f[1] = 0;
            return sum_f;
        }

        for (int index = 0; index < distances.length; ++index) {  // For all the neighboring robots do:
            float theta = thetas[index];                          // get the bearing
            float r = distances[index];                           // and the distance

            if (r > 2.0*R)
                continue;

            float lhs = (float) (Math.pow(R, 6.0) / Math.pow(r, 7.0));
            float rhs = (float) (2*(Math.pow(R, 12.0) / Math.pow(r, 13.0)));

            float F = 24*E*(lhs - rhs);

            if (F > FMAX) F = FMAX;
            if (F < -FMAX) F = -FMAX;

            float fx = (float) (F * Math.cos(Math.toRadians(theta)));
            float fy = (float) (F * Math.sin(Math.toRadians(theta)));

            sum_f[0] += fx;
            sum_f[1] += fy;
        }

        return sum_f;
    }

    public float getDistance() {
        return distance;
    }

    public float getTurn() {
        return turn;
    }

    public float getSpeed() {
        return distance;
    }

}
