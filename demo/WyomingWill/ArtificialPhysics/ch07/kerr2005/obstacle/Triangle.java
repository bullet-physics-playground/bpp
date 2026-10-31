/*
 * Triangle.java
 *
 * Created on August 24, 2004, 11:27 AM
 */

package obstacle;

import java.io.*;
import java.awt.*;

import math.Intersection;
import sensor.SonarSensor;
/**
 *
 * @author  wkerr
 */
public class Triangle implements Obstacle {
    
    private float x1;
    private float y1;
    
    private float x2;
    private float y2;
    
    private float x3;
    private float y3;
    
    /** Creates a new instance of Triangle */
    public Triangle(float x1, float y1, float x2, float y2, float x3, float y3) {
        this.x1 = x1;
        this.y1 = y1;
        
        this.x2 = x2;
        this.y2 = y2;
        
        this.x3 = x3;
        this.y3 = y3;
    }
    
    public void draw(Graphics2D g, Color c, double scale, boolean fill) {
        g.setColor(c);
        
        int[] xPoints = { (int) (x1*scale), (int) (x2*scale), (int) (x3*scale) };
        int[] yPoints = { (int) (y1*scale), (int) (y2*scale), (int) (y3*scale) };
        
        if (fill) {
            g.fillPolygon(xPoints, yPoints, 3);
        } else {
            g.drawPolygon(xPoints, yPoints, 3);
        }
    }
    
    public float intersect(float px1, float py1, float px2, float py2) {
        float distance = SonarSensor.max;
        float d = Intersection.lineIntersect(px1, py1, px2, py2, x1, y1, x2, y2);
        if (d < distance) {
            distance = d;
        }
        
        d = Intersection.lineIntersect(px1, py1, px2, py2, x2, y2, x3, y3);
        if (d < distance) {
            distance = d;
        }
        
        d = Intersection.lineIntersect(px1, py1, px2, py2, x3, y3, x1, y1);
        if (d < distance) {
            distance = d;
        }
        
        return distance;
    }
    
    public void write(BufferedWriter out) throws IOException {
        out.write("2 " + x1 + " " + y1 + " " + x2 + " " + y2 + " " + x3 + " " + y3 + "\n");
    }
    
    public void fillAreaHashtable(java.util.Hashtable area, double[] ratio, double[] cellDim2) {
    }
    
    public void fillBehindHashtable(java.util.Hashtable area, java.util.Hashtable behind, double[] ratio, double[] cellDim2) {
    }
    
    public boolean inside(double rx, double ry) {
        return false;
    }
    
}
