/*
 * RobotSensor.java
 *
 * Created on July 27, 2004, 1:27 PM
 */

package sensor;

import java.awt.Color;

import java.util.List;
import java.util.LinkedList;
import java.util.Iterator;

import env.Environment;

import robot.Robot;

import util.Logger;
/**
 *
 * @author  Wesley Kerr
 */
public class RodSensor {
    
    public static float max = 60.0f;
    
    private int robotId;
    private Logger log;
    
    private float[] thetas;
    private float[] distances;
    private int[]   ids;
    private Color[] colors;
    
    /** Creates a new instance of RobotSensor */
    public RodSensor(int id) {
        robotId = id;
        log = Logger.inst();
    }
    
    public void findVisibleRobots() {
        double[][] positions = Environment.inst().getPositions();
        double[] bearings = Environment.inst().getBearings();
        
        List foundList = new LinkedList();
        
        double x = positions[robotId][0];
        double y = positions[robotId][1];
        double ourBearing = bearings[robotId];
        
        for (int i = 0; i < positions.length; ++i) {
            if (i == robotId) {
                continue;
            }
            
            double deltax = positions[i][0] - x;
            double deltay = positions[i][1] - y;
            
            float distance = (float) Math.sqrt(deltax*deltax + deltay*deltay);
            float theta = (float) (Math.toDegrees(Math.atan2(deltay, deltax)) - ourBearing);
            
            if (distance < max) {
                Detail d = new Detail();
                d.distance = distance;
                d.theta = theta;
                d.id = i;
                d.color = Environment.inst().getRobot(i).getColor();
                foundList.add(d);
            }
            
        }
        
        if (foundList.size() == 0) {
            // should do something here, we don't see any robots
            distances = null;
            thetas    = null;
            ids       = null;
            colors    = null;
            return ;
        }
        
        distances = new float[foundList.size()];
        thetas    = new float[foundList.size()];
        ids       = new int[foundList.size()];
        colors    = new Color[foundList.size()];

        Iterator iter = foundList.iterator();
        for (int i = 0; iter.hasNext(); ++i) {
            Detail d     = (Detail) iter.next();
            thetas[i]    = d.theta;
            distances[i] = d.distance - (Environment.robotDiameter / 2);
            ids[i]       = d.id;
            colors[i]    = d.color;
        }
    }
    
    public float[] getDistances() {
        return distances;
    }
    
    public float[] getBearings() {
        return thetas;
    }
    
    public int[] getIds() {
        return ids;
    }
    
    public Color[] getColors() {
        return colors;
    }
}
