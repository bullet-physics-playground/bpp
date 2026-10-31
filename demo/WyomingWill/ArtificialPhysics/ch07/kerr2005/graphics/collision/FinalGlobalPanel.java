/*
 * DisplayPanel.java
 *
 * Created on October 28, 2003, 10:12 PM
 */

package graphics.collision;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;

import java.text.NumberFormat;

/**
 *
 * @author  Wesley Kerr
 */
public class FinalGlobalPanel extends JPanel {

    /** Creates a new instance of DisplayPanel */
    public FinalGlobalPanel() {
        super(true);
        init();
    }

    public void init() {
        setBackground(Color.white);
        setForeground(Color.white);
    }

    public void paintComponent(Graphics g) {
        super.paintComponent(g);
        Graphics2D f = (Graphics2D) g;
        f.setColor(Color.white);
        f.fillRect(0, 0, getWidth(), getHeight());

        Observer o = Observer.inst();
        int scaleX = getWidth() / o.width;
        int scaleY = getHeight() / o.height;

        int scale = Math.min(scaleX, scaleY);

        paintGrid(f, scale);
        paintRobots(f, scale, o.getCalculator());
        paintMomentum(f, o.getCalculator());
    }

    public void paintGrid(Graphics2D g, int size) {
        g.setColor(Color.black);
        for (int i = 0; i <= Observer.inst().width; ++i) {
            g.drawLine(i*size, 0, i*size, Observer.inst().height*size);
        }

        for (int i = 0; i <= Observer.inst().height; ++i) {
            g.drawLine(0, i*size, Observer.inst().width*size, i*size);
        }
    }

    public void paintRobots(Graphics2D g, int size, Calculator c) {

        if (c == null) {
            System.out.println("Calculator is null");
            return;
        }
        double Ay = Observer.inst().height - c.globalAy;
        double By = Observer.inst().height - c.globalBy;

        double Avy = -c.finalGlobalAvy;
        double Bvy = -c.finalGlobalBvy;

        g.setColor(Color.blue);
        g.fillOval((int) (size*c.globalAx)-3, (int) (size*Ay)-3, 6, 6);
        g.drawLine((int) (c.globalAx*size), (int) (Ay*size), (int) ((c.globalAx+c.finalGlobalAvx)*size), (int) ((Ay+Avy)*size));

        g.setColor(Color.red);
        g.fillOval((int) (size*c.globalBx)-3, (int) (size*By)-3, 6, 6);
        g.drawLine((int) (c.globalBx*size), (int) (By*size), (int) ((c.globalBx+c.finalGlobalBvx)*size), (int) ((By+Bvy)*size));
    }

    public void paintMomentum(Graphics2D g, Calculator c) {
        if (c == null)
            return;

        double mx = c.finalGlobalAvx + c.finalGlobalBvx;
        double my = c.finalGlobalAvy + c.finalGlobalBvy;

        NumberFormat nf = NumberFormat.getInstance();
        nf.setMaximumFractionDigits(2);
        nf.setMinimumFractionDigits(2);

        g.setColor(Color.black);
        g.drawString("Avx: " + nf.format(c.finalGlobalAvx), getWidth()-80, 10);
        g.drawString("Avy: " + nf.format(c.finalGlobalAvy), getWidth()-80, 25);
        g.drawString("Bvx: " + nf.format(c.finalGlobalBvx), getWidth()-80, 60);
        g.drawString("Bvy: " + nf.format(c.finalGlobalBvy), getWidth()-80, 75);
        g.drawString("Mx: " + nf.format(mx), getWidth()-80, 110);
        g.drawString("My: " + nf.format(my), getWidth()-80, 125);
    }
}