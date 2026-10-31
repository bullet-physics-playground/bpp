/*
 * TrailSensor.java
 *
 * Created on May 16, 2005, 11:59 AM
 */

package sensor;

import env.Environment;
import env.Trails;

import robot.Robot;
/**
 *
 * @author  Wesley Kerr
 */
public class TrailSensor {
    
    protected int robotId;
    
    /** Creates a new instance of TrailSensor */
    public TrailSensor(int id) {
        robotId = id;
    }
    
    public int[] determineTrailValues(float angle) {
        double[][] pos = Environment.inst().getPositions();
        double[]   bea = Environment.inst().getBearings();
        Trails t       = Environment.inst().getTrails();
        
        //double realAngle = bea[robotId] + angle; 
        //double xPos = pos[robotId][0] + Robot.VMAX*Math.cos(Math.toRadians(realAngle));
        //double yPos = pos[robotId][1] + Robot.VMAX*Math.sin(Math.toRadians(realAngle));
        
        //System.out.println("Robot: " + robotId + " Pos <" + pos[robotId][0] + "," + pos[robotId][1] + ">");
        //System.out.println("\tPos <" + xPos + "," + yPos + ">");
        return t.getUValues(pos[robotId][0], pos[robotId][1]);
    }
    
    public void updateTrailValue(int choice) {
        double[][] pos = Environment.inst().getPositions();
        Trails t       = Environment.inst().getTrails();
        
        int uOld = t.getUValue(pos[robotId][0], pos[robotId][1]);
        //int uNew = t.getUValue(pos[robotId][0], pos[robotId][1], choice);
        
        // Node Counting
        t.setUValue(pos[robotId][0], pos[robotId][1], uOld+1);
        // LRTA*
        //t.setUValue((float)pos[robotId][0], (float)pos[robotId][1], uNew+1);
        // Thrun's Value Update
        //t.setUValue((float)pos[robotId][0], (float)pos[robotId][1],
        //            Math.max(uOld+1, uNew+1));
    }
    
}
