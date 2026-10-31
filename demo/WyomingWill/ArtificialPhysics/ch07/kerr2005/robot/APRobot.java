package robot;

/*
 * APRobot.java
 *
 * Created on July 27, 2004, 10:19 AM
 */

import env.Environment;

import sensor.GoalSensor;
import sensor.RodSensor;
import sensor.SonarSensor;

import util.Logger;
/**
 *
 * @author  Wesley Kerr
 */
public class APRobot extends Robot {
    
    public float delta_t = 1.0f;
    public float FMAX = 1.5f;
    public float G = 240.0f;
    public float R = 24.0f;
    
    private float goalForce = 1.f;
    
    public float distance;
    public float turn;
    
    /** Creates a new instance of APRobot */
    public APRobot() {
        super();
        distance = 0;
        turn = 0;
    }
    
    public void move() {
        
        if (isCompleted()) {
            turn = 0;
            distance = 0;
            return;
        }
        
        float theta;
        float r, F, fx, fy, sum_fx = 0, sum_fy = 0;
        float vx, vy, deltavx, deltavy, deltax, deltay;
        vx = vy = 0;

        float[] robotF = findRobotForce();
        float[] obstacleF = findObstacleForce();
        float[] goalF = goalForce();
        sum_fx = robotF[0] + obstacleF[0] + goalF[0];
        sum_fy = robotF[1] + obstacleF[1] + goalF[1];
        
        deltavx = delta_t * sum_fx;
        deltavy = delta_t * sum_fy;
        
        vx = vx + deltavx;
        vy = vy + deltavy;
        
        deltax = vx * delta_t;
        deltay = vy * delta_t;
        
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
        int[]   ids       = rs.getIds();
        
        if (distances == null) {
            sum_f[0] = 0;
            sum_f[1] = 0;
            return sum_f;
        }

        for (int index = 0; index < distances.length; ++index) {  // For all the neighboring robots do:
            float theta = thetas[index];                          // get the bearing
            float r = distances[index];                           // and the distance
            
            float F = 0.0f;
            if (r <= 1.5 * R) {
                F = G / (r * r);           // Force law with p = 2.0
                if (F > FMAX) 
                    F = FMAX;
                if (r < R)
                    F = -F;                // Negates force vector
            }
            
            float fx = (float) (F * Math.cos(Math.toRadians(theta)));
            float fy = (float) (F * Math.sin(Math.toRadians(theta)));
            
            sum_f[0] += fx;
            sum_f[1] += fy;
        }
        
        return sum_f;
    }
    
    private float[] findObstacleForce() {
        float[] sum_f = new float[2];

        SonarSensor ss = new SonarSensor(id, 24);
        ss.findSensorReadings();
        float[] distances = ss.getDistances();
        float[] bearings = ss.getBearings();
        
        if (distances == null) {
            sum_f[0] = 0.0f;
            sum_f[1] = 0.0f;
            return sum_f;
        }
        
        for (int i = 0; i < distances.length; ++i) {
            float theta = bearings[i];                        // get the bearing
            float r = distances[i];                           // and the distance
            
            float F = 0.0f;
            if (r <= 1.5 * R) {
                F = G / (r * r);           // Force law with p = 2.0
                if (F > FMAX) 
                    F = FMAX;
                F = -F;                    // Negates force vector
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
