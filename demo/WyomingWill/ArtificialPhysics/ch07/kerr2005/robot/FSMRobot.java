/*
 * FSMControl.java
 *
 * Created on October 26, 2004, 2:07 PM
 */

package robot;

import java.io.*;
import java.util.*;

import util.FSM;
import util.Node;

import env.Environment;
import sensor.SonarSensor;
import sensor.GoalSensor;
/**
 *
 * @author  wkerr
 */
public class FSMRobot extends Robot {
    
    private Random rand;
    
    protected float distance;
    protected float turn;
    protected float divisor;
    protected int   previous;

    private FSM    fsm;
    private int  currentState;
   
    private SonarSensor ss;
    private GoalSensor  gs;
    
    /** Creates a new instance of FSMControl */
    public FSMRobot() {
        super();
        
        distance = VMAX;
        turn = 0;
        previous = 0;
        
        divisor = 360.0f / 24.0f;
    }
    
    public void setId(int id) {
        this.id = id;
        
        ss = new SonarSensor(id, 24);
        gs = new GoalSensor(id);

        rand = new Random(System.currentTimeMillis() + id);
        
        try {
           String file = ClassLoader.getSystemClassLoader().getResource("data/").getPath();
           loadFSM(file+"FSM.txt", 13);
        } catch (Exception e) {
            System.out.println("ERROR - Loading FSM: " + e.getMessage());
            fsm = new FSM();
            fsm.generateRandom();
        }
    }
    
    public void setFSM(FSM fsm) {
        this.fsm = fsm;
    }
    
    public void loadFSM(String file, int index) throws Exception {
        BufferedReader in = new BufferedReader(new FileReader(file));
        boolean found = false;
        for (int i = 0; in.ready() && !found; ++i) {
            String line = in.readLine();
            StringTokenizer str = new StringTokenizer(line, " ");
            int curr = Integer.parseInt(str.nextToken());
            if (curr == index) {
                fsm = new FSM();
                fsm.load(line);
                found = true;
            }
        }
    }
    
    public void move() {
        
        ss.findSensorReadings();
        float[] bearings = ss.getBearings();
        float[] distances = ss.getDistances();
        
        float goal = gs.getGoalBearing();

        if (gs.nearGoal() && !startTimer) {
            startTimer = true;
            timer = 0;
        } else if (gs.nearGoal() && startTimer) {
            timer++;
        } else if (!gs.nearGoal() && startTimer) {
            startTimer = false;
        }
        
        if (timer >= 10 && gs.nearGoal()) {
            done = true;
            turn = 0; 
            distance = 0;
            return;
        }
        
        while (goal < 0) {
            goal += 360.0f;
        }
        
        boolean[] options = getOptions(distances, goal);
        StringBuffer buf = new StringBuffer();
        for (int j = 0; j < options.length; ++j) {
            if (options[j])
                buf.insert(0,0);
            else
                buf.insert(0,1);
        }
        int input = Integer.parseInt(buf.toString(), 2);
        int choice = fsm.getAction(currentState, input);
        currentState = fsm.getState(currentState, input);
        
        float newAngle = goal - (45.0f * (float)choice);
        while (newAngle < 0) {
            newAngle += 360;
        }
        
        turn = newAngle;
        distance = determineSafeDistance(ss, turn);
    }
    
    protected boolean[] getOptions(float[] distances, float goal) {
        float safeZone = 3*VMAX;
        boolean[] options = new boolean[8];
        float angle = goal;
        for (int i = 0; i < 8; ++i) {
            int index = (int) Math.round(angle / divisor);
            index = (index == 24) ? 0 : index;
            if (distances[index] > safeZone) {
                options[i] = true;
            }
            
            angle -= 45.0f;
            if (angle < 0) {
                angle += 360.0f;
            }
        }
        return options;
    }

    public float getDistance() {
        return distance;
    }
    
    public float getSpeed() {
        return distance;
    }
    
    public float getTurn() {
        return turn;
    }
}
