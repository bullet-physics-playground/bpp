/*
 * Viewer.java
 *
 * Created on October 28, 2003, 10:14 PM
 */

package graphics.collision;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;

/**
 *
 * @author  Wesley Kerr
 */
public class Viewer extends JFrame {

    /** Creates a new instance of Viewer */
    public Viewer() {
        addComponents();
        addListeners();
        show();
    }

    private void addComponents() {
        menuBar = new ProgramMenuBar();
        igp     = new InitialGlobalPanel();
        fgp     = new FinalGlobalPanel();
        ilp     = new InitialLocalPanel();
        flp     = new FinalLocalPanel();

        getContentPane().setLayout(new GridBagLayout());

        GridBagConstraints gridBagConstraints = new GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.insets = new Insets(3, 3, 3, 3);
        gridBagConstraints.fill = GridBagConstraints.BOTH;
        gridBagConstraints.weightx = 0.5;
        gridBagConstraints.weighty = 0.5;
        getContentPane().add(igp, gridBagConstraints);

        gridBagConstraints = new GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.insets = new Insets(3, 3, 3, 3);
        gridBagConstraints.fill = GridBagConstraints.BOTH;
        gridBagConstraints.weightx = 0.5;
        gridBagConstraints.weighty = 0.5;
        getContentPane().add(fgp, gridBagConstraints);

        gridBagConstraints = new GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.insets = new Insets(3, 3, 3, 3);
        gridBagConstraints.fill = GridBagConstraints.BOTH;
        gridBagConstraints.weightx = 0.5;
        gridBagConstraints.weighty = 0.5;
        getContentPane().add(ilp, gridBagConstraints);

        gridBagConstraints = new GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.insets = new Insets(3, 3, 3, 3);
        gridBagConstraints.fill = GridBagConstraints.BOTH;
        gridBagConstraints.weightx = 0.5;
        gridBagConstraints.weighty = 0.5;
        getContentPane().add(flp, gridBagConstraints);

        setJMenuBar(menuBar);
        setSize(1024, 768);
    }

    private void addListeners() {
        addWindowListener(new WindowAdapter() {
            public void windowClosing(WindowEvent evt) {
                Observer o = Observer.inst();
                synchronized (o.lock) {
                    o.exit = true;
                    o.lock.notifyAll();
                }
            }
        });
    }

    public void loadNewValues() {
        ValueDialog vd = new ValueDialog(this);
        vd.pack();
        vd.show();
    }

    public void update() {
        igp.repaint();
        fgp.repaint();
        ilp.repaint();
        flp.repaint();
    }

    private ProgramMenuBar menuBar;
    private InitialGlobalPanel igp;
    private FinalGlobalPanel fgp;
    private InitialLocalPanel ilp;
    private FinalLocalPanel flp;
}
