/*
 * Circle.java
 *
 * Created on August 24, 2004, 11:23 AM
 */

package obstacle;

import java.io.*;
import java.awt.*;
import javax.swing.*;

import math.Intersection;
import sensor.SonarSensor;
/**
 *
 * @author  wkerr
 */
public class Circle implements Obstacle {

    private float x;
    private float y;
    private float r;

    /** Creates a new instance of Circle */
    public Circle(float x, float y, float r) {
        this.x = x;
        this.y = y;
        this.r = r;
    }

    public void draw(Graphics2D g, Color c, double scale, boolean fill) {
        g.setColor(c);

        if (fill) {
            g.fillOval((int) (x*scale), (int) (y*scale), (int) (r*scale), (int) (r*scale));
        } else {
            g.drawOval((int) (x*scale), (int) (y*scale), (int) (r*scale), (int) (r*scale));
        }
    }

    public float intersect(float px1, float py1, float px2, float py2) {
        float distance = SonarSensor.max;
        float d = Intersection.circleIntersect(px1, py1, px2, py2, x, y, r);
        if (d < distance)
            distance = d;
        return distance;
    }

    public void write(BufferedWriter out) throws IOException {
        out.write("1 " + x + " " + y + " " + r + "\n");
    }

    public void fillAreaHashtable(java.util.Hashtable area, double[] ratio, double[] cellDim2) {
    }

    public void fillBehindHashtable(java.util.Hashtable area, java.util.Hashtable behind, double[] ratio, double[] cellDim2) {
    }

    public boolean inside(double rx, double ry) {
        float distance = (float) Math.sqrt((rx-x)*(rx-x) + (ry-y)*(ry-y));
        if (distance < r) {
            return true;
        }
        return false;
    }

}
