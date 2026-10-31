/*
 * FSM.java
 *
 * Created on October 24, 2004, 11:02 PM
 */

package util;

import java.io.*;
import java.util.*;

/**
 * actions & inputs index
 *   index = goal - (45*i)
 *
 * meaning
 *   0 - Available
 *   1 - Not Available
 * @author  Wesley Kerr
 */
public class FSM {
    public static int numStates = 8;
    public static int numActions = 8;
    public static int numInputs = (int) Math.pow(2, numActions);

    private static List[] prefs;

    private int currentState;
    private Node[][] table;
    private double fitness;

    /** Creates a new instance of FSM */
    public FSM() {
        table = new Node[numStates][numInputs];
        fitness = -1;
    }

    public static void addOne(boolean[] options) {
        for (int i = 0; i < options.length; ++i) {
            if (!options[i]) {
                options[i] = true;
                return;
            } else {
                options[i] = false;
            }
        }
    }

    public static void print(boolean[] options) {
        for (int i = 0; i < options.length; ++i) {
            if (options[i]) {
                System.out.print("1 ");
            } else {
                System.out.print("0 ");
            }
        }
        System.out.println();
    }

    public static void loadPrefs() {
        boolean[] options = { false, false, false, false, false, false, false, false };
        prefs = new List[numInputs];

        for (int i = 0; i < numInputs; ++i) {
            prefs[i] = new LinkedList();
        }

        for (int i = 0; i < numInputs; ++i) {
            for (int j = 0; j < options.length; ++j) {
                if (!options[j]) {
                    prefs[i].add(new Integer(j));
                }
            }
            addOne(options);
        }

        prefs[8] = new LinkedList();
        prefs[8].add(new Integer(0));
        prefs[8].add(new Integer(1));
        prefs[8].add(new Integer(2));

        prefs[24] = new LinkedList();
        prefs[24].add(new Integer(0));
        prefs[24].add(new Integer(1));
        prefs[24].add(new Integer(2));

        prefs[32] = new LinkedList();
        prefs[32].add(new Integer(0));
        prefs[32].add(new Integer(6));
        prefs[32].add(new Integer(7));

        prefs[48] = new LinkedList();
        prefs[48].add(new Integer(0));
        prefs[48].add(new Integer(6));
        prefs[48].add(new Integer(7));

        prefs[131] = new LinkedList();
        prefs[131].add(new Integer(2));
        prefs[131].add(new Integer(6));

        prefs[129] = new LinkedList();
        prefs[129].add(new Integer(1));
        prefs[129].add(new Integer(2));

        prefs[3] = new LinkedList();
        prefs[3].add(new Integer(6));
        prefs[3].add(new Integer(7));
    }

    private int chooseRandomAction(int index) {
        List l = prefs[index];
        double rand = Rand.nextDouble();

        double max = 1.0 / (double) l.size();
        double ratio = max;
        Iterator iter = l.iterator();
        while (iter.hasNext()) {
            Integer n = (Integer) iter.next();
            if (rand < max) {
                return n.intValue();
            } else {
                max += ratio;
            }
        }
        return 0;
    }

    public void generateRandom() {
        for (int i = 0; i < numStates; ++i) {
            for (int j = 0; j < numInputs; ++j) {
                int state = Rand.rrand(0, numStates);
                int action = chooseRandomAction(j);
                table[i][j] = new Node(state, action);
            }
        }
    }

    public int getAction(int state, int input) {
        return table[state][input].getAction();
    }

    public int getState(int state, int input) {
        return table[state][input].getState();
    }

    public double getFitness() {
        return fitness;
    }

    public void setFitness(double fitness) {
        this.fitness = fitness;
    }

    public void copy(FSM fsm) {
        for (int i = 0; i < numStates; ++i) {
            for (int j = 0; j < numInputs; ++j) {
                //table[i][j] = new Node(fsm.table[i][j]);
                table[i][j] = new Node();
                table[i][j].setState(fsm.table[i][j].getState());
                table[i][j].setAction(fsm.table[i][j].getAction());
            }
        }

        fitness = fsm.fitness;
    }

    public void uniform(double uniProb, FSM fsm) {
        fitness = -1;
        for (int i = 0; i < numStates; ++i) {
            for (int j = 0; j < numInputs; ++j) {
                if (Rand.nextDouble() < uniProb) {
                    Node temp = fsm.table[i][j];
                    fsm.table[i][j] = table[i][j];
                    table[i][j] = temp;
                }
            }
        }
    }

    public void mutate(double mutRate) {
        for (int i = 0; i < numStates; ++i) {
            for (int j = 0; j < numInputs; ++j) {
                if (Rand.nextDouble() < mutRate) {
                    fitness = -1;
                    if (Rand.nextBoolean()) {  // Update the state
                        table[i][j].setState(Rand.rrand(0, numStates));
                    } else {
                        table[i][j].setAction(chooseRandomAction(j));
                    }
                }
            }
        }
    }

    public String toString() {
        StringBuffer buf = new StringBuffer();
        for (int i = 0; i < numStates; ++i) {
            for (int j = 0; j < numInputs; ++j) {
                buf.append(table[i][j].toString() + " ");
            }
        }
        return buf.toString();
    }

    public String prettyPrint() {
        StringBuffer buf = new StringBuffer();
        for (int i = 0; i < numStates; ++i) {
            for (int j = 0; j < 8; ++j) {
                buf.append(table[i][j].toString() + " ");
            }
            buf.append("\n");
        }
        return buf.toString();
    }

    public void load(String line) {
        StringTokenizer str = new StringTokenizer(line, " ");
        str.nextToken();
        for (int i = 0; i < numStates; ++i) {
            for (int j = 0; j < numInputs; ++j) {
                Node n = new Node();
                n.load(str.nextToken());
                table[i][j] = n;
            }
        }
    }
}
