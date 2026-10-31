/*
 * Calculator.java
 *
 * Created on September 8, 2004, 11:05 AM
 */

package graphics.wallCollision;

import java.util.Random;
/**
 *
 * @author  wkerr
 */
public class Calculator {
    
    public double globalInitialBearing;

    public double localGoalBearing;
    public double idealVx;
    public double idealVy;
    public double idealTheta;
    
    public double calculatedVx;
    public double calculatedVy;
    
    public double globalFinalBearing;
    public double globalVx;
    public double globalVy;
    
    /** Creates a new instance of Calculator */
    public Calculator() {
    }
    
    public void calculate() {
        localGoalBearing = 90 - globalInitialBearing;

        double sigma = 360.0 - localGoalBearing;
        double mpv = 2.0407;
        double stdev = 1.4430;
        Random rand = new Random(1);
        idealVx = Math.sqrt(-Math.log(1.0-rand.nextDouble()))*mpv;
        idealVy = randn(rand)*stdev;
      
        idealTheta = Math.toDegrees(Math.atan2(idealVy, idealVx));
        System.out.println("ideal vx " + idealVx + " vy " + idealVy + " theta " + idealTheta);

        double d = Math.sqrt(idealVx*idealVx + idealVy*idealVy);
        //double alpha = 270.0 + idealTheta - sigma;
        double alpha = localGoalBearing - 90 + idealTheta;
        
        System.out.println("Local Goal: " + localGoalBearing + " alpha " + alpha);
        calculatedVx = d*Math.cos(Math.toRadians(alpha));
        calculatedVy = d*Math.sin(Math.toRadians(alpha));
        
        System.out.println("Calculated vx " + calculatedVx + " vy " + calculatedVy);
        d = Math.sqrt(calculatedVx*calculatedVx + calculatedVy*calculatedVy);
        double turn = Math.toDegrees(Math.atan2(calculatedVy, calculatedVx));
        
        globalFinalBearing = globalInitialBearing + turn;
        globalVx = d*Math.cos(Math.toRadians(globalFinalBearing));
        globalVy = d*Math.sin(Math.toRadians(globalFinalBearing));
        
        System.out.println("Global vx " + globalVx + " vy " + globalVy);
    }
    
    public double randn(Random rand) {
        double randn = Math.sqrt(-2.0*Math.log(1.0 - rand.nextDouble())) * 
                       Math.cos(6.283185307 * rand.nextDouble());
        return randn;
    }
    
}
