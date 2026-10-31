/*
 * ObstacleContainer.java
 *
 * Created on August 24, 2004, 11:33 AM
 */

package obstacle;

import java.io.*;

import java.util.LinkedList;
import java.util.List;
import java.util.Iterator;
import java.util.StringTokenizer;
import java.util.Hashtable;

import java.awt.Graphics2D;
import java.awt.Color;
/**
 *
 * @author  wkerr
 */
public class ObstacleContainer {
    
    private List list;
    
    private static ObstacleContainer oc = null;
    
    /** Creates a new instance of ObstacleContainer */
    private ObstacleContainer() {
        list = new LinkedList();
    }
    
    public static ObstacleContainer inst() {
        if (oc == null)
            oc = new ObstacleContainer();
        
        return oc;
    }
    
    public void clear() {
        list = new LinkedList();
    }
    
    public List getObstacles() {
        return list;
    }
    
    public void draw(Graphics2D g, Color c, double scale, boolean fill) {
        if (list == null) {
            return;
        }
        
        Iterator iter = list.iterator();
        while (iter.hasNext()) {
            Obstacle o = (Obstacle) iter.next();
            o.draw(g, c, scale, fill);
        }
    }
    
    public void loadObstacles(String fileName) throws IOException {
        list = new LinkedList();
        try {
            float x1, x2, x3;
            float y1, y2, y3;
            float r;
            BufferedReader in = new BufferedReader(new FileReader(fileName));
            while (in.ready()) {
                String line = in.readLine();
                StringTokenizer str = new StringTokenizer(line, " ");
                int type = Integer.parseInt(str.nextToken());
                switch (type) {
                    case 0: // Square
                        x1 = Float.parseFloat(str.nextToken());
                        y1 = Float.parseFloat(str.nextToken());
                        x2 = Float.parseFloat(str.nextToken());
                        y2 = Float.parseFloat(str.nextToken());
                        list.add(new Square(x1, y1, x2, y2));
                        break;
                    case 1: // Circle
                        x1 = Float.parseFloat(str.nextToken());
                        y1 = Float.parseFloat(str.nextToken());
                        r = Float.parseFloat(str.nextToken());
                        list.add(new Circle(x1, y1, r));
                        break;
                    case 2: // Triangle
                        x1 = Float.parseFloat(str.nextToken());
                        y1 = Float.parseFloat(str.nextToken());
                        x2 = Float.parseFloat(str.nextToken());
                        y2 = Float.parseFloat(str.nextToken());
                        x3 = Float.parseFloat(str.nextToken());
                        y3 = Float.parseFloat(str.nextToken());
                        list.add(new Triangle(x1, y1, x2, y2, x3, y3));
                        break;
                }
            }
        } catch (IOException e) {
            list = new LinkedList();
            throw e;
        }
    }
    
    public void fillHashtables(Hashtable area, Hashtable behind, 
                               int ncell_x, int ncell_y, int width, int height) {

        double[] ratio = new double[2];
        double[] cellDim2 = new double[2];
        
        ratio[0] = (double) ncell_x / (double) width;
        ratio[1] = (double) ncell_y / (double) height;
        
        cellDim2[0] = ((double) width / (double) ncell_x) / 2.0;
        cellDim2[1] = ((double) height / (double) ncell_y) / 2.0;

        Iterator iter = list.iterator();
        while (iter.hasNext()) {
            Obstacle o = (Obstacle) iter.next();
            o.fillAreaHashtable(area, ratio, cellDim2);
        }
        
        iter = list.iterator();
        while (iter.hasNext()) {
            Obstacle o = (Obstacle) iter.next();
            o.fillBehindHashtable(area, behind, ratio, cellDim2);
        }
        
    }
    
    public void saveObstacles(String fileName) throws IOException{
        BufferedWriter out = new BufferedWriter(new FileWriter(fileName));
        Iterator iter = list.iterator();
        while (iter.hasNext()) {
            Obstacle o = (Obstacle) iter.next();
            o.write(out);
        }
    }
    
    public boolean inside(double x, double y) {
        Iterator iter = list.iterator();
        while (iter.hasNext()) {
            Obstacle o = (Obstacle) iter.next();
            if (o.inside(x, y)) {
                return true;
            }
        }
        return false;
    }
}
