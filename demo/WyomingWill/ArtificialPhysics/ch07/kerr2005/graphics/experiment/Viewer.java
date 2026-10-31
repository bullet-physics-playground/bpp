/*
 * Viewer.java
 *
 * Created on October 28, 2003, 10:14 PM
 */

package graphics.experiment;

import graphics.ui.*;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;

/**
 *
 * @author  Wesley Kerr
 */
public class Viewer extends JFrame {

    /** Creates a new instance of Viewer */
    public Viewer(int width, int height) {
        addComponents(width, height);
        addListeners();
        show();
    }

    private void addComponents(int width, int height) {
        displayPanel   = new DisplayPanel();

        displayPanel.setPreferredSize(new Dimension(width/4, height/4));
        scroll = new JScrollPane(displayPanel);
        scroll.setPreferredSize(new Dimension(width/4, height/4));
        scroll.getViewport().setPreferredSize(new Dimension(width/4, height/4));
        scroll.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED);
        scroll.setHorizontalScrollBarPolicy(JScrollPane.HORIZONTAL_SCROLLBAR_AS_NEEDED);

        getContentPane().setLayout(new GridBagLayout());

        GridBagConstraints gridBagConstraints = new GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.insets = new Insets(3, 3, 3, 3);
        gridBagConstraints.fill = GridBagConstraints.BOTH;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.weighty = 1.0;
        getContentPane().add(scroll, gridBagConstraints);

        setSize((width/4)+50, 768);
    }

    private void addListeners() {
        addWindowListener(new WindowAdapter() {
            public void windowClosing(WindowEvent evt) {
                dispose();
            }
        });
    }

    public void update() {
        displayPanel.repaint();
    }

    public void showErrorMessage(String error) {
        JOptionPane.showMessageDialog(this, error);
    }

    private JScrollPane scroll;
    private DisplayPanel displayPanel;
}
