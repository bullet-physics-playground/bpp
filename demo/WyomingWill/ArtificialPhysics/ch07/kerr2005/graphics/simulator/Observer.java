/*
 * Observer.java
 *
 * Created on July 14, 2004, 3:06 PM
 */

package graphics.simulator;

import java.io.*;

import env.Environment;
import env.Parameters;
import util.Logger;
/**
 *
 * @author  Wesley Kerr
 */
public class Observer implements Runnable {

    public boolean running = false;
    public boolean exit = false;
    public boolean reset = false;

    private Parameters p;

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
        p = new Parameters();

        p.n         = 10;
        p.sepRadius = 15;
        p.width     = 1000;
        p.height    = 5000;
        p.ncell_x   = 50;
        p.ncell_y   = 250;
        p.robotType = "robot.FSMRobot";
        p.seed      = -1;

        Environment.inst().init(p);

        Logger.inst().setDebugLevels("0");
        viewer = new Viewer(p.width, p.height);

    }

    public void loadObstacles(String path) {
        p.obstaclePath = path;
        doReset();
        update();
    }

    public void update() {
        viewer.update();
    }

    public void startVis() {
        synchronized (lock) {
            running = true;
            lock.notifyAll();
        }
    }

    public void stopVis() {
        synchronized (lock) {
            running = false;
            lock.notifyAll();
        }
    }

    public void resetVis() {
        synchronized (lock) {
            reset = true;
            lock.notifyAll();
        }
    }

    public void displayId(boolean displayId) {
        viewer.displayId(displayId);
    }

    public void run() {
        while (!exit) {
            if (reset) {
                doReset();
                reset = false;
                continue;
            }

            if (!running) {
                doWait();
                continue;
            }

            if (running) {
                doRun();
            }

            viewer.update();
        }
        dispose();
    }

    private void doReset() {
        Environment.inst().reset(p);
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

    private void doRun() {
        //try {
        //    Thread.currentThread().sleep(1000);
        //} catch (Exception e) {
        //    System.err.println("Error - " + e.getMessage());
        //    System.exit(-1);
        //}

        Environment.inst().timeStep();
        //running = false;
        //if (Environment.inst().getTime() == 1000)
        //    running = false;
    }

    public void dispose() {
        viewer.dispose();
        System.exit(0);
    }

    public static void main(String[] args) {
        Observer.inst().init();
        Observer.inst().run();
    }
}
