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
public class Liquid extends Robot {
    
    public static final float E = 1.0f;
    
    public static final float R = 20;
    public static final float upup = R;
    public static final float updown = (float) (R / (2*Math.cos(Math.toRadians(54))));
    public static final float downdown = (float) (R*Math.tan(Math.toRadians(54)));
    public float delta_t = 1.0f;
    public float FMAX = 1.5f;
    
    private float goalForce = 0.1f;
    
    private float FR = 0.0f;
    
    public float distance;
    public float turn;
    
    public Color color;
    
    /** Creates a new instance of APRobot */
    public Liquid() {
        super();
        distance = 0;
        turn = 0;
        
        if (Math.random() < 0.4) {
            color = Color.blue;
        } else {
            color = Color.black;
        }
        
    }
    
    public void setColor(Color color) {
        this.color = color;
    }
    
    public Color getColor() {
        return color;
    }
    
    public void move() {

        turn = 0;
        
        float vx = distance*FR;
        float vy = 0;
        
        float[] robotF = findRobotForce();
        
        float deltavx = delta_t * robotF[0];
        float deltavy = delta_t * robotF[1];
        
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
        Color[] colors    = rs.getColors();
        
        if (distances == null) {
            sum_f[0] = 0;
            sum_f[1] = 0;
            return sum_f;
        }

        for (int index = 0; index < distances.length; ++index) {  // For all the neighboring robots do:
            float theta = thetas[index];                          // get the bearing
            float r = distances[index];                           // and the distance
            Color c = colors[index];                              // and the color
            
            if (r > 1.5*R)
                continue; 
            
            float sigma = upup;
            if (c == color && color == Color.black) {
                sigma = upup;
            } else if (c == color && color == Color.blue) {
                sigma = downdown;
            } else {
                sigma = updown;
            }
            
            float lhs = (float) (Math.pow(sigma, 6.0) / Math.pow(r, 7.0));
            float rhs = (float) (2*(Math.pow(sigma, 12.0) / Math.pow(r, 13.0)));

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
