/*
 * Logger.java
 *
 * Created on July 12, 2004, 2:10 PM
 */

package util;

import java.util.StringTokenizer;
import java.io.*;
/**
 * Level 0 - Basic logging information (typically turned off)
 * Level 1 - Position and Bearing format
 *              TimeStep <> Robot <> x <> y <> bearing <>
 * Level 2 - Sensor information for specific robot
 * Level 3 - Robot information per move (turn and distance) format
 *              TimeStep <> Robot <> Turn <> Move <> deltavx <> deltavy <> deltax <> deltay <>
 * Level 4 - Obstacle Force
 *              TimeStep <> Robot <> ForceTheta <> ForceR <> F <> fx <> fy <>
 * Level 5 -
 * Level 6 - Robot positions format
 *              TimeStep <> Robot <> x <> y <> vx <> vy <>
 * Level 7 - Sensed Robots format
                TimeStep <> Robot <> Sensed <> Distance <> Theta <>
 * Level 8 - Sum of Forces format
                TimeStep <> Robot <> Fx <> Fy <>
 * Level 9 - Collision with wall information.
 *              Robot <> x <> y <> sensor45 <>
                Robot <> x <> y <> sensor30 <>
                Robot <> x <> y <> sensor15 <>
                Robot <> x <> y <> sensor0 <>
                Robot <> x <> y <> sensor345 <>
                Robot <> x <> y <> senor330 <>
                Robot <> x <> y <> sensor315 <>
 * Level 10 - Total Energy of the Simulation
 *              TimeStep <> Energy <>
 * Level 11 - Collision with Robot information.
 * Level 12 - Sonar information
 * @author  Wesley Kerr
 */
public class Logger {
    private boolean[] debugLevels;
    private FileWriter out;

    private static Logger l = null;

    /** Creates a new instance of Logger */
    private Logger() {
        debugLevels = new boolean[50];
        try {
            String fileName = ClassLoader.getSystemClassLoader().getResource("log/").getPath();
            out = new FileWriter(fileName + "debug.txt");
        }
        catch (IOException e) {
            System.out.println("Error opening debug file - " + e.getMessage());
            e.printStackTrace();
            System.exit(-1);
        }
    }

    public static Logger inst() {
        if (l == null) {
            l = new Logger();
        }

        return l;
    }

    public boolean isDebugLevelOn(int level) {
        return debugLevels[level];
    }

    public void setDebugLevels(String debug) {
        StringTokenizer str = new StringTokenizer(debug, ",");
        while (str.hasMoreTokens()) {
            int level = Integer.parseInt(str.nextToken());
            System.out.println("Level " + level);
            debugLevels[level] = true;
        }
    }

    public void close() {
        try {
            out.close();
        }
        catch (IOException e) {
            System.out.println("Error closing debug file - " + e.getMessage());
            e.printStackTrace();
            System.exit(-1);
        }
    }

    public void log(int level, String message) {
        if (!debugLevels[level]) {
            return;
        }

        try {
            out.write("[Level " + level + "] ");
            out.write(message + "\n");
            out.flush();
        }
        catch (IOException e) {
            System.err.println("Error debugFile - " + e.getMessage());
            e.printStackTrace();
            System.exit(-1);
        }
    }
}
