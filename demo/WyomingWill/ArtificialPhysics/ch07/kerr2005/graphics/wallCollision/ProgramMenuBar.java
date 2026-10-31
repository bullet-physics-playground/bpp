/*
 * ProgramMenuBar.java
 *
 * Created on October 28, 2003, 10:32 PM
 */

package graphics.wallCollision;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;

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
        fileMenu.add(exitMenuItem);
        fileMenu.add(loadMenuItem);
        add(fileMenu);
    }

    private void addListeners() {
        exitMenuItem.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                Observer o = Observer.inst();
                synchronized (o.lock) {
                    o.exit = true;
                    o.lock.notifyAll();
                }
            }
        });

        loadMenuItem.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                Observer.inst().loadNewValues();
            }
        });
    }

    private JMenu fileMenu     = new JMenu("File");

    private JMenuItem loadMenuItem          = new JMenuItem("Load");
    private JMenuItem exitMenuItem          = new JMenuItem("Exit");
}
