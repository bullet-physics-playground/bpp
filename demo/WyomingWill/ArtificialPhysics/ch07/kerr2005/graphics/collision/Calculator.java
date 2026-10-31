/*
 * Calculator.java
 *
 * Created on September 8, 2004, 11:05 AM
 */

package graphics.collision;

/**
 *
 * @author  wkerr
 */
public class Calculator {
    
    public double globalAx;
    public double globalAy;
    public double globalAvx;
    public double globalAvy;
    public double globalAspeed;
    public double globalAangle;
    public double globalAthetaB;
    
    public double globalBx;
    public double globalBy;
    public double globalBvx;
    public double globalBvy;
    public double globalBspeed;
    public double globalBangle;
    public double globalBthetaA;
    
    public double finalGlobalAvx;
    public double finalGlobalAvy;
    
    public double finalGlobalBvx;
    public double finalGlobalBvy;

    public double localAvx;
    public double localAvy;
    public double localAspeed;
    public double localAthetaB;
    public double localAthetaR;
    
    public double localBvx;
    public double localBvy;
    public double localBspeed;
    public double localBthetaA;
    public double localBthetaR;
    
    public double finalLocalAvx;
    public double finalLocalAvy;
    
    public double finalLocalBvx;
    public double finalLocalBvy;


    /** Creates a new instance of Calculator */
    public Calculator() {
    }
    
    public void calculate() {
        globalAspeed = Math.sqrt(globalAvx*globalAvx + globalAvy*globalAvy);
        globalAangle = Math.toDegrees(Math.atan2(globalAvy, globalAvx));
        
        globalBspeed = Math.sqrt(globalBvx*globalBvx + globalBvy*globalBvy);
        globalBangle = Math.toDegrees(Math.atan2(globalBvy, globalBvx));

        double Adeltax = globalBx - globalAx;
        double Adeltay = globalBy - globalAy;
        globalAthetaB = Math.toDegrees(Math.atan2(Adeltay, Adeltax));

        double Bdeltax = globalAx - globalBx;
        double Bdeltay = globalAy - globalBy;
        globalBthetaA = Math.toDegrees(Math.atan2(Bdeltay, Bdeltax));
        
        localAvx = globalAspeed;
        localAvy = 0;
        localAspeed = globalAspeed;

        localAthetaB = globalAthetaB - globalAangle;
        localBthetaA = globalBthetaA - globalBangle;
        
        localAthetaR = 180 + localAthetaB - localBthetaA;
        localBthetaR = 180 + localBthetaA - localAthetaB;
        System.out.println("ThetaAB " + localAthetaB + " ThetaBA " + localBthetaA);
        System.out.println("ThetaR " + localAthetaR);
        
        localBspeed = globalBspeed;
        localBvx = localBspeed*Math.cos(Math.toRadians(localAthetaR));
        localBvy = localBspeed*Math.sin(Math.toRadians(localAthetaR));

        calculateLocal();
    }
        
    private void calculateLocal() {
        double cr = Math.sqrt(Math.pow(localAvx-localBvx,2) + Math.pow(localAvy-localBvy,2));
        double vcmx = 0.5*(localAvx + localBvx);
        double vcmy = 0.5*(localAvy + localBvy);
        
        double cos_th = -1.0;
        double sin_th = 0.0;
        
        double vrelx = cr*cos_th;
        double vrely = cr*sin_th;
        
        finalLocalAvx = vcmx + 0.5*vrelx;
        finalLocalAvy = vcmy + 0.5*vrely;
        
        finalLocalBvx = vcmx - 0.5*vrelx;
        finalLocalBvy = vcmy - 0.5*vrely;

        double Aturn = Math.toDegrees(Math.atan2(finalLocalAvy, finalLocalAvx));
        double Bturn = Math.toDegrees(Math.atan2(finalLocalBvy, finalLocalBvx));
        
        double Adistance = Math.sqrt(finalLocalAvx*finalLocalAvx + finalLocalAvy*finalLocalAvy);
        double Bdistance = Math.sqrt(finalLocalBvx*finalLocalBvx + finalLocalBvy*finalLocalBvy);
        
        double finalAangle = globalAangle+Aturn;
        double finalBangle = globalAangle+Bturn;
        
        finalGlobalAvx= Adistance*Math.cos(Math.toRadians(finalAangle));
        finalGlobalAvy = Adistance*Math.sin(Math.toRadians(finalAangle));
        
        finalGlobalBvx = Bdistance*Math.cos(Math.toRadians(finalBangle));
        finalGlobalBvy = Bdistance*Math.sin(Math.toRadians(finalBangle));

        double newSpeed = Bdistance;
        double newSpeedAngle = Bturn;
        double bearing = localAthetaB;
                
        double alpha = 180.0f + localBthetaA - bearing;
        double vx = newSpeed*Math.cos(Math.toRadians(alpha+newSpeedAngle));
        double vy = newSpeed*Math.sin(Math.toRadians(alpha+newSpeedAngle));
        
        System.out.println("B vx " + vx + " vy " + vy);
        System.out.println("Turn " + Math.toDegrees(Math.atan2(vy, vx)) + " Bturn " + Bturn + " alpha " + alpha);
        System.out.println("Global B angle " + globalBangle);
        System.out.println("New Global angle " + (globalBangle+alpha-newSpeedAngle));
        double newAngle = globalBangle+alpha+newSpeedAngle;
        System.out.println("vx " + (newSpeed*Math.cos(Math.toRadians(newAngle))));
        System.out.println("vy " + (newSpeed*Math.sin(Math.toRadians(newAngle))));
    }
}
