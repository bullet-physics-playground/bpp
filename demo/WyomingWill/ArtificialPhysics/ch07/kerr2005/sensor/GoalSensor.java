/*
 * GoalSensor.java
 *
 * Created on July 28, 2004, 1:38 PM
 */

package sensor;

import env.Environment;
/**
 *
 * @author  Wesley Kerr
 */
public class GoalSensor {
    
    private int robotId;
    
    /** Creates a new instance of GoalSensor */
    public GoalSensor(int id) {
        robotId = id;
    }
    
    public float getGoalBearing() {
        double[] bearings = Environment.inst().getBearings();
        return (float) (90.0 - bearings[robotId]);
    }
    
    public boolean atGoal() {
        double[][] positions = Environment.inst().getPositions();
        if (positions[robotId][1] >= Environment.inst().getHeight()-SonarSensor.max) {
            return true;
        }
        return false;
    }
    
    public boolean nearGoal() {
        double[][] positions = Environment.inst().getPositions();
        if (positions[robotId][1] >= Environment.inst().getHeight()-2*SonarSensor.max) {
            return true;
        }
        return false;
    }
}
