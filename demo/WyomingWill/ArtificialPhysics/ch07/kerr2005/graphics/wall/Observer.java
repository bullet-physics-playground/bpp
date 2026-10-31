/*
 * Observer.java
 *
 * Created on July 14, 2004, 3:06 PM
 */

package graphics.wall;

import java.io.*;
import java.util.StringTokenizer;
import java.util.Vector;

/**
 *
 * @author  Wesley Kerr
 */
public class Observer implements Runnable {
    
    public boolean exit = false;
    
    private Viewer viewer;

    private Vector info;
    private int curr;
    
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
        info = new Vector();
        try {
            String fileName = ClassLoader.getSystemClassLoader().getResource("log/").getPath();
            fileName += "sonar2.txt";
            BufferedReader in = new BufferedReader(new FileReader(fileName));
            while (in.ready()) {
                SlideInfo si = new SlideInfo();
                for (int i = 0; i < 7; ++i) {
                    String line = in.readLine();
                    StringTokenizer str = new StringTokenizer(line, " ");
                    if (str.countTokens() != 6) {
                        throw new Exception("File Read errors: Not enough tokens " + line);
                    }
                    
                    double x = Double.parseDouble(str.nextToken());
                    double y = Double.parseDouble(str.nextToken());
                    double bearing = Double.parseDouble(str.nextToken());
                    double goalBearing = Double.parseDouble(str.nextToken());
                    int wall = Integer.parseInt(str.nextToken());
                    double distance = Double.parseDouble(str.nextToken());
                    if (i == 0) {
                        si.x = x;
                        si.y = y;
                        si.wall = wall;
                        si.bearing = bearing;
                        si.goalBearing = goalBearing;
                    }
                    si.sensor[i] = distance;
                }
                info.addElement(si);
            }
        } catch (Exception e) {
            System.out.println("Error " + e.getMessage());
            System.exit(0);
        }
        viewer = new Viewer();
    }
    
    public void inc() {
        synchronized (lock) {
            curr++;
            curr = curr % info.size();
            lock.notifyAll();
        }
    }
    
    public void dec() {
        synchronized (lock) {
            curr--;
            if (curr < 0) 
                curr = info.size() - 1;
            lock.notifyAll();
        }
    }
    
    public void first() {
        synchronized (lock) {
            curr = 0;
            lock.notifyAll();
        }
    }
    
    public void last() {
        synchronized (lock) {
            curr = info.size() - 1;
            lock.notifyAll();
        }
    }
    
    public SlideInfo getCurrent() {
        return (SlideInfo) info.elementAt(curr);
    }
    
    public void run() {
        while (!exit) {
            doWait();
            update();
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
    
    public void update() {
        viewer.update();
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
