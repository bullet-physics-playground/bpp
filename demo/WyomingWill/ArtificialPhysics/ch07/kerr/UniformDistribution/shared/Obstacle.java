/*
 * Obstacle.java
 *
 * Created on November 12, 2003, 4:12 PM
 */

package shared;

import java.awt.Graphics;
import java.util.*;
/**
 *
 * @author  Wesley Kerr
 */
public interface Obstacle
{
   public void draw(Graphics g, int panelWidth, int panelHeight);
   public Point force(double x, double y, int dir);
   public void collision(double[] x, double[] x_old, double[] v, double mpv, 
                         double tau, MyLong seed);   
   public void checkCollision(double[] x, double[] x_old);
   public boolean past(double y);
   public Vector cells();
}
