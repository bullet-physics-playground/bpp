/*
 * ObstacleGenerator.java
 *
 * Created on October 7, 2004, 10:03 PM
 */

package obstacleGenerator;

import java.util.*;
import java.io.*;
import java.util.Random;
/**
 *
 * @author  wkerr
 */
public class ObstacleGenerator {
    
    private Random rand = new Random();
    
    /** Creates a new instance of ObstacleGenerator */
    public ObstacleGenerator(long seed) {
        if (seed != -1) {
            rand = new Random(seed);
        }
    }
    
    public void generateCourses(int pct) {
        String path = ClassLoader.getSystemClassLoader().getResource("data/").getPath();
        for (int j = 0; j < 10; ++j) {
            boolean[][] placed = generate((double)pct/100.0);
            printObstacleCourse(path+"video_"+pct+"_"+j+".txt", prepareCourse(placed));
        }
    }
    
    private double[][] preprocess(int nW, int nH) {
        double[][] d = new double[nH][nW];
        for (int i = 0; i < nH; ++i) {
            for (int j = 0; j < nW; ++j) {
                d[i][j] = 0.01;
            }
        }
        return d;
    }
    
    private int checkForCycles(boolean[][] placed) {
        boolean[][] checkArray = new boolean[placed.length][placed[0].length];
        
        LinkedList foundList = new LinkedList();
        boolean place = false;
        for (int i = 0; i < placed.length && !place; ++i) {
            for (int j = 0; j < placed[0].length && !place; ++j) {
                if (!placed[i][j]) {
                    checkArray[i][j] = true;
                    place = true;
                    Point p = new Point();
                    p.x = j;
                    p.y = i;
                    foundList.add(p);
                }
            }
        }
        
        
        while (!foundList.isEmpty()) {
            Point p = (Point) foundList.removeFirst();
            if (p.x > 0) {
                if (!placed[p.y][p.x-1] && !checkArray[p.y][p.x-1]) {
                    checkArray[p.y][p.x-1] = true;
                    Point p2 = new Point();
                    p2.x = p.x-1;
                    p2.y = p.y;
                    foundList.addLast(p2);
                }
            }
            
            if (p.y > 0) {
                if (!placed[p.y-1][p.x] && !checkArray[p.y-1][p.x]) {
                    checkArray[p.y-1][p.x] = true;
                    Point p2 = new Point();
                    p2.x = p.x;
                    p2.y = p.y-1;
                    foundList.addLast(p2);
                }
            }
            
            if (p.x < placed[0].length-1) {
                if (!placed[p.y][p.x+1] && !checkArray[p.y][p.x+1]) {
                    checkArray[p.y][p.x+1] = true;
                    Point p2 = new Point();
                    p2.x = p.x+1;
                    p2.y = p.y;
                    foundList.addLast(p2);
                }
            }
            
            if (p.y < placed.length-1) {
                if (!placed[p.y+1][p.x] && !checkArray[p.y+1][p.x]) {
                    checkArray[p.y+1][p.x] = true;
                    Point p2 = new Point();
                    p2.x = p.x;
                    p2.y = p.y+1;
                    foundList.addLast(p2);
                }
            }
        }
        
        int reachable = 0;
        int notReachable = 0;
        for (int i = 0; i < placed.length; ++i) {
            for (int j = 0; j < placed[0].length; ++j) {
                if (!placed[i][j] && checkArray[i][j]) {
                    reachable++;
                } else if (!placed[i][j]) {
                    notReachable++;
                }
            }
        }
        
        //System.out.println("Reachable " + reachable);
        //System.out.println("Not Reachable " + notReachable);
        boolean choice = reachable >= notReachable ? false : true;
        for (int i = 0; i < placed.length; ++i) {
            for (int j = 0; j < placed[0].length; ++j) {
                if (!placed[i][j] && checkArray[i][j] == choice) {
                    placed[i][j] = true;
                }
            }
        }
        
        return Math.min(reachable, notReachable);
    }
    
    public boolean[][] generate(double pct) {
        int numW = 40;
        int numH = 40;
        
        boolean[][] placed = new boolean[numH][numW];
        double[][] d = preprocess(numW,numH);
        
        double count = 0;
        double total = numW*numH;
        double coverage = 0.0;
        
        int squareSize = 10;
        if (pct < 0.3) {
            squareSize = 5;
        }
        while (coverage < pct) {
            int i = rand.nextInt(numH);
            int j = rand.nextInt(numW);
            if (!placed[i][j] && rand.nextDouble() < d[i][j]) {
                int right = Math.min(j+squareSize, numW-1);
                int bottom = Math.min(i+squareSize, numH-1);
                for (int k = i; k <= bottom && coverage < pct; ++k) {
                    for (int l = j; l <= right && coverage < pct; ++l) {
                        if (placed[k][l]) {
                            continue;
                        }
                        
                        placed[k][l] = true;
                        int newPlaced = checkForCycles(placed);
                        count += newPlaced;
                        ++count;
                        coverage = count / total;
                    }
                }
                //System.out.println("Coverage " + coverage);
            }
        }
        System.out.println("coverage " + coverage);
        return placed;
    }
    
    private boolean hasPath(boolean[][] placed) {
        boolean left = false;
        boolean right = false;
        for (int i = 0; i < placed.length; ++i) {
            if (!placed[i][0]) {
                left = true;
            }
            if (!placed[i][placed[i].length-1]) {
                right = true;
            }
        }
        return left || right;
    }
    
    public ArrayList prepareCourse(boolean[][] placed) {
        Builder b = new Builder();
        return b.build(placed);
    }
    
    public void printObstacleCourse(String file, ArrayList l) {
        double width = 400;
        double height = 400;
        
        double squareWidth = width / 40.0;
        double squareHeight = height / 40.0;
        
        double offsetY = 400;
        
        try {
            BufferedWriter buf = new BufferedWriter(new FileWriter(file));
            Iterator iter = l.iterator();
            while (iter.hasNext()) {
                Rectangle r = (Rectangle) iter.next();
                buf.write("0 ");
                buf.write((r.x1*squareWidth) + " ");
                buf.write((r.y1*squareHeight + offsetY) + " ");
                buf.write(((r.x2+1)*squareWidth) + " ");
                buf.write(((r.y2+1)*squareHeight + offsetY) + " ");
                buf.write("\n");
            }
            buf.close();
        } catch (IOException e) {
            
        }
    }
    
    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) {
        if (args.length != 1) {
            String usage = "Usage: ObstacleGenerator <seed>";
            System.err.println(usage);
            System.exit(0);
        }
        
        long seed       = Long.parseLong(args[0]);
        
        ObstacleGenerator og = new ObstacleGenerator(seed);
        for (int i = 20; i < 30; i+=10) {
            og.generateCourses(i);
        }
    }
    
}

class Point {
    public int x;
    public int y;
}
