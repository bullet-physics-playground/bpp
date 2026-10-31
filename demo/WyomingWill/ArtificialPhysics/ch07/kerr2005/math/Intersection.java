/*
 * Intersection.java
 *
 * Created on August 24, 2004, 11:15 AM
 */

package math;

import sensor.SonarSensor;
/**
 *
 * @author  wkerr
 */
public class Intersection {

    /** Creates a new instance of Intersection */
    public Intersection() {
    }

    public static float circleIntersect(float x1, float y1, float x2, float y2, float centerx, float centery, float rad) {
        float deltax = x2 - x1;
        float deltay = y2 - y1;

        float a = deltax*deltax + deltay*deltay;
        float b = 2 * ((x2 - x1)*(x1 - centerx) + (y2 - y1)*(y1 - centery));
        float c = (centerx*centerx) + (centery*centery) + (x1*x1) + (y1*y1) -
                  (2*(centerx*x1 + centery*y1)) - (rad*rad);

        float mid = b*b - (4*a*c);
        if (mid < 0)
            return SonarSensor.max;

        float intx = 0.0f;
        float inty = 0.0f;

        float u1 = (-b + (float) Math.sqrt(mid)) / (2*a);
        float u2 = (-b - (float) Math.sqrt(mid)) / (2*a);

        float intx1 = x1 + u1*(x2-x1);
        float inty1 = y1 + u1*(y2-y1);

        if ((u1 < 0 || u1 > 1) && (u2 < 0 || u2 > 1)) {
            return SonarSensor.max;
        }

        float u = u1;
        if (u1 > 0 && u1 < 1 && u2 > 0 && u2 < 1) {
            if (u1 < u2) {
                u = u1;
            } else {
                u = u2;
            }
        } else if (u1 > 0 && u1 < 1) {
            u = u1;
        } else {
            u = u2;
        }

        intx = x1 + u*(x2-x1);
        inty = y1 + u*(y2-y1);
        return (float) Math.sqrt((intx-x1)*(intx-x1) + (inty-y1)*(inty-y1));
    }

    public static float lineIntersect(float x1, float y1,
                                      float x2, float y2,
                                      float x3, float y3,
                                      float x4, float y4) {
        float denom = (y4-y3)*(x2-x1) - (x4-x3)*(y2-y1);

        if (denom == 0.0f) {
            return SonarSensor.max;
        }

        float ua = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / denom;
        float ub = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / denom;

        if (ua <= 1 && ua >= 0 && ub <= 1 && ub >= 0) {
            float x = x1 + ua*(x2-x1);
            float y = y1 + ua*(y2-y1);

            return (float) Math.sqrt(Math.pow(x-x1,2) + Math.pow(y-y1,2));
        }

        return SonarSensor.max;
    }

    public static double[] intersectionPoint(double x1, double y1,
                                             double x2, double y2,
                                             double x3, double y3,
                                             double x4, double y4) {
        double denom = (y4-y3)*(x2-x1) - (x4-x3)*(y2-y1);

        if (denom == 0.0) {
            // Lines do not intersect
            return null;
        }

        double ua = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / denom;
        double ub = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / denom;

        double[] intPoint = new double[2];
        intPoint[0] = x1 + ua*(x2-x1);
        intPoint[1] = y1 + ua*(y2-y1);

        return intPoint;
    }

    public static float[] intersectionPoint(float x1, float y1,
                                            float x2, float y2,
                                            float x3, float y3,
                                            float x4, float y4) {
        double[] temp = intersectionPoint((double) x1,y1,x2,y2,x3,y3,x4,y4);

        if (temp == null) {
            return null;
        }

        float[] ret = new float[2];
        ret[0] = (float) temp[0];
        ret[1] = (float) temp[1];
        return ret;
    }

    public static boolean doLinesIntersect(float x1, float y1,
                                           float x2, float y2,
                                           float x3, float y3,
                                           float x4, float y4) {
        double denom = (y4-y3)*(x2-x1) - (x4-x3)*(y2-y1);

        if (denom == 0.0) {
            // Lines do not intersect
            return false;
        }

        double ua = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / denom;
        double ub = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / denom;

        if (ua <= 1 && ua >= 0 && ub <= 1 && ub >= 0)
            return true;
        return false;
    }
}
