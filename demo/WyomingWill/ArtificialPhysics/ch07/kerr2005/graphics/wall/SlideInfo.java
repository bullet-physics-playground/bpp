/*
 * SlideInfo.java
 *
 * Created on August 31, 2004, 12:07 PM
 */

package graphics.wall;

/**
 *
 * @author  wkerr
 */
public class SlideInfo {
    
    public double x;
    public double y;
    
    public int wall;
    public double[] sensor;
    public double bearing;
    public double goalBearing;
    
    /** Creates a new instance of SlideInfo */
    public SlideInfo() {
        sensor = new double[7];
    }
    
}
