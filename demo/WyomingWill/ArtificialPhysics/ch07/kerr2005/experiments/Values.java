/*
 * Values.java
 *
 * Created on September 14, 2004, 10:50 AM
 */

package experiments;

/**
 *
 * @author  wkerr
 */
public class Values {
    
    public final double boltz = 1.3806e-23;  // Boltzmann's constant (J/K)
    public double mass = 6.63e-26;           // Mass of argon atom (kg)

    /** Creates a new instance of Values */
    public Values() {
        double T = 0.0;
        
        for (int i = 0; i < 20; ++i) {
            System.out.println("Temperature " + T);
            System.out.println("<v> " + (0.25*Math.sqrt(8.0*Math.PI*boltz*T/mass)));
            System.out.println("MPV " + Math.sqrt(2.0*boltz*T/mass));
            System.out.println("STD " + Math.sqrt(boltz*T/mass));
            T += 0.001;
        }
    }
    
    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) {
        new Values();
    }
    
}
