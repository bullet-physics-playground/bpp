/*
 * DisplayPanel.java
 *
 * Created on October 28, 2003, 10:12 PM
 */

package graphics.wall;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;
import java.text.NumberFormat;

import math.Intersection;
/**
 *
 * @author  Wesley Kerr
 */
public class RobotDisplayPanel extends JPanel {
    
    private int desired = 50;
    private int robotSize = 10;
    private int wallWidth = 10;

    /** Creates a new instance of DisplayPanel */
    public RobotDisplayPanel() {
        super(true);
        init();
    }
    
    public void init() {
        setBackground(Color.black);
        setForeground(Color.black);
    }
    
    public void paintComponent(Graphics g) {
        super.paintComponent(g);
        Graphics2D f = (Graphics2D) g;
        f.setColor(Color.white);
        f.fillRect(0, 0, getWidth(), getHeight());
        
        int scaleX = getWidth() / desired;
        int scaleY = getHeight() / desired;
        
        int scale = Math.min(scaleX, scaleY);
        
        SlideInfo current = Observer.inst().getCurrent();
        paintLowerElements(f, current);
        paintRobots(f, current, scale);
    }
    
    public void paintLowerElements(Graphics2D g, SlideInfo current) {
        g.setColor(Color.red);
        switch (current.wall) {
            case 0:
                g.fillRect(0,0, getWidth(), wallWidth);
                break;
            case 1:
                g.fillRect(0,0, wallWidth, getHeight());
                break;
            case 2:
                g.fillRect(getWidth()-wallWidth, 0, getWidth(), getHeight());
                break;
            case 3:
                g.fillRect(0, getHeight()-wallWidth, getWidth(), getHeight());
                break;
        }
        
        g.setColor(Color.black);
        NumberFormat nf = NumberFormat.getInstance();
        nf.setMaximumFractionDigits(2);
        nf.setMinimumFractionDigits(2);
        g.drawString("X " + nf.format(current.x), wallWidth+5, wallWidth+10);
        g.drawString("Y " + nf.format(current.y), wallWidth+5, wallWidth+24);
        g.drawString("Theta " + nf.format(current.bearing), wallWidth+5, wallWidth+36);
        
        double w1x =0;
        double w1y =0;
        double w2x =0;
        double w2y =0;
        
        double theta = 45.0;
        for (int i = 0; i < current.sensor.length; ++i, theta -= 15.0) {
            if (current.sensor[i] == 60.0) {
                continue;
            }
            w1x = current.sensor[i]*Math.cos(Math.toRadians(theta+current.bearing));
            w1y = current.sensor[i]*Math.sin(Math.toRadians(theta+current.bearing));
            break;
        }
        
        theta = -45.0;
        for (int i = current.sensor.length-1; i >= 0; --i, theta += 15.0) {
            if (current.sensor[i] == 60) {
                continue;
            }
            w2x = current.sensor[i]*Math.cos(Math.toRadians(theta+current.bearing));
            w2y = current.sensor[i]*Math.sin(Math.toRadians(theta+current.bearing));
            break;
        }
        
        int x = (int) getWidth() / 2;
        int y = (int) getHeight() / 2;
        int scale = getWidth() / 2 / 60;

        g.setColor(Color.black);
        g.fillOval(x+(int)(w1x*scale)-2, y+(int) (w1y*scale)-2, 4, 4);
        g.fillOval(x+(int)(w2x*scale)-2, y+(int) (w2y*scale)-2, 4, 4);
        g.drawLine(x+(int) (w1x*scale), y+(int) (w1y*scale), x+(int) (w2x*scale), y+(int) (w2y*scale));
        
        double px = 20*Math.cos(Math.toRadians(current.goalBearing+current.bearing));
        double py = 20*Math.sin(Math.toRadians(current.goalBearing+current.bearing));
        
        g.setColor(Color.blue);
        g.fillOval(x+(int)(px*scale)-2, y+(int) (py*scale)-2, 4, 4);
        double intPoint[] = Intersection.intersectionPoint(w1x, w1y, w2x, w2y, 0, 0, px, py);
        
        double a2 = w1x*w1x + w1y*w1y;
        double b2 = intPoint[0]*intPoint[0] + intPoint[1]*intPoint[1];
        double c2 = (w1x-intPoint[0])*(w1x-intPoint[0]) + (w1y-intPoint[1])*(w1y-intPoint[1]);
        
        double top = b2 + c2 - a2;
        double bottom = 2.0 * Math.sqrt(b2) * Math.sqrt(c2);
        
        double frac = top / bottom;
        double angle = Math.toDegrees(Math.acos(frac));
        g.setColor(Color.black);
        g.drawString("IntersectionAngle " + nf.format(angle), wallWidth+5, wallWidth+48);
    }
    
    public void paintRobots(Graphics2D g, SlideInfo current, int size) {
        int x = (int) getWidth() / 2;
        int y = (int) getHeight() / 2;
        
        g.drawOval(x-(robotSize/2), y-(robotSize/2), robotSize, robotSize);
        
        int length = getWidth() / 2;
        
        //int x2 = (int) (length*Math.cos(Math.toRadians(current.bearing)) + x);
        //int y2 = (int) (length*Math.sin(Math.toRadians(current.bearing)) + y);
        
        int x2;
        int y2;
        //g.drawLine(x, y, x2, y2);
        
        int scale = getWidth() / 2 / 60;
        int sonarLength = 100;
        int sonarTitleLength = 200;
        
        int start = 45;
        for (int i = 0; i < 7; ++i) {
            x2 = (int) (current.sensor[i]*scale*Math.cos(Math.toRadians(current.bearing+start)) + x);
            y2 = (int) (current.sensor[i]*scale*Math.sin(Math.toRadians(current.bearing+start)) + y);
            
            g.drawLine(x, y, x2, y2);
            
            x2 = (int) (sonarTitleLength*Math.cos(Math.toRadians(current.bearing+start)) + x);
            y2 = (int) (sonarTitleLength*Math.sin(Math.toRadians(current.bearing+start)) + y);
            
            g.drawString(start + "", x2, y2);
            start -= 15;
        }
        
        x2 = (int) (length*Math.cos(Math.toRadians(current.goalBearing+current.bearing)) + x);
        y2 = (int) (length*Math.sin(Math.toRadians(current.goalBearing+current.bearing)) + y);
        
        g.setColor(Color.blue);
        g.drawLine(x, y, x2, y2);
    }
}