/*
 * Square.java
 *
 * Created on August 24, 2004, 11:06 AM
 */

package obstacle;

import java.util.Hashtable;

import java.io.*;
import java.awt.*;
import javax.swing.*;

import math.Intersection;
import sensor.SonarSensor;
/**
 *
 * @author  wkerr
 */
public class Square implements Obstacle {
    
    private float x1;
    private float y1;
    private float x2;
    private float y2;
    
    /** Creates a new instance of Square */
    public Square(float x1, float y1, float x2, float y2) {
        if (x1 < x2) {
            this.x1 = x1;
            this.x2 = x2;
        } else {
            this.x1 = x2;
            this.x2 = x1;
        }
        
        if (y1 < y2) {
            this.y1 = y1;
            this.y2 = y2;
        } else {
            this.y1 = y2;
            this.y2 = y1;
        }
    }
    
    public void draw(Graphics2D g, Color c, double scale, boolean fill) {
        g.setColor(c);
        
        if (fill) {
            g.fillRect((int) (x1*scale), (int) (y1*scale), (int) ((x2-x1)*scale), (int) ((y2-y1)*scale));
        } else {
            g.drawRect((int) (x1*scale), (int) (y1*scale), (int) ((x2-x1)*scale), (int) ((y2-y1)*scale));
        }
    }
    
    public float intersect(float px1, float py1, float px2, float py2) {
        
        float distance = SonarSensor.max;
        float d = Intersection.lineIntersect(px1, py1, px2, py2, x1, y1, x2, y1);
        if (d < distance) {
            distance = d;
        }
        
        d = Intersection.lineIntersect(px1, py1, px2, py2, x1, y1, x1, y2);
        if (d < distance) {
            distance = d;
        }
        
        d = Intersection.lineIntersect(px1, py1, px2, py2, x2, y1, x2, y2);
        if (d < distance) {
            distance = d;
        }
        
        d = Intersection.lineIntersect(px1, py1, px2, py2, x1, y2, x2, y2);
        if (d < distance) {
            distance = d;
        }
        
        return distance;
    }
    
    public void write(BufferedWriter out) throws IOException {
        out.write("0 " + x1 + " " + y1 + " " + x2 + " " + y2 + "\n");
    }

    public void fillAreaHashtable(Hashtable area, double[] ratio, double[] cellDim2) {
        int minx = (int) ((x1+cellDim2[0])*ratio[0]);
        int maxx = (int) ((x2-cellDim2[0])*ratio[0]);

        int miny = (int) ((y1+cellDim2[1])*ratio[1]);
        int maxy = (int) ((y2-cellDim2[1])*ratio[1]);

        for (int i = minx; i <= maxx; ++i) {
            for (int j = miny; j <= maxy; ++j) {
                String location = i + "," + j;
                if (!area.containsKey(location)) {
                    area.put(location, location);
                }
            }
        }
    }
    
    public void fillBehindHashtable(Hashtable area, Hashtable behind, double[] ratio, double[] cellDim2) {
        int minx = (int) ((x1+cellDim2[0])*ratio[0]);
        int maxx = (int) ((x2-cellDim2[0])*ratio[0]);

        int maxy = (int) ((y2+cellDim2[1])*ratio[1]);

        for (int i = minx; i <= maxx; ++i) {
            String location = i + "," + maxy;
            if (!area.containsKey(location) && !behind.containsKey(location)) {
                behind.put(location, location);
            }
        }
    }
    
    public boolean inside(double rx, double ry) {
        if (rx >= x1 && rx <= x2 && ry >= y1 && ry <= y2) {
            return true;
        }
        return false;
    }
    
}
