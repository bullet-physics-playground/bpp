/*
 * ImageWriter.java
 *
 * Created on January 12, 2004, 3:18 PM
 */

package util;

import com.sun.image.codec.jpeg.JPEGCodec;
import com.sun.image.codec.jpeg.JPEGImageEncoder;

import java.awt.*;
import java.io.*;
import java.awt.image.*;
import java.util.*;

import obstacle.Obstacle;
import obstacle.ObstacleContainer;

import env.Environment;
/**
 *
 * @author  Wesley Kerr
 */
public class ImageSaver extends graphics.ui.DisplayPanel {
    private static ImageSaver image = null;
    
    /** Creates a new instance of ImageWriter */
    private ImageSaver() {
    }
    
    public static ImageSaver inst() {
        if (image == null) {
            image = new ImageSaver();
        }
        return image;
    }

    public void saveImage(BufferedImage bi, String fileName) {
        try {
            FileOutputStream os = new FileOutputStream(fileName);
            JPEGImageEncoder ie = JPEGCodec.createJPEGEncoder(os);
            ie.encode(bi, JPEGCodec.getDefaultJPEGEncodeParam(bi));
            os.close();
        }
        catch (Exception e) {
            System.out.println("Error - " + e.getMessage());
        }
    }

    public BufferedImage getPlainImage(int width, int height) {
        BufferedImage bi = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = (Graphics2D) bi.getGraphics();
        
        g.setColor(Color.white);
        g.fillRect(0, 0, width, height);
        
        Font f1 = g.getFont();
        Font f2 = f1.deriveFont(9.0f);
        g.setFont(f2);

        Environment e = Environment.inst();
       
        double scaleX = (double) width / (double) e.getWidth();
        double scaleY = (double) height / (double) e.getHeight();
        
        double scale = Math.min(scaleX, scaleY);
        
        paintLowerElements(g, scale);
        paintRobots(g, scale);
        return bi;
    }
}
