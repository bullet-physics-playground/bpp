/*
 * Builder.java
 *
 * Created on November 19, 2004, 7:58 PM
 */

package obstacleGenerator;

import java.util.ArrayList;

/**
 *
 * @author  Wesley Kerr
 */
public class Builder {

    /** Creates a new instance of Builder */
    public Builder() {
    }

    public ArrayList build(boolean[][] selected) {
        ArrayList obstacleList = new ArrayList();
        for (int i = 0; i < selected.length; ++i) {
            for (int j = 0; j < selected[i].length; ++j) {
                if (selected[i][j]) {
                    findConnected(selected, i, j, obstacleList);
                }
            }
        }
        return obstacleList;
    }

    protected void findConnected(boolean[][] selected, int i, int j, ArrayList list) {
        int right = j;
        for (; right < selected[i].length; ++right) {
            if (!selected[i][right])
                break;
        }
        right--;

        int bottom = i;
        for (; bottom < selected.length; ++bottom) {
            if (!selected[bottom][j])
                break;
        }
        bottom--;

        for (int k = i+1; k <= bottom; ++k) {
            for (int l = j+1; l <= right; ++l) {
                if (!selected[k][l]) {
                    right = l-1;
                }
            }
        }

        for (int k = i; k <= bottom; ++k) {
            for (int l = j; l <= right; ++l) {
                selected[k][l] = false;
            }
        }
        Rectangle r = new Rectangle(j, i, right, bottom);
        list.add(r);
    }
}
