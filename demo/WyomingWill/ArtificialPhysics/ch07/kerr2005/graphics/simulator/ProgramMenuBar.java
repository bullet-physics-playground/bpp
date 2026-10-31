/*
 * ProgramMenuBar.java
 *
 * Created on October 28, 2003, 10:32 PM
 */

package graphics.simulator;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;

import obstacle.ObstacleContainer;
/**
 *
 * @author  Wesley Kerr
 */
public class ProgramMenuBar extends JMenuBar {
    /** Creates a new instance of ProgramMenuBar */
    public ProgramMenuBar() {
        addComponents();
        addListeners();
    }

    private void addComponents() {
        fileMenu.add(startMenuItem);
        fileMenu.add(stopMenuItem);
        fileMenu.add(resetMenuItem);
        fileMenu.add(new JSeparator());
        fileMenu.add(exitMenuItem);

        add(fileMenu);

        displayMenu.add(displayIdMenuItem);

        add(displayMenu);

        obstacleMenu.add(clearMenuItem);
        obstacleMenu.add(loadMenuItem);

        add(obstacleMenu);
    }

    private void addListeners() {
        startMenuItem.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                Observer.inst().startVis();
            }
        });

        stopMenuItem.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                Observer.inst().stopVis();
            }
        });

        resetMenuItem.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                Observer.inst().resetVis();
            }
        });

        exitMenuItem.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                Observer o = Observer.inst();
                synchronized (o.lock) {
                    o.exit = true;
                    o.lock.notifyAll();
                }
            }
        });

        displayIdMenuItem.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                Observer.inst().displayId(displayIdMenuItem.getState());
            }
        });

        clearMenuItem.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                Observer.inst().loadObstacles(null);
            }
        });

        loadMenuItem.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                JFileChooser jf = new JFileChooser(ClassLoader.getSystemClassLoader().getResource("data/").getPath());
                if (jf.showOpenDialog(null) == JFileChooser.APPROVE_OPTION) {
                    try {
                        Observer.inst().loadObstacles(jf.getSelectedFile().getAbsolutePath());
                    } catch (Exception exp) {
                        exp.printStackTrace();
                        JOptionPane.showMessageDialog(null, "Error loading Obstacles\n" + exp.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                    }
                }
            }
        });

        saveMenuItem.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                JFileChooser jf = new JFileChooser(ClassLoader.getSystemClassLoader().getResource("data/").getPath());
                if (jf.showSaveDialog(null) == JFileChooser.APPROVE_OPTION) {
                    try {
                        ObstacleContainer.inst().saveObstacles(jf.getSelectedFile().getAbsolutePath());
                    } catch (Exception exp) {
                        JOptionPane.showMessageDialog(null, "Error saving Obstacles\n" + exp.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                    }
                }
            }
        });
    }

    private JMenu fileMenu     = new JMenu("File");
    private JMenu displayMenu  = new JMenu("Display");
    private JMenu obstacleMenu = new JMenu("Obstacle");

    private JMenuItem startMenuItem         = new JMenuItem("Start");
    private JMenuItem stopMenuItem          = new JMenuItem("Stop");
    private JMenuItem resetMenuItem         = new JMenuItem("Reset");
    private JMenuItem exitMenuItem          = new JMenuItem("Exit");

    private JCheckBoxMenuItem displayIdMenuItem  = new JCheckBoxMenuItem("Display Id", false);

    private JMenuItem clearMenuItem              = new JMenuItem("Clear Obstacles");
    private JMenuItem loadMenuItem               = new JMenuItem("Load Obstacles");
    private JMenuItem saveMenuItem               = new JMenuItem("Save Obstacles");
}
