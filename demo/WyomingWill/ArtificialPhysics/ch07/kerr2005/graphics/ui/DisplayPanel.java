/*
 * DisplayPanel.java
 *
 * Created on October 28, 2003, 10:12 PM
 */

package graphics.ui;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;

import env.Environment;
import env.Coverage;
import obstacle.ObstacleContainer;

import sensor.RodSensor;
/**
 *
 * @author  Wesley Kerr
 */
public class DisplayPanel extends JPanel {

    private boolean displayId = false;

    /** Creates a new instance of DisplayPanel */
    public DisplayPanel() {
        super(true);
        init();
    }

    public void displayId(boolean displayId) {
        this.displayId = displayId;
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

        Font f1 = f.getFont();
        Font f2 = f1.deriveFont(9.0f);
        f.setFont(f2);

        Environment e = Environment.inst();

        double scaleX = (double) getWidth() / (double) e.getWidth();
        double scaleY = (double) getHeight() / (double) e.getHeight();

        double scale = Math.min(scaleX, scaleY);

        paintLowerElements(f, scale);
        paintRobots(f, scale);
        paintInformation(f);
    }

    public void paintLowerElements(Graphics2D g, double size) {
        Environment e = Environment.inst();

        g.setColor(Color.black);
        g.drawLine(0, 0, (int) (size*e.getWidth()), 0);
        g.drawLine((int) (size*e.getWidth()), 0, (int) (size*e.getWidth()), (int) (size*e.getHeight()));
        g.drawLine((int) (size*e.getWidth()), (int) (size*e.getHeight()), 0, (int) (size*e.getHeight()));
        g.drawLine(0, 0, 0, (int) (size*e.getHeight()));
        ObstacleContainer.inst().draw(g, Color.BLACK, size, false);
    }

    public void paintRobots(Graphics2D g, double size) {

        Environment e = Environment.inst();

        double[][] positions = e.getPositions();
        double[] bearings = e.getBearings();

        if (positions == null || bearings == null)
            return;

        for (int i = 0; i < positions.length; ++i) {

            int x = (int) positions[i][0];
            int y = (int) positions[i][1];

            g.setColor(Environment.inst().getRobot(i).getColor());
            g.drawOval((int) (size*(x - 3)), (int) (size*(y - 3)), (int) (6*size), (int) (6*size));

            //drawRobotConnections(g, size, i);
            //g.drawOval((int) (size*(x-20)), (int) (size*(y-20)), (int) (40*size), (int) (40*size));
            //g.drawOval(size*(x - 27), size*(y - 27), 27*2*size, 27*2*size);

            g.setColor(Color.red);
            int x2 = (int) (positions[i][0] + 10*Math.cos(bearings[i]*Math.PI/180.0));
            int y2 = (int) (positions[i][1] + 10*Math.sin(bearings[i]*Math.PI/180.0));
            g.drawLine((int)(x*size), (int)(y*size), (int) (x2*size), (int) (y2*size));

            if (displayId) {
                g.setColor(Color.black);
                g.drawString(i + "", (int) (x*size - 2), (int) (y*size - 4));
            }
        }
    }

    private void paintInformation(Graphics2D g) {
        Environment e = Environment.inst();
        g.setColor(Color.blue);
        int halfWidth = getWidth() / 2;
        g.drawString("Time: " + e.getTime(), halfWidth, 20);

        Coverage c = e.getCoverage();
        if (c == null) {
            return;
        }
        g.drawString("Coverage: " + c.getCoveredPct(), halfWidth, 30);
        g.drawString("Behind: " + c.getBehindPct(), halfWidth, 40);
    }

    private void drawRobotConnections(Graphics2D g, double size, int robotId) {
        g.setColor(Color.darkGray);
        RodSensor rs = new RodSensor(robotId);
        rs.findVisibleRobots();
        int[] ids = rs.getIds();

        if (ids == null)
            return;

        double[][] positions = Environment.inst().getPositions();
        for (int i = 0; i < ids.length; ++i) {
            double x = positions[robotId][0];
            double y = positions[robotId][1];

            double x2 = positions[ids[i]][0];
            double y2 = positions[ids[i]][1];

            g.drawLine((int) (x*size), (int) (y*size), (int) (x2*size), (int) (y2*size));
        }
    }
}