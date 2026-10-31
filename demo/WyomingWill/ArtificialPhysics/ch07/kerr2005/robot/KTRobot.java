package robot;

/*
 * KTRobot.java
 *
 * Created on July 27, 2004, 10:19 AM
 */

import java.util.Random;

import util.Logger;

import env.Environment;

import sensor.RodSensor;
import sensor.SonarSensor;
import sensor.GoalSensor;
import sensor.CommunicationSensor;

import math.Intersection;
/**
 *
 * @author  Wesley Kerr
 */
public class KTRobot extends Robot {
    
    public static float mpv = 1.11777f; // T=0.0030 | 2.0407f; // T=0.01
    public static float stdev = 0.79038f; // T=0.0030 | 1.4430f; // T=0.01
    public static float wall = 2.0f; //0.5f;
    public static float safe = 15.0f;
    
    public boolean[] col;
    public int[] timeCounter;
    
    public Random rand;
    
    public float distance;
    public float turn;
    
    public float speed;
    
    private float vx;
    private float vy;
    
    private int timer          = 0;
    private boolean startTimer = false;
    
    private int stuckTimer     = 0;
    private boolean stuck      = false;
    
    /** Creates a new instance of KTRobot */
    public KTRobot() {
        super();
        
        rand = new Random(System.currentTimeMillis());
        speed = VMAX; 
        distance = speed;
        
        int numRobots = Environment.inst().getNumRobots();
        col = new boolean[numRobots];
        timeCounter = new int[numRobots];
    }
    
    public float getSpeed() {
        return speed;
    }
    
    public float getDistance() {
        return distance;
    }
    
    public float getTurn() {
        return turn;
    }

    public void move() {
        speed = distance;
        vx = distance;
        vy = 0;
        
        updateCollisionCounter();
        
        GoalSensor gs = new GoalSensor(id);
        float goalBearing = gs.getGoalBearing();

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
        //if (gs.atGoal()) {
        //    done = true;
        //    distance = 0;
        //    turn = 0;
        //    return;
        //}

        RodSensor rs = new RodSensor(id);
        rs.findVisibleRobots();
        int[] ids = rs.getIds();
        float[] bearings = rs.getBearings();
        float[] distances = rs.getDistances();
        
        SonarSensor ss = new SonarSensor(id, 24);
        ss.findSensorReadings();
        float[] ssBearings = ss.getBearings();
        float[] ssDistances = ss.getDistances();

        boolean collideWithWalls = true;
        if (ids != null) {
            for (int i = 0; i < bearings.length; ++i) {
                float bearing = bearings[i] < 0 ? bearings[i]+360 : bearings[i];
                if (((bearing < 45.0f && bearing > 0) ||(bearing > 315.0f && bearing < 360.0f)) 
                     && distances[i] < safe ) {
                    collideWithWalls = false;
                }
            }
        }
        if (collideWithWalls) {
            updateForWalls(goalBearing, ssBearings, ssDistances);
        }
        
        //if (!gs.nearGoal()) {
            updateForRobots(ids, bearings, distances);
        //    close = false;
        //} else {
        //    close = true;
        //}
        
        turn = (float) Math.toDegrees(Math.atan2(vy, vx));

        distance = determineSafeDistance(ss, turn);
        speed = distance;
        
        if (stuck && distance < 0.0001) {
            stuckTimer++;
            if (stuckTimer >= 5) {
                turn = rand.nextFloat()*360.0f;
                stuck = false;
            }
            distance = determineSafeDistance(ss, turn);
            speed = distance;
        } else if (distance < 0.0001) {
            stuck = true;
            stuckTimer = 0;
        }
    }
    
    private void updateCollisionCounter() {
        for (int i = 0; i < col.length; ++i) {
            if (col[i])
                timeCounter[i]++;
        }
    }

