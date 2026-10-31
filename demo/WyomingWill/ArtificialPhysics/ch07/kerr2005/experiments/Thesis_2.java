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

import robot.KTRobot;

import util.Logger;
import util.ImageSaver;

/**
 *
 * @author  Wesley Kerr
 */
public class Thesis_2 {
    
    private String inputPath = ClassLoader.getSystemClassLoader().getResource("data/").getPath();
    private String outputPath = ClassLoader.getSystemClassLoader().getResource("log/").getPath();
    
    private float speed = 0.4f;
    private int obstaclePercentage = 20;
    //private int numCourses = 5;
    private int startCourse = 0;
    private int endCourse = 10;
    private int numRuns = 10;
    private long seed = 100;
    
    private StringBuffer pctObstacle;
    private StringBuffer pctTotal;
    private StringBuffer time;
    private StringBuffer map;
    private StringBuffer output;
    private StringBuffer pctOutput;

    private Parameters p;
    
    private Viewer v;
    
    /** Creates a new instance of AAMAS */
    public Thesis_2(String controller, int n, int start, int end) {
        startCourse = start;
        endCourse   = end;
        
        p = new Parameters();
        p.robotType = "robot." + controller;
        p.n         = n;
        p.sepRadius = 40;
        p.width     = 1000;
        p.height    = 5000;
        p.ncell_x   = 50;
        p.ncell_y   = 250;
  
        //v = new Viewer(p.width, p.height);
    }
    
    public void runExperiments(String controller, int n) {
        
        String initial = controller + "_" + n + "_";
        pctObstacle   = new StringBuffer(initial + "ob = [ ");
        pctTotal      = new StringBuffer(initial + "total = [ ");
        time          = new StringBuffer(initial + "time = [ ");
        
        output    = new StringBuffer();
        pctOutput = new StringBuffer();
        
        for (int i = startCourse; i < endCourse; ++i) {
            p.obstaclePath = inputPath + "course_" + obstaclePercentage + "_" + i + ".txt";
            long startTime = System.currentTimeMillis();
            for (int j = 0; j < numRuns; ++j) {
                System.out.println("Course " + i + " Run " + j + " Seed " + seed);
                
                p.seed = seed++;
                if (controller.equals("KTRobot")) {
                    KTRobot.wall = speed;
                }
                
                String prefix = controller + " Speed " + speed + " N " + n + " Course " + i + " Run " + j + " ";
                runExperiment(prefix);
            }
            long endTime = System.currentTimeMillis();
        
            double runningTime = endTime - startTime;
            System.out.println("ExperimentTime " + (runningTime / (double) ((endCourse-startCourse)*numRuns)));
            writeResults(controller, n);       
        }
        pctObstacle.append("];");
        pctTotal.append("];");
        time.append("];");
        
    }
    
    private void runExperiment(String prefix) {
        Environment.inst().init(p);
        
        int t;
        boolean running = true;
        for (t = 0; t < 150000 && running; ++t) {
            Environment.inst().timeStep();
            if (!Environment.inst().continueGoing()) {
                running = false;
            }
            
            //v.update();
            //if (t%1000 == 0) {
            //    pctOutput.append(prefix + " Time " + t + " PctFinished " + Environment.inst().pctRobotsDone() + "\n");
            //}
        }
        //pctOutput.append(prefix + " Time " + t + " PctFinished " + 1.0);
        if (t == 150000) {
            BufferedImage bi = ImageSaver.inst().getPlainImage(1000, 5000);
            ImageSaver.inst().saveImage(bi, outputPath + p.robotType + "_" + seed + "_" + p.n + ".jpeg");
        }
        
        Coverage c = Environment.inst().getCoverage();

        output.append(prefix);

        if (c.getBehindCount() == 0) {
            pctObstacle.append("0");
            output.append("Behind 0 ");
        } else {
            pctObstacle.append(c.getBehindPct()*100.0 + " ");
            output.append("Behind " + c.getBehindPct()*100.0 + " ");
        }
        

        pctTotal.append(c.getCoveredPct()*100 + " ");
        output.append("Total " + c.getCoveredPct()*100 + " ");
        
        time.append(t + " ");
        output.append("Time " + t + "\n");
    }
    
    public void writeResults(String controller, int n) {
        try {
            String prefix = outputPath + controller + "_N" + n;
            BufferedWriter out = new BufferedWriter(new FileWriter(prefix + ".m"));
            out.write(pctObstacle + "\n");
            out.write(pctTotal + "\n");
            out.write(time + "\n");
            out.close();
            
            out = new BufferedWriter(new FileWriter(prefix + ".txt"));
            out.write(output + "\n");
            out.write(pctOutput + "\n");
            out.close();
        } catch (Exception e) {
            System.out.println("ERROR - " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    public static void main(String[] args) {
        if (args.length != 4) {
            System.out.println("Usage Thesis_2 <controller> <n> <start> <end>");
            System.exit(0);
        }
        
        String controller = args[0];
        int n             = Integer.parseInt(args[1]);
        int startCourse   = Integer.parseInt(args[2]);
        int endCourse     = Integer.parseInt(args[3]);
        
        Thesis_2 a = new Thesis_2(controller, n, startCourse, endCourse);
        a.runExperiments(controller, n);
        a.writeResults(controller, n);
        
    }
}
