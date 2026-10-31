/*
 * Energy.java
 *
 * Created on December 2, 2004, 9:09 PM
 */

package env;

/**
 *
 * @author  Wesley Kerr
 */
public class Energy {
    
    private double totalEnergy;
    private double timeStepEnergy;
    
    private double timeSteps;
    /** Creates a new instance of Energy */
    public Energy() {
        timeSteps = 0;
    }
    
    public double getTotalEnergy() {
        return timeStepEnergy;
    }
    
    public double getAverageEnergy() {
        return totalEnergy / timeSteps;
    }
    
    public void addEnergy(double v) {
        double mass = 6.63e-26;
        timeStepEnergy += 0.5*(mass)*(v*v);
    }
    
    public void finishTimeStep() {
        timeSteps++;
        totalEnergy += timeStepEnergy;
        timeStepEnergy = 0;
    }
}
