/*
 * GA.java
 *
 * Created on October 24, 2004, 9:50 PM
 */

package ga;

import java.io.*;
import java.util.*;

import robot.FSMRobot;

import util.FSM;
import util.Rand;
import util.Logger;

import env.Parameters;
import env.Environment;
import env.Coverage;
/**
 *
 * @author  Wesley Kerr
 */
public class GA {

    public BufferedWriter popLog;
    public BufferedWriter bestLog;

    public static int popSize = 50;
    public static final double M = 1.0 / ((double) FSM.numStates*FSM.numInputs);
    public static final double R = 0.6;
    public static final double UP = 0.5;

    private FSM     best;
    private double  bestFitness = -1;
    private boolean newBest     = false;

    private FSM[] pop;
    private int[] sh;
    private double avg;

    protected Parameters p;

    /** Creates a new instance of GA */
    public GA() {

        p = new Parameters();
        p.robotType = "robot.FSMRobot";
        p.n         = 20;
        p.sepRadius = 40;
        p.width     = 1000;
        p.height    = 5000;
        p.ncell_x   = 50;
        p.ncell_y   = 250;

        FSM.loadPrefs();
        String file = ClassLoader.getSystemClassLoader().getResource("log/").getPath();
        try {
            popLog = new BufferedWriter(new FileWriter(file + "GAPop.txt"));
            bestLog = new BufferedWriter(new FileWriter(file + "GABest.txt"));
        } catch (Exception e) {
            System.err.println("Error loading logs " + e.getMessage());
            System.exit(0);
        }
    }

    public void initializePopulation() {
        pop = new FSM[popSize];
        for (int i = 0; i < popSize; ++i) {
            pop[i] = new FSM();
            pop[i].generateRandom();
        }
    }

    private void runExperiment(double[] pcts, int i) {
        Environment.inst().init(p);
        for (int j = 0; j < p.n; ++j) {
            FSMRobot r = (FSMRobot) Environment.inst().getRobot(j);
            r.setFSM(pop[i]);
        }
        int t;
        boolean running = true;
        for (t = 0; t < 5000 && running; ++t) {
            Environment.inst().timeStep();
            if (!Environment.inst().continueGoing()) {
                running = false;
            }
        }
        Coverage c = Environment.inst().getCoverage();

        pcts[0] += c.getBehindPct();
        pcts[1] += c.getCoveredPct();
        pcts[2] += (double)Environment.inst().countRobotsDone() / (double)p.n;
        pcts[3] += 1.0;
    }

    public void evaluate() {
        avg = 0;

        String path = ClassLoader.getSystemClassLoader().getResource("data/").getPath();
        for (int i = 0; i < pop.length; ++i) {
            if (pop[i].getFitness() > 0) {
                avg += pop[i].getFitness();
                continue;
            }

            double[] pcts = new double[4];
            p.obstaclePath = path + "CB.txt";
            runExperiment(pcts, i);

            p.obstaclePath = path + "L.txt";
            runExperiment(pcts, i);

            for (int pct = 30; pct < 40; pct += 10) {
                for (int tests = 0; tests < 1; ++tests) {
                    p.obstaclePath = path + "course_"+pct+"_"+tests+".txt";
                    runExperiment(pcts, i);
                }
            }

            pcts[0] /= pcts[3];
            pcts[1] /= pcts[3];
            pcts[2] /= pcts[3];

            double fitness = 0.45*pcts[0] + 0.45*pcts[1] + 0.1*pcts[2];

            if (fitness < 1e-9) {
                fitness = 1e-9;
            }
            pop[i].setFitness(fitness);
            avg += fitness;
            if (fitness > bestFitness) {
                bestFitness = fitness;
                best = new FSM();
                best.copy(pop[i]);
                newBest = true;
            }
        }
        avg /= (double) pop.length;
    }

    public void selection() {
        int[] children = new int[pop.length];
        sh             = new int[pop.length];
        double[] f     = new double[pop.length];

        double prior = (double) pop[0].getFitness() / avg;
        f[0] = prior;

        System.out.println("Average Fitness " + avg);
        //System.out.println("F[0] " + f[0]);
        for (int i = 1; i < f.length; ++i) {
            f[i] = ((double) pop[i].getFitness() / avg) + prior;
            prior = f[i];
            //System.out.println("F[" + i + "] " + f[i]);
        }

        double r = Rand.ssrand();
        int index = 0;
        int count = 0;
        while (count < f.length) {
            if (r < f[index]) {
                children[index]++;
                count++;
                r += 1.0;
            }
            else {
                index++;
            }
        }

        FSM[] off = new FSM[pop.length];
        count = 0;
        for (int i = 0; i < children.length; ++i) {
            if (children[i] == 0)
                continue;

            for (int j = 0; j < children[i]; ++j) {
                FSM d = new FSM();
                d.copy(pop[i]);
                off[count] = d;
                sh[count] = i;
                ++count;
            }
        }
        pop = off;

        placeBestAtWorst();
    }

    private void placeBestAtWorst() {
        double worst = pop[0].getFitness();
        int index = 0;
        for (int i = 1; i < popSize; ++i) {
            if (pop[i].getFitness() < worst) {
                index = i;
                worst = pop[i].getFitness();
            }
        }
        pop[index] = new FSM();
        pop[index].copy(best);
    }

    private void shuffle() {
        for (int i = 0; i < sh.length; ++i) {
            int j = Rand.rrand(0, sh.length);
            int temp = sh[i];
            sh[i] = sh[j];
            sh[j] = temp;
        }
    }

    public void recombination() {
        shuffle();
        for (int i = 0; i < R*pop.length; i+=2) {
            pop[sh[i]].uniform(UP, pop[sh[i+1]]);
        }
    }

    public void mutation() {
        for (int i = 0; i < pop.length; ++i) {
            pop[i].mutate(M);
        }
    }

    public void outputPopulation(int gen) {
        try {
            popLog.write("Generation: " + gen + "\n");
            //for (int i = 0; i < pop.length; ++i) {
            //    popLog.write(pop[i].prettyPrint() + "\n");
            //}
            //popLog.write("\n");
            popLog.flush();
        } catch (Exception e) {
            System.err.println("Error Writing to File " + e.getMessage());
        }
    }

    public void outputBest(int gen) {
        if (!newBest)
            return;

        try {
            bestLog.write(gen + " " + best + " " + bestFitness + "\n");
            bestLog.flush();
            newBest = false;
        } catch (Exception e) {
            System.err.println("Error Writing Best " + e.getMessage());
        }
    }

    public void outputAverageFitness(int gen) {
        try {
            popLog.write(gen + " AvgFitness " + avg + "\n");
            popLog.flush();
        } catch (Exception e) {
            System.err.println("Error writing AvgFitness " + e.getMessage());
        }
    }
    public void finish() {
        try {
            popLog.close();
            bestLog.close();
        } catch (Exception e) {
            System.err.println("Error closing file " + e.getMessage());
        }
    }

    public static void main(String[] args) {
        Logger.inst().setDebugLevels("");
        GA ga = new GA();

        ga.initializePopulation();
        ga.evaluate();
        ga.outputPopulation(0);
        ga.outputBest(0);
        ga.outputAverageFitness(0);
        for (int i = 0; i < 1000; ++i) {
            ga.selection();
            ga.recombination();
            ga.mutation();
            ga.evaluate();
            ga.outputPopulation(i+1);
            ga.outputBest(i+1);
            ga.outputAverageFitness(i+1);
        }

        ga.finish();
    }
}
