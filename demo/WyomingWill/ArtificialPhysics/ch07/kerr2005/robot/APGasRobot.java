package robot;

/*
 * APRobot.java
 *
 * Created on July 27, 2004, 10:19 AM
 */

import env.Environment;

import sensor.SonarSensor;
import sensor.GoalSensor;

import util.Logger;
/**
 *
 * @author  Wesley Kerr
 */
public class APGasRobot extends Robot {

    public float delta_t = 1.0f;
    public float VMAX = 5.0f;
    public float FMAX = 1.5f;
    public float G = 240.0f;
    public float R = 24.0f;

    public float goalForce = 0.09f;//0.25f;

    public float distance;
    public float turn;

    public float speed;

    /** Creates a new instance of APRobot */
    public APGasRobot() {
        super();
        distance = 0;
        turn = 0;

        speed = 0;
    }

    public void move() {

        if (isCompleted()) {
            distance = 0;
            turn = 0;
            return;
        }

        float theta;
        float r, F, fx, fy, sum_fx = 0, sum_fy = 0;
        float deltavx, deltavy, deltax, deltay;
        float vx, vy;

        float[] force = findForce();
        float[] goal = goalForce();
        sum_fx = force[0] + goal[0];
        sum_fy = force[1] + goal[1];

        deltavx = delta_t * sum_fx;
        deltavy = delta_t * sum_fy;

        vx = distance + deltavx;
        vy = deltavy;

        deltax = vx * delta_t;
        deltay = vy * delta_t;

        distance = (float) Math.sqrt(deltax*deltax + deltay*deltay);
        if (distance > VMAX) {
            distance = VMAX;
        }

        turn = (float) Math.toDegrees(Math.atan2(deltay, deltax));
    }

    private float[] findForce() {
        float[] sum_f = new float[2];

        SonarSensor ss = new SonarSensor(id, 24);
        ss.findSensorReadings();
        float[] distances = ss.getDistances();
        float[] thetas = ss.getBearings();

        if (distances == null) {
            sum_f[0] = 0;
            sum_f[1] = 0;
            return sum_f;
        }

        for (int index = 0; index < distances.length; ++index) {  // For all the neighboring robots do:
            float theta = thetas[index];                          // get the bearing
            float r = distances[index];                           // and the distance

            float F = 0.0f;
            if (r <= R) {
                F = G / (r * r);           // Force law with p = 2.0
                if (F > FMAX)
                    F = FMAX;
                F = -F;                // Negates force vector
            }

            float fx = (float) (F * Math.cos(Math.toRadians(theta)));
            float fy = (float) (F * Math.sin(Math.toRadians(theta)));

            sum_f[0] += fx;
            sum_f[1] += fy;
        }

        return sum_f;
    }

    public float[] goalForce() {
        GoalSensor gs = new GoalSensor(id);

        float bearing = gs.getGoalBearing();

        float[] ret = new float[2];
        ret[0] = (float) (goalForce*Math.cos(Math.toRadians(bearing)));
        ret[1] = (float) (goalForce*Math.sin(Math.toRadians(bearing)));

        return ret;
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
