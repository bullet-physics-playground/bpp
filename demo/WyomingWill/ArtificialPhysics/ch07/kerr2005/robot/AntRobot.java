package robot;

/*
 * AntRobot.java
 *
 * Created on May 19 2005, 10:19 AM
 */

import java.util.Random;

import util.Logger;

import env.Environment;

import sensor.SonarSensor;
import sensor.GoalSensor;
import sensor.TrailSensor;

import math.Intersection;
/**
 *
 * @author  Wesley Kerr
 */
public class AntRobot extends Robot {
    
    public Random rand;
    
    public float distance;
    public float turn;
    
    public float speed;
    
    protected float divisor;
    
    protected GoalSensor  gs;
    protected SonarSensor ss;
    protected TrailSensor ts;
    
    private int stuckTimer     = 0;
    private boolean stuck      = false;
    
    protected boolean state1     = false;
    protected int     stateTimer = 0;

    /** Creates a new instance of AntRobot */
    public AntRobot() {
        super();
        
        rand = new Random(System.currentTimeMillis());
        speed = VMAX; 
        distance = speed;

        divisor = 360.0f / 24.0f;
    }
    
    public void setId(int id) {
        this.id = id;

        gs = new GoalSensor(id);
        ss = new SonarSensor(id, 24);
        ts = new TrailSensor(id);
        
        state1 = true;
    }

    public float getSpeed() {
        return speed;
    }
    
    public float getDistance() {
        return distance;
    }
    
    public float getTurn() {
        return turn;
    }

    public void move() {
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
        
        if (state1) {
            int choice = runAlgorithm(goal);
            float newAngle = goal + (90.0f * (float)choice);
            while (newAngle < 0) {
                newAngle += 360.0f;
            }
        
            turn = newAngle;
            distance = determineSafeDistance(ss, turn);
            
            state1 = false;
        } else {
            turn = 0;
            distance = determineSafeDistance(ss, turn);
            
            if (++stateTimer == 3) {
                stateTimer = 0;
                state1     = true;
            }
        }
        
        ts.updateTrailValue(0);
        if (stuck && distance < 0.0001) {
            stuckTimer++;
            if (stuckTimer >= 5) {
                turn = rand.nextFloat()*360.0f;
                stuck = false;
            }
            distance = determineSafeDistance(ss, turn);
            speed = distance;
        } else if (distance < 0.0001) {
            stuck = true;
            stuckTimer = 0;
        }
    }
    
    protected int runAlgorithm(float goal) {
        
        // u[0] is goal, u[1] is goal+90, u[2] is goal+180, u[3] is goal+270
        int[] u = ts.determineTrailValues(goal);
        
        int minIndex = 0;
        int min      = u[minIndex];
        for (int i = 0; i < u.length; ++i) {
            if (u[i] <= min) {
                minIndex = i;
                min      = u[i];
            } //else if (u[i] == min && rand.nextBoolean()) {
              //  minIndex = i;
              //  min      = u[i];
            //}
        }
        
        //System.out.print("Robot: " + id + " u " + u[0] + " " + u[1] + " " + u[2] + " " + u[3] + " ");
        //System.out.println("Choice: " + minIndex);
        return minIndex;
    }
}
