package robot;

import java.awt.Color;

import sensor.SonarSensor;
import sensor.GoalSensor;
/*
 * Robot.java
 *
 * Created on July 27, 2004, 10:18 AM
 */

/**
 *
 * @author  Wesley Kerr
 */
public abstract class Robot {

    public static float VMAX  = 6.0f;
    public static float VMAX2 = 12.0f;

    protected int timer          = 0;
    protected boolean startTimer = false;

    public int id;
    public boolean done;
    public boolean close;

    public Robot() {
        done = false;
    }

    public void setId(int id) {
        this.id = id;
    }

    public boolean isDone() {
        return done;
    }

    public boolean isCloseToGoal() {
        return close;
    }

    public Color getColor() {
        return Color.black;
    }

    public abstract void move();
    public abstract float getDistance();
    public abstract float getSpeed();
    public abstract float getTurn();

    protected boolean isCompleted() {
        GoalSensor gs = new GoalSensor(id);
        float goalBearing = gs.getGoalBearing();

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
        }
        return done;
    }


    protected float determineSafeDistance(SonarSensor ss, float turn) {
        float distance = ss.findSensorReading(turn);
        if (distance < VMAX2 && distance > VMAX) {
            //System.out.println("Trying to move " + (distance - VMAX));
            //return distance - VMAX;
            return VMAX;
        } else if (distance <= VMAX) {
            //System.out.println("We are trying to move " + (distance-3.0f));
            return Math.max(distance - 3.0f, 0.0f);
        } else {
            return VMAX;
        }
    }

}
