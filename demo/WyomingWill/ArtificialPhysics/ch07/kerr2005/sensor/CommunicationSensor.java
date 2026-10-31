/*
 * CommunicationSensor.java
 *
 * Created on July 27, 2004, 1:29 PM
 */

package sensor;

import java.util.List;
import java.util.Iterator;

import env.Environment;
import robot.Robot;
/**
 *
 * @author  Wesley Kerr
 */
public class CommunicationSensor {

    private float[][] messageValues;
    private boolean[] messageSenders;
    private boolean[] ignoring;

    private int robotId;

    /** Creates a new instance of CommunicationSensor */
    public CommunicationSensor(int id) {
        robotId = id;
    }

    public float getSpeed(int id) {
        Robot robot = Environment.inst().getRobot(id);

        return robot.getSpeed();
    }

    public float getReverseBearning(int id) {
        double[][] positions = Environment.inst().getPositions();
        double[] bearings = Environment.inst().getBearings();

        double x = positions[robotId][0];
        double y = positions[robotId][1];

        double bearing = bearings[id];

        double deltax = positions[id][0] - x;
        double deltay = positions[id][1] - y;

        float theta = (float) (Math.toDegrees(Math.atan2(deltay, deltax)) - bearing);
        return theta;
    }

    public void sendMessage(int receiver, float speed, float speedAngle, float bearingMeToYou) {
        Message m = new Message(robotId, receiver, speed, speedAngle, bearingMeToYou);
        Environment.inst().addMessage(m);
    }

    public void sendIgnoreMessage(int reciever) {
        Environment.inst().robotIgnoring(robotId, reciever);
    }

    public void prepMessages() {
        messageSenders = new boolean[Environment.inst().getNumRobots()];
        messageValues = new float[Environment.inst().getNumRobots()][3];

        List l = Environment.inst().getMessages(robotId);
        Iterator iter = l.iterator();
        while (iter.hasNext()) {
            Message m = (Message) iter.next();
            messageSenders[m.senderId] = true;
            messageValues[m.senderId][0] = m.speed;
            messageValues[m.senderId][1] = m.speedAngle;
            messageValues[m.senderId][1] = m.bearing;
        }
    }

    public boolean[] getMessageSenders() {
        return messageSenders;

    }

    public float[][] getMessageValues() {
        return messageValues;
    }

    public boolean[] getIgnoreMessages() {
        return Environment.inst().getIgnoring(robotId);
    }
}
