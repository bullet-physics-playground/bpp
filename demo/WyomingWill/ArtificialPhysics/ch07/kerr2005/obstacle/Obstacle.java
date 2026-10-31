/*
 * Obstacle.java
 *
 * Created on August 24, 2004, 11:00 AM
 */

package obstacle;

import java.io.*;
import java.util.Hashtable;

import java.awt.Graphics2D;
import java.awt.Color;
/**
 *
 * @author  wkerr
 */
public interface Obstacle {
    public float intersect(float px1, float py1, float px2, float py2);
    public void draw(Graphics2D g, Color c, double scale, boolean fill);
    public void write(BufferedWriter out) throws IOException;
    public void fillAreaHashtable(Hashtable area, double[] ratio, double[] cellDim2);
    public void fillBehindHashtable(Hashtable area, Hashtable behind, double[] ratio, double[] cellDim2);
    public boolean inside(double rx, double ry);
}
