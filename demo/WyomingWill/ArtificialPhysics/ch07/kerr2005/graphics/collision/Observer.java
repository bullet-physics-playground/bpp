/*
 * Observer.java
 *
 * Created on July 14, 2004, 3:06 PM
 */

package graphics.collision;

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
        c.globalAx = 4;
        c.globalAy = 9;
        c.globalAvx = 1;
        c.globalAvy = -3;

        c.globalBx = 7;
        c.globalBy = 6;
        c.globalBvx = -2;
        c.globalBvy = 4;

        //c.globalAx = 4;
        //c.globalAy = 4;
        //c.globalAvx = 1;
        //c.globalAvy = -1;

        //c.globalBx = 7;
        //c.globalBy = 1;
        //c.globalBvx = -1;
        //c.globalBvy = 1;
        c.calculate();
    }

    public void loadNewValues() {
        viewer.loadNewValues();
    }

    public void setValues(double ax, double ay, double avx, double avy,
                          double bx, double by, double bvx, double bvy) {
        c.globalAx = ax;
        c.globalAy = ay;
        c.globalAvx = avx;
        c.globalAvy = avy;

        c.globalBx = bx;
        c.globalBy = by;
        c.globalBvx = bvx;
        c.globalBvy = bvy;
        c.calculate();
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
