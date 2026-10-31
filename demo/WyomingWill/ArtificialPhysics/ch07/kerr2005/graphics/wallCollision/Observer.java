/*
 * Observer.java
 *
 * Created on July 14, 2004, 3:06 PM
 */

package graphics.wallCollision;

import java.io.*;

/**
 *
 * @author  Wesley Kerr
 */
public class Observer implements Runnable {
    
    public int width = 15;
    public int height = 15;
    
    public boolean exit = false;
    public boolean reset = false;
    
    private Calculator c;
    private Viewer viewer;

    private static Observer observer = null;
    
    public Object lock = new Object();
    
    /** Creates a new instance of Observer */
    private Observer() {
    }
    
    public static Observer inst() {
        if (observer == null) {
            observer = new Observer();
        }
        
        return observer;
    }
    
    public void init() {
        c = new Calculator();
        c.globalInitialBearing = 105;
        c.calculate();
    }
    
    public void loadNewValues() {
        viewer.loadNewValues();
    }
    
    public void setValues(double ax, double ay, double avx, double avy,
                          double bx, double by, double bvx, double bvy) {
        viewer.update();
    }
    
    public void createDisplay() {
        viewer = new Viewer();
    }

    public Calculator getCalculator() {
        return c;
    }
    
    public void update() {
        viewer.update();
    }

    public void run() {
        while (!exit) {
            viewer.update();
            doWait();
            continue;
        }
        dispose();
    }
    
    private void doWait() {
        synchronized (lock) {
            try {
                lock.wait();
            } catch (Exception e) {
                System.err.println("Error - " + e.getMessage());
                System.exit(-1);
            }
        }
    }
    
    public void dispose() {
        viewer.dispose();
        System.exit(0);
    }
    
    public static void main(String[] args) {
        Observer.inst().init();
        Observer.inst().createDisplay();
        Observer.inst().run();
    }
}