    private void updateForWalls(float goalBearing, float[] bearings, float[] distances) {
        
        if (distances[0] < safe || distances[6] < 2.0f || distances[18] < 2.0f) {
            
            float thetac = collisionParallel(distances, goalBearing);
            boolean parallel = false;
            if ((thetac < 45 && thetac > -45) ||
                (thetac > 135 && thetac < 225)) {
                parallel = true;
            }
  
            int dir = 1;
            if (distances[6] < distances[18]) {
                dir = -1;
            }
            
            float idealvx = ((float) Math.sqrt(-Math.log(1.0-rand.nextDouble()))*mpv);
            float idealvy = (float) (randn(rand)*stdev);
            float d = (float) Math.sqrt(idealvx*idealvx + idealvy*idealvy);
            float theta = (float) Math.toDegrees(Math.atan2(idealvy, idealvx));
            float alpha = (float) (goalBearing - 90.0f + theta);
            
            vx = (float) (d*Math.cos(Math.toRadians(alpha)));
            vy = (float) (d*Math.sin(Math.toRadians(alpha)));

            if (vx > 0) {
                vx *= -1;
            }

            if ((vy > 0 && dir == -1) ||
                (vy < 0 && dir != -1)) {
                vy *= -1;
            }
            
            if (parallel) {
                float goalvx = (float) (Math.cos(Math.toRadians(goalBearing))*wall);
                float goalvy = (float) (Math.sin(Math.toRadians(goalBearing))*wall);
                
                vx += goalvx;
                vy += goalvy;
            }
            
            
            Environment.inst().addWallCollision(id, distances);
        }
    }
    
    private void updateForRobots(int[] ids, float[] bearings, float[] distances) {
        
        if (ids == null)
            return;
        
        CommunicationSensor cs = new CommunicationSensor(id);
        cs.prepMessages();
        boolean[] senders = cs.getMessageSenders();
        float[][] values = cs.getMessageValues();
        
        boolean[] ignore = cs.getIgnoreMessages();
        for (int i = 0; i < ids.length; ++i) {
            
            int collidingId = ids[i];
            if (distances[i] > safe)
                continue;
            
            if (ignore[collidingId])
                continue;
            
            if (col[collidingId] && timeCounter[collidingId] < 5 &&
                bearings[i] > 45 && bearings[i] < 315) {
                    cs.sendIgnoreMessage(collidingId);
                    continue;
            }
            
            
            if (senders[collidingId]) {
                float newSpeed = values[collidingId][0];
                float newSpeedAngle = values[collidingId][1];
                float reverseBearing = values[collidingId][2];
                
                float alpha = 180.0f + bearings[i] - reverseBearing;
                vx += (float) newSpeed*Math.cos(Math.toRadians(alpha+newSpeedAngle));
                vy += (float) newSpeed*Math.sin(Math.toRadians(alpha+newSpeedAngle));
                
                col[collidingId] = true;
                timeCounter[collidingId] = 0;
                continue;
            }

            // somehow get the velocity in our coordinate system of id[i]
            // Possibly request bearing to me from robot ids[i]
            float collidingBearingToMe = cs.getReverseBearning(collidingId);
            float collidingSpeed = cs.getSpeed(collidingId);
            
            //float thetar = 180.0f - bearings[i] + collidingBearingToMe;
            float thetar = 180.0f + bearings[i] - collidingBearingToMe;
            float collidingVx = collidingSpeed * (float) Math.cos(Math.toRadians(thetar));
            float collidingVy = collidingSpeed * (float) Math.sin(Math.toRadians(thetar));
            
            float relativeSpeed = (float) Math.sqrt((collidingVx-speed)*(collidingVx-speed) + 
                                                    (collidingVy*collidingVy));
            
            float centerVelocity_x = 0.5f*(collidingVx + speed);
            float centerVelocity_y = 0.5f*(collidingVy);

            // calculate relative speed
            // calculate center of mass velocity.
            // choose a cos and sin of collision angle theta
            float cos_th = 1.0f - 2.0f*rand.nextFloat();
            float sin_th = (float) Math.sqrt(1.0 - cos_th*cos_th);
            
            float relx = relativeSpeed*cos_th;
            float rely = relativeSpeed*sin_th;
            
            float p1x = (centerVelocity_x + 0.5f*relx);
            float p1y = (centerVelocity_y + 0.5f*rely);
            
            float p2x = (centerVelocity_x - 0.5f*relx);
            float p2y = (centerVelocity_y - 0.5f*rely);
            
            float collidingRx = (float) (distances[i]*Math.cos(Math.toRadians(bearings[i])));
            float collidingRy = (float) (distances[i]*Math.sin(Math.toRadians(bearings[i])));
            
            float newCollidingRx = collidingRx + p2x;
            float newCollidingRy = collidingRy + p2y;
            
            float r_x = 0;
            float r_y = 0;
            
            float newRx = r_x + p1x;
            float newRy = r_y + p1y;
            
            float myvx = p1x;
            float myvy = p1y;
            
            float newCollidingVx = p2x;
            float newCollidingVy = p2y;
            
            boolean inter = Intersection.doLinesIntersect(r_x, r_y, newRx, newRy, 
                                                          collidingRx, collidingRy,
                                                          newCollidingRx, newCollidingRy);
            if (inter) {
                myvx = p2x;
                myvy = p2y;
                
                newCollidingVx = p1x;
                newCollidingVy = p1y;
            }
            
            vx += myvx;
            vy += myvy;
            
            float newCollidingSpeed = (float) Math.sqrt(newCollidingVx*newCollidingVx + 
                                                        newCollidingVy*newCollidingVy);
            
            float newCollidingTheta = (float) Math.toDegrees(Math.atan2(newCollidingVy, newCollidingVx));
            cs.sendMessage(ids[i], newCollidingSpeed, newCollidingTheta, bearings[i]);
            col[collidingId] = true;
            timeCounter[collidingId] = 0;
            
            Environment.inst().addRobotCollision(id, ids[i], bearings[i], collidingBearingToMe, 
                 thetar, cos_th, collidingVx, collidingVy, speed, 0, p1x, p1y, p2x, p2y);
        }
    }
    
