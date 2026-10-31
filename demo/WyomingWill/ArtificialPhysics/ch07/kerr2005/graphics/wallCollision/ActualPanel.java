/*
 * DisplayPanel.java
 *
 * Created on October 28, 2003, 10:12 PM
 */

package graphics.wallCollision;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;

import java.text.NumberFormat;
/**
 *
 * @author  Wesley Kerr
 */
public class ActualPanel extends JPanel {
    
    /** Creates a new instance of DisplayPanel */
    public ActualPanel() {
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
        
        //paintGrid(f, scale);
        paintRobots(f, scale, o.getCalculator());
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
        
        g.setColor(Color.blue);
        g.drawLine(centerx*size, centery*size, (int) ((centerx+c.globalVx)*size), centery*size);
        g.drawLine(centerx*size, centery*size, centerx*size, (int) ((centery+c.globalVy)*size));
        
        g.setColor(Color.red);
        g.drawLine(centerx*size, centery*size, (int) ((centerx+c.globalVx)*size), (int) ((centery+c.globalVy)*size));
    }
}