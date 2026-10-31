/*
 * Momentum.java
 *
 * Created on December 2, 2004, 9:09 PM
 */

package env;

/**
 *
 * @author  Wesley Kerr
 */
public class Momentum {

    private double[] timeStepMomentum;
    private double[] totalMomentum;

    private double timeSteps;

    /** Creates a new instance of Momentum */
    public Momentum() {
        timeStepMomentum = new double[2];
        totalMomentum = new double[2];
        timeSteps = 0;
    }

    public double[] getTotalMomentum() {
        return totalMomentum;
    }

    public double[] getAverageMomentum() {
        double[] temp = new double[2];
        temp[0] = totalMomentum[0] / timeSteps;
        temp[1] = totalMomentum[1] / timeSteps;

        return temp;
    }

    public void addMomentum(double deltax, double deltay) {
        timeStepMomentum[0] += deltax;
        timeStepMomentum[1] += deltay;
    }

    public void finishTimeStep() {
        timeSteps++;
        totalMomentum[0] += timeStepMomentum[0];
        totalMomentum[1] += timeStepMomentum[1];

        timeStepMomentum[0] = 0;
        timeStepMomentum[1] = 0;
    }
}
