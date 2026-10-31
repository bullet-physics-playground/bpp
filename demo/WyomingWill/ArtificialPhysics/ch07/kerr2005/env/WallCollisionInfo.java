/*
 * CollisionInfo.java
 *
 * Created on August 31, 2004, 10:44 AM
 */

package env;

/**
 *
 * @author  wkerr
 */
public class WallCollisionInfo {
    
    public int robotId;
    public float[] distances;
    
    /** Creates a new instance of CollisionInfo */
    public WallCollisionInfo(int id, float[] distances) {
        this.robotId = id;
        this.distances = distances;
    }
    
}
