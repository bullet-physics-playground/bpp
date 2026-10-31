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
public class InitialLocalPanel extends JPanel {

    /** Creates a new instance of DisplayPanel */
    public InitialLocalPanel() {
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
        int centerx = Observer.inst().width / 2;
        int centery = Observer.inst().height / 2;

        double Avy = -c.localAvy;
        double Bvy = -c.localBvy;

        g.setColor(Color.black);
        g.fillOval(centerx*size-3, centery*size-3, 6, 6);

        g.setColor(Color.blue);
        g.drawLine(centerx*size, centery*size, (int) ((centerx+c.localAvx)*size), (int) ((centery+Avy)*size));

        g.setColor(Color.red);
        g.drawLine(centerx*size, centery*size, (int) ((centerx+c.localBvx)*size), (int) ((centery+Bvy)*size));
    }

    public void paintMomentum(Graphics2D g, Calculator c) {
        if (c == null)
            return;

        double mx = c.localAvx + c.localBvx;
        double my = c.localAvy + c.localBvy;

        NumberFormat nf = NumberFormat.getInstance();
        nf.setMaximumFractionDigits(2);
        nf.setMinimumFractionDigits(2);

        g.setColor(Color.black);
        g.drawString("Avx: " + nf.format(c.localAvx), getWidth()-80, 10);
        g.drawString("Avy: " + nf.format(c.localAvy), getWidth()-80, 25);
        g.drawString("Bvx: " + nf.format(c.localBvx), getWidth()-80, 60);
        g.drawString("Bvy: " + nf.format(c.localBvy), getWidth()-80, 75);
        g.drawString("Mx: " + nf.format(mx), getWidth()-80, 110);
        g.drawString("My: " + nf.format(my), getWidth()-80, 125);
    }
}