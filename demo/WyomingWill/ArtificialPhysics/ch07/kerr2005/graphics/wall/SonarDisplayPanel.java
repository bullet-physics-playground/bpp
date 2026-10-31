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
/**
 *
 * @author  Wesley Kerr
 */
public class SonarDisplayPanel extends JPanel {
    
    /** Creates a new instance of DisplayPanel */
    public SonarDisplayPanel() {
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
        
        int sonarWidth = getWidth() / 7;
        int scaleFactor = getHeight() / 60;
        
        f.setColor(Color.blue);
        int start = 45;
        SlideInfo info = Observer.inst().getCurrent();
        for (int i = 0; i < info.sensor.length; ++i, start-=15) {

            int wX = sonarWidth / 2;
            int wY = 10;
            g.drawString(start + "", wX + (i*sonarWidth), wY);
            
            int x = i*sonarWidth + 2;
            int y = getHeight() - (int) (info.sensor[i]*scaleFactor);
            int width = sonarWidth - 4;
            int height = (int) (info.sensor[i]*scaleFactor);
            f.fillRect(x, y, width, height);
        }
    }
    
}