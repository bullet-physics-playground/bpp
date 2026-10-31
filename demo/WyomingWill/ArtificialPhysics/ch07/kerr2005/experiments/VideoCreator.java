/*
 * VideoCreator.java
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

import robot.KTRobot;

import util.Logger;
import util.ImageSaver;

/**
 *
 * @author  Wesley Kerr
 */
public class VideoCreator {

    private String inputPath = ClassLoader.getSystemClassLoader().getResource("data/").getPath();
    private String outputPath = ClassLoader.getSystemClassLoader().getResource("movie/").getPath();

    private float[] speeds = { 2.0f, 4.0f, 6.0f, 8.0f, 10.0f };
    private long seed = 100;

    private Parameters p;

    private Viewer v;

    /** Creates a new instance of AAMAS */
    public VideoCreator() {
        p = new Parameters();
        p.robotType = "robot.KTRobot";
        p.n         = 30;
        p.sepRadius = 30;
        p.width     = 400;
        p.height    = 1200;
        p.ncell_x   = 40;
        p.ncell_y   = 120;

        v = new Viewer(p.width, p.height);
    }

    public void runExperiments() {
        p.obstaclePath = inputPath + "video_20_0.txt";

        KTRobot.wall = speeds[0];
        runExperiment("KTRobot");

        p.robotType = "robot.APRobot";
        runExperiment("APRobot");

        p.robotType = "robot.APGasRobot";
        runExperiment("APGasRobot");
    }

    private void runExperiment(String robot) {
        Environment.inst().init(p);

        int t;
        boolean running = true;
        for (t = 0; t < 3001 && running; ++t) {
            Environment.inst().timeStep();
            if (!Environment.inst().continueGoing()) {
                running = false;
            }

            if (t % 5 == 0) {
                BufferedImage bi = ImageSaver.inst().getPlainImage(400, 1200);
                ImageSaver.inst().saveImage(bi, outputPath + robot + "_" + t + ".jpeg");
            }
            v.update();
        }

    }

    public static void main(String[] args) {
        VideoCreator a = new VideoCreator();
        a.runExperiments();

    }
}
