/*
 * Message.java
 *
 * Created on August 30, 2004, 10:32 AM
 */

package sensor;

/**
 *
 * @author  wkerr
 */
public class Message {
    
    public int senderId;
    public int recieverId;
    public float speed;
    public float speedAngle;
    public float bearing;
    
    /** Creates a new instance of Message */
    public Message(int sender, int reciever, float speed, float speedAngle, float bearing) {
        this.senderId = sender;
        this.recieverId = reciever;
        this.speed = speed;
        this.speedAngle = speedAngle;
        this.bearing = bearing;
    }
    
}
