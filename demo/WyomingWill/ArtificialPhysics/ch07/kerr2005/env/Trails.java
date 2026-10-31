/*
 * Trails.java
 *
 * Created on May 16, 2005, 11:39 AM
 */

package env;

import java.util.Hashtable;
import java.util.Iterator;
import java.util.StringTokenizer;

import robot.Robot;
import obstacle.ObstacleContainer;
/**
 *
 * @author  Wesley Kerr
 */
public class Trails {
    
    protected int ncell_x = 0;
    protected int ncell_y = 0;
    
    protected double xRatio = 0;
    protected double yRatio = 0;
    
    protected int[][] floorMarkings;
    
    /** Creates a new instance of Trails */
    public Trails(Parameters p) {
        //ncell_x = (int) (p.width / Robot.VMAX);
        //ncell_y = (int) (p.height / Robot.VMAX);
        ncell_x = p.ncell_x;
        ncell_y = p.ncell_y;
        
        xRatio = (double) ncell_x / (double) p.width;
        yRatio = (double) ncell_y / (double) p.height;
        
        floorMarkings = new int[ncell_y][ncell_x];
        
        Hashtable area = new Hashtable();
        Hashtable behind = new Hashtable();
        ObstacleContainer.inst().fillHashtables(area, behind, ncell_x, ncell_y, p.width, p.height);
        
        Iterator iter = area.keySet().iterator();
        while (iter.hasNext()) {
            String loc = (String) iter.next();
            StringTokenizer str = new StringTokenizer(loc, ",");
            if (str.countTokens() != 2) {
                System.out.println("ERROR - Wrong number of tokens");
                System.out.println("\tLine in error - " + loc);
                continue;
            }
            
            int x = Integer.parseInt(str.nextToken());
            int y = Integer.parseInt(str.nextToken());
            
            floorMarkings[y][x] = Integer.MAX_VALUE;
        }
    }
    
    public int getUValue(double x, double y) {
        int xPos = (int) (x * xRatio);
        int yPos = (int) (y * yRatio);
        
        if (xPos >= ncell_x || yPos >= ncell_y ||
            x < 0 || y < 0) {
            return Integer.MAX_VALUE;
        }
        
        return floorMarkings[yPos][xPos];
    }
    
    public int getUValue(double x, double y, int choice) {
        int xPos = (int) (x * xRatio);
        int yPos = (int) (y * yRatio);
        
        
        switch (choice) {
            case 0:
                yPos++;
                break;
            case 1:
                xPos--;
                break;
            case 2:
                yPos--;
                break;
            case 3:
                xPos++;
        }

        if (xPos >= ncell_x || yPos >= ncell_y ||
            xPos < 0 || yPos < 0) {
            return Integer.MAX_VALUE;
        }
        return floorMarkings[yPos][xPos];
    }
    
    
    public int[] getUValues(double x, double y) {
        int xPos = (int) (x * xRatio);
        int yPos = (int) (y * yRatio);
        
        int[] uValues = new int[4];
        if (xPos >= ncell_x || yPos >= ncell_y ||
            x < 0 || y < 0) {
            return uValues;
        }
        
        if (yPos - 1 < 0) {
            uValues[2] = Integer.MAX_VALUE;
        } else {
            uValues[2] = floorMarkings[yPos-1][xPos];
        }
        
        if (xPos - 1 < 0) {
            uValues[1] = Integer.MAX_VALUE;
        } else {
            uValues[1] = floorMarkings[yPos][xPos-1];
        }
        
        if (yPos + 1 >= ncell_y) {
            uValues[0] = Integer.MAX_VALUE;
        } else {
            uValues[0] = floorMarkings[yPos+1][xPos];
        }
        
        if (xPos + 1 >= ncell_x) {
            uValues[3] = Integer.MAX_VALUE;
        } else {
            uValues[3] = floorMarkings[yPos][xPos+1];
        }
        
        return uValues;
    }
    
    public void setUValue(double x, double y, int value) {
        int xPos = (int) (x * xRatio);
        int yPos = (int) (y * yRatio);
        
        floorMarkings[yPos][xPos] = value;
    }
    
    public void print() {
        for (int i = 0; i < ncell_y; ++i) {
            for (int j = 0; j < ncell_x; ++j) {
                System.out.print(floorMarkings[i][j] + "\t");
            }
            System.out.println();
        }
    }
    
    public void print(double[][] pos) {
        int[][] floorCopy = new int[ncell_y][ncell_x];
        for (int i = 0; i < ncell_y; ++i) {
            System.arraycopy(floorMarkings[i], 0, floorCopy[i], 0, ncell_x);
        }
        
        for (int i = 0; i < pos.length; ++i) {
            int xPos = (int) (pos[i][0] * xRatio);
            int yPos = (int) (pos[i][1] * yRatio);
            
            floorCopy[yPos][xPos] = -1;
        }
        
        for (int i = 0; i < ncell_y; ++i) {
            for (int j = 0; j < ncell_x; ++j) {
                System.out.print(floorCopy[i][j] + "\t");
            }
            System.out.println();
        }
        System.out.println();
    }
}
