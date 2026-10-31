/*
 * State.java
 *
 * Created on October 24, 2004, 10:19 PM
 */

package util;

/**
 *
 * @author  Wesley Kerr
 */
public class Node {
    
    private int state;
    private int action;
    
    /** Creates a new instance of State */
    public Node() {
        
    }
    
    public Node(int state, int action) {
        this.state = state;
        this.action = action;
    }
    
    public Node(Node n) {
        state = n.state;
        action = n.action;
    }
    
    public int getState() {
        return state;
    }
    
    public int getAction() {
        return action;
    }
    
    public void setState(int state) {
        this.state = state;
    }
    
    public void setAction(int action) {
        this.action = action;
    }
    
    public String toString() {
        return state + "," + action;
    }
    
    public void load(String n) {
        int index = n.indexOf(",");
        state = Integer.parseInt(n.substring(0, index));
        action = Integer.parseInt(n.substring(index+1));
    }
}
