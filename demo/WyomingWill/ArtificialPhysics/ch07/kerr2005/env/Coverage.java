/*
 * Coverage.java
 *
 * Created on December 2, 2004, 8:36 PM
 */

package env;

import java.util.Hashtable;
import java.util.Iterator;

import obstacle.ObstacleContainer;
/**
 *
 * @author  Wesley Kerr
 */
public class Coverage {
    
    private int width;
    private int height;
    
    private int ncell_x;
    private int ncell_y;
    
    private boolean[][] coverage;
    
    private Hashtable obstacleArea;
    private Hashtable obstacleBehind;
    
    private int coveredCount = 0;
    private int behindCount  = 0;
    
    /** Creates a new instance of Coverage */
    public Coverage(Parameters p) {
        this.ncell_x = p.ncell_x;
        this.ncell_y = p.ncell_y;
        
        this.width  = p.width;
        this.height = p.height;
        
        coverage       = new boolean[ncell_y][ncell_x];
        obstacleArea   = new Hashtable();
        obstacleBehind = new Hashtable();
        
        ObstacleContainer.inst().fillHashtables(obstacleArea, obstacleBehind, 
                                                ncell_x, ncell_y, width, height);
    }
    
    public Hashtable getArea() {
        return obstacleArea;
    }
    
    public Hashtable getBehind() {
        return obstacleBehind;
    }
    
    public void updateCoverage(double x, double y) {
        int gridx = (int) (x*((double) ncell_x / (double) width));
        int gridy = (int) (y*((double) ncell_y / (double) height));
        
        gridx = ( gridx < ncell_x ) ? gridx : ncell_x - 1;
        gridy = ( gridy < ncell_y ) ? gridy : ncell_y - 1;
        
        boolean updateCoverage = false;
        if (!obstacleArea.contains(gridx+","+gridy) && !coverage[gridy][gridx]) {
            updateCoverage = true;
            ++coveredCount;
        }
        
        if (obstacleBehind.contains(gridx+","+gridy) && updateCoverage) {
            ++behindCount;
        }
        
        coverage[gridy][gridx] = true;
    }
    
    public int getCoverageCount() {
        return coveredCount;
    }
    
    public int getBehindCoverageCount() {
        return behindCount;
    }
    
    public int getTotalCellCount() {
        return (ncell_x*ncell_y - obstacleArea.size());
    }
    
    public int getBehindCount() {
        return obstacleBehind.size();
    }
    
    public double getCoveredPct() {
        return (double) getCoverageCount() / (double) getTotalCellCount();
    }
    
    public double getBehindPct() {
        return (double) getBehindCoverageCount() / (double) getBehindCount();
    }
}