    private float collisionParallel(float[] distances, float goalBearing) {
        boolean parallelCollision = false;
        float w1x = 0;
        float w1y = 0;
        float w2x = 0;
        float w2y = 0;
        
        float theta = 45.0f;
        for (int i = 0; i < distances.length; ++i, theta -= 15.0f) {
            if (distances[i] == 60.0f) {
                continue;
            }
            w1x = (float) (distances[i]*Math.cos(Math.toRadians(theta)));
            w1y = (float) (distances[i]*Math.sin(Math.toRadians(theta)));
            break;
        }
        
        theta = -45.0f;
        for (int i = distances.length-1; i >= 0; --i, theta += 15.0f) {
            if (distances[i] == 60.0f) {
                continue;
            }
            w2x = (float) (distances[i]*Math.cos(Math.toRadians(theta)));
            w2y = (float) (distances[i]*Math.sin(Math.toRadians(theta)));
            break;
        }
        
        
        float px = (float) (20.0*Math.cos(Math.toRadians(goalBearing)));
        float py = (float) (20.0*Math.sin(Math.toRadians(goalBearing)));
        
        float intPoint[] = Intersection.intersectionPoint(w1x, w1y, w2x, w2y, 0, 0, px, py);
        
        if (intPoint == null) {
            return 0;
        } else {
            float a2 = w1x*w1x + w1y*w1y;
            float b2 = intPoint[0]*intPoint[0] + intPoint[1]*intPoint[1];
            float c2 = (w1x-intPoint[0])*(w1x-intPoint[0]) + (w1y-intPoint[1])*(w1y-intPoint[1]);
            
            float top = b2 + c2 - a2;
            float bottom = (float) (2.0 * Math.sqrt(b2) * Math.sqrt(c2));
            
            float frac = top / bottom;
            float angle = (float) Math.toDegrees(Math.acos(frac));
            
            return angle;
        }
    }
    

    public double randn(Random rand) {
        double randn = Math.sqrt(-2.0*Math.log(1.0 - rand.nextDouble())) * 
                       Math.cos(6.283185307 * rand.nextDouble());
        return randn;
    }
}
