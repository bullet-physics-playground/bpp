/*
 * AAMAS.java
 *
 * Created on November 18, 2004, 11:19 AM
 */

package experiments;

import java.io.*;
import java.awt.image.BufferedImage;

import graphics.experiment.Viewer;

import env.Environment;
import env.Coverage;
import env.Parameters;

import robot.Robot;
import robot.KTRobot;

import util.Logger;
import util.ImageSaver;

/**
 *
 * @author  Wesley Kerr
 */
public class AvgSpeed {

    private String inputPath = ClassLoader.getSystemClassLoader().getResource("data/").getPath();
    private String outputPath = ClassLoader.getSystemClassLoader().getResource("log/").getPath();

    private float speed = 0.4f;
    private int obstaclePercentage;
    private int numCourses = 1;
    private int numRuns = 5;
    private long seed = 100;

    private StringBuffer speedOutput;

    private Parameters p;

    private Viewer v;

    /** Creates a new instance of AAMAS */
    public AvgSpeed(String controller) {
        p = new Parameters();
        p.robotType = "robot." + controller;
        p.n         = 25;
        p.sepRadius = 40;
        p.width     = 1000;
        p.height    = 5000;
        p.ncell_x   = 50;
        p.ncell_y   = 250;

        //v = new Viewer(p.width, p.height);
    }

    public void runExperiments(String controller) {
        speedOutput = new StringBuffer();

        for (int i = 0; i < 40; i+=10) {
            obstaclePercentage = i;

            for (int j = 0; j < numCourses; ++j) {
                if (i != 0) {
                    p.obstaclePath = inputPath + "course_" + i + "_" + j + ".txt";
                } else {
                    p.obstaclePath = null;
                }

                System.out.println(p.obstaclePath);
                long startTime = System.currentTimeMillis();
                for (int k = 0; k < numRuns; ++k) {
                    System.out.println("Course " + i + " Run " + j + " Seed " + seed);

                    p.seed = seed++;
                    if (controller.equals("KTRobot")) {
                        KTRobot.wall = speed;
                    }

                    String prefix = controller + " WallSpeed " + speed + " Pct " + i + " Course " + j + " Run " + k + " ";
                    runExperiment(prefix);
                }
                long endTime = System.currentTimeMillis();

                double runningTime = endTime - startTime;
                System.out.println("ExperimentTime " + (runningTime / (double) (numCourses*numRuns)));
                writeResults(controller, i);
            }
        }
    }

    private void runExperiment(String prefix) {
        Environment.inst().init(p);

        double totalAvg = 0.0;

        int t;
        for (t = 0; t < 150000; ++t) {
            Environment.inst().timeStep();
            if (!Environment.inst().continueGoing()) {
                break;
            }

            double count = 0;
            double avg   = 0;
            for (int i = 0; i < p.n; ++i) {
                Robot r = Environment.inst().getRobot(i);
                if (!r.isDone()) {
                    avg += r.getDistance();
                    count += 1;
                }
            }
            if (count > 0) {
                avg /= count;
                totalAvg += avg;
            }
        }

        totalAvg /= (double) t;
        speedOutput.append(prefix + " AvgSpeed " + totalAvg + "\n");
    }

    public void writeResults(String controller, int pct) {
        try {
            String prefix = outputPath + controller + "_" + pct;
            BufferedWriter out = new BufferedWriter(new FileWriter(prefix + ".txt"));
            out.write(speedOutput + "\n");
            out.close();
        } catch (Exception e) {
            System.out.println("ERROR - " + e.getMessage());
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {
        if (args.length != 1) {
            System.out.println("Usage AvgSpeed <controller>");
            System.exit(0);
        }

        String controller = args[0];

        AvgSpeed a = new AvgSpeed(controller);
        a.runExperiments(controller);
        //a.writeResults(controller);

    }
}
