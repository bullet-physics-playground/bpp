/*
 * APSliderPanel.java
 *
 * Created on July 13, 2004, 4:02 PM
 */

package graphics.simulator.sliders;

import javax.swing.*;
import javax.swing.event.*;
import java.awt.*;
import java.awt.event.*;

import graphics.ui.DoubleLabel;

import robot.KTRobot;
/**
 *
 * @author  Wesley Kerr
 */
public class KTSliderPanel extends DefaultSliderPanel {

    /** Creates a new instance of APSliderPanel */
    public KTSliderPanel() {
        super();
        addComponents();
        addListeners();

        updateSliders();
    }

    private void addComponents() {
        setLayout(new GridBagLayout());

        GridBagConstraints gridBagConstraints = new GridBagConstraints();

        gridBagConstraints = new GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.insets = new Insets(3, 3, 3, 3);
        gridBagConstraints.fill = GridBagConstraints.HORIZONTAL;
        gridBagConstraints.weightx = 0.1;
        add(wallVelocityLabel, gridBagConstraints);

        gridBagConstraints = new GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.insets = new Insets(3, 3, 3, 3);
        gridBagConstraints.fill = GridBagConstraints.HORIZONTAL;
        gridBagConstraints.weightx = 0.8;
        add(wallVelocitySlider, gridBagConstraints);

        wallVelocityLabelValue.setHorizontalAlignment(SwingConstants.RIGHT);
        gridBagConstraints = new GridBagConstraints();
        gridBagConstraints.gridx = 2;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.insets = new Insets(3, 3, 3, 3);
        gridBagConstraints.fill = GridBagConstraints.HORIZONTAL;
        gridBagConstraints.weightx = 0.1;
        add(wallVelocityLabelValue, gridBagConstraints);
    }

    private void addListeners() {
        wallVelocitySlider.addChangeListener(new ChangeListener() {
            public void stateChanged(ChangeEvent e) {
                float value = (float) wallVelocitySlider.getValue() / 10.0f;
                wallVelocityLabelValue.setText(value);
                KTRobot.wall = value;
            }
        });
    }

    public void updateSliders() {
        wallVelocityLabelValue.setText(KTRobot.wall + "");
    }

    private JLabel wallVelocityLabel = new JLabel("Wall Velocity:");
    private JSlider wallVelocitySlider = new JSlider(0, 200, 10);
    private DoubleLabel wallVelocityLabelValue = new DoubleLabel(10);
}
