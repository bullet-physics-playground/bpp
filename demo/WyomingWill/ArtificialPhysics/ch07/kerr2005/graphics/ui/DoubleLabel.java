/*
 * DoubleLabel.java
 *
 * Created on July 19, 2004, 1:29 PM
 */

package graphics.ui;

import java.text.NumberFormat;
import javax.swing.*;
/**
 *
 * @author  Wesley Kerr
 */
public class DoubleLabel extends JLabel {

    private NumberFormat nf;

    /** Creates a new instance of DoubleLabel */
    public DoubleLabel(double value) {
        super();

        nf = NumberFormat.getInstance();
        nf.setMinimumFractionDigits(2);
        nf.setMaximumFractionDigits(2);
        nf.setGroupingUsed(false);
        this.setText(value);
    }

    public void setText(double value) {
        this.setText(nf.format(value));
    }
}
