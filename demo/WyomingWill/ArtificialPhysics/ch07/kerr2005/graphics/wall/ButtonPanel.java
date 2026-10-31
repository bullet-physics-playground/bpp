/*
 * ButtonPanel.java
 *
 * Created on August 31, 2004, 11:55 AM
 */

package graphics.wall;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
/**
 *
 * @author  wkerr
 */
public class ButtonPanel extends JPanel {

    /** Creates a new instance of ButtonPanel */
    public ButtonPanel() {
        init();
        addListeners();
    }

    private void init() {
        setLayout(new GridBagLayout());

        GridBagConstraints gbc = new GridBagConstraints();
        gbc.gridx = 0;
        gbc.gridy = 0;
        gbc.insets = new Insets(3,3,3,3);
        gbc.fill = GridBagConstraints.BOTH;
        add(firstButton, gbc);

        gbc = new GridBagConstraints();
        gbc.gridx = 1;
        gbc.gridy = 0;
        gbc.insets = new Insets(3,3,3,3);
        gbc.fill = GridBagConstraints.BOTH;
        add(nextButton, gbc);

        gbc = new GridBagConstraints();
        gbc.gridx = 2;
        gbc.gridy = 0;
        gbc.insets = new Insets(3,3,3,3);
        gbc.fill = GridBagConstraints.BOTH;
        add(prevButton, gbc);

        gbc = new GridBagConstraints();
        gbc.gridx = 3;
        gbc.gridy = 0;
        gbc.insets = new Insets(3,3,3,3);
        gbc.fill = GridBagConstraints.BOTH;
        add(lastButton, gbc);
    }

    private void addListeners() {
        firstButton.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                Observer.inst().first();
            }
        });

        nextButton.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                Observer.inst().inc();
            }
        });

        prevButton.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                Observer.inst().dec();
            }
        });

        lastButton.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                Observer.inst().last();
            }
        });
    }

    private JButton firstButton = new JButton("First");
    private JButton nextButton = new JButton("Next");
    private JButton prevButton = new JButton("Previous");
    private JButton lastButton = new JButton("Last");
}
